#!/bin/sh

RED='\033[0;31m'
RED_BOLD='\033[01;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
GREEN_BOLD='\033[01;32m'
NC='\033[0m'
NC_BOLD='\033[01m'

INSTALL_DIR='./'
TEMPLATE_COMMANDS=""

SUPPORTED_TEMPLATES=['laravel']

CURRENT_DIR=$(pwd)

usage() {
    echo "Usage: [-t <string>] [-p <string>] [-a <string>]" 1>&2;
    echo "Options: " 1>&2;
    echo " -t: Template Name" 1>&2;
    echo " -p: Installation path (default: current folder)" 1>&2;
    echo " -a: GitHub Personal Token\n" 1>&2;
    exit 1;
}

while getopts :ha:p:t: flag
do
    case "${flag}" in
        t) TEMPLATE=${OPTARG};;
        p) INSTALL_DIR=${OPTARG};;
        a) TOKEN=${OPTARG};;
        h | *) # Display help.
            usage
            exit 0
            ;;
    esac
done

if [[ $INSTALL_DIR == "" ]]; then
    INSTALL_DIR='./'
fi


if [ -z "$TEMPLATE" ]; then
    printf "\n${RED_BOLD}Error: ${NC}No template provided!\n\n"
    usage
    exit
fi
TEMPLATE=$(echo "$TEMPLATE" | tr '[:upper:]' '[:lower:]')

get_body()
{
    headers=('-H' "Accept: application/json")
    if [ -n "$TOKEN" ]; then
        headers+=('-H' "Authorization: Bearer $2")
    fi

    response=$(curl \
        -s \
        "${headers[@]}" \
        -w "\n%{http_code}" "$1"
    )

    http_code=$(tail -n1 <<< "$response")  # get the last line
    content=$(sed '$ d' <<< "$response")   # get all but the last line which contains the status code

    if [[ $http_code -ge 300 ]]
    then
        echo "\nError: ${NC_BOLD}${content}${NC}!" >&2
        echo "\n${RED_BOLD}Aborting.${NC}\n" >&2
        return
    fi

    echo $content
}

fetch_data()
{
    # Hardcoded values until the JSON unique source of truth

    case $TEMPLATE in

        laravel)
            TEMPLATE_COMMANDS='[
                "composer require platformsh/laravel-bridge --prefer-dist --no-interaction --ignore-platform-req=ext-redis --ignore-platform-req=ext-apcu --ignore-platform-req=ext-intl --ignore-platform-req=ext-bcmath --ignore-platform-req=ext-exif --ignore-platform-req=ext-gd --ignore-platform-req=ext-imagick --ignore-platform-req=ext-mbstring --ignore-platform-req=ext-memcache --ignore-platform-req=ext-pdo --ignore-platform-req=ext-openssl --ignore-platform-req=ext-zip --ignore-platform-req=php"
            ]'
            ;;

    esac
}


init_template()
{
    # Suggest the initialisation of the framework if the installation directory is empty
    if [ -n "$(ls -A $INSTALL_DIR)" ]; then
        return
    fi

    echo "" >&2
    echo "You are platformifying an empty directory." >&2
    while true; do
        read -p "$(echo "${NC_BOLD}Do you wish to initialize a new ${RED_BOLD}$TEMPLATE${NC}${NC_BOLD} project? ${NC}(y/n) ")" yn
        case $yn in
            [Yy]* )
                echo "" >&2
                git clone "git@github.com:platformsh-templates/${TEMPLATE}.git" $INSTALL_DIR
                exit 1
                break;;
            [Nn]* ) return;;
            * ) echo "Please answer yes or no." >&2;;
        esac
    done
}


platformify()
{
    json_data=$(get_body "https://api.github.com/repos/platformsh/template-builder/contents/templates/$TEMPLATE/files$1" $TOKEN)
    if [ -z "$json_data" ]; then
        return
    fi

    for row in $(echo "${json_data}" | jq -r '.[] | @base64'); do
        _jq() {
            echo "${row}" | base64 --decode | jq -r "${1}"
        }

        name=$(_jq '.name')
        type=$(_jq '.type')

        current_dir=$(echo "$1" | sed -e 's#^\/##;')
        current_dir=$([ "$current_dir" == '' ] && echo "$current_dir" || echo "$current_dir/")

        if [[ $type == 'dir' ]]; then
            printf "$current_dir$name - "
            if [[ ! -d "$INSTALL_DIR/$current_dir$name" ]]; then
                mkdir "$INSTALL_DIR/$current_dir$name"
                printf "${GREEN}Folder created${NC}.\n"
            else
                printf "${BLUE}Already existing${NC}.\n"
            fi

            platformify "$1/$name"

        elif [[ $type == 'file' ]]; then
            extension=$(echo "$name" | grep -o '\.\w*$' | tr '[:upper:]' '[:lower:]')
            printf "$current_dir$name - "
            if [[ $extension == '.md' ]]; then
                printf "${BLUE}Skipped${NC}.\n"
                continue
            fi;

            if [[ ! -f "$INSTALL_DIR/$current_dir$name" ]]; then
                curl -s -o "$INSTALL_DIR/$current_dir$name" $(_jq '.download_url')
                printf "${GREEN}File downloaded${NC}.\n"
                continue
            fi
            printf "${BLUE}Already existing${NC}.\n"
        fi
    done
}

echo ""
echo "> ${NC_BOLD}Platformification of the project based on the ${GREEN_BOLD}${TEMPLATE} ${NC}${NC_BOLD}template${NC}"
echo "  ${BLUE}https://github.com/platformsh/template-builder/tree/master/templates/${TEMPLATE}/files${NC}"
echo ""
echo "  Platform.sh related files from the template will be created in your project if missing."
echo "  ${NC_BOLD}Existing files won't be overriden${NC}."
echo ""

while true; do
    read -p "$(echo "${RED_BOLD}Do you wish to continue? ${RED}(y/n) ${NC} ")" yn
    case $yn in
        [Yy]* )
            # Try to clone the template if the installation folder is empty (and exit script)
            init_template

            # Checking if the template is supported
            if [[ ! ${SUPPORTED_TEMPLATES[*]} =~ $TEMPLATE ]]; then
                echo "${RED}The platformification of the ${RED_BOLD}${TEMPLATE}${RED} template is not yet supported. Aborting.${NC}.\n"
                exit
            fi

            # Fetch JSON data related to the template
            fetch_data

            # Platformify the current project reccursively copying files
            platformify ""

            # Execute followup commands
            if [ -n "$TEMPLATE_COMMANDS" ]; then
                echo ""
                cd $INSTALL_DIR
                for row in $(echo "${TEMPLATE_COMMANDS}" | jq -r '.[] | @base64'); do
                    eval $(echo ${row} | base64 --decode)
                done
                cd $CURRENT_DIR
            fi

            break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
