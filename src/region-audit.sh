#!/usr/bin/env bash
# Produces an audit report of projects in a given organization on a subset of regions.
# Examples:
#   - ./region-audit.sh my-org ch-1,uk-1,de-2,us-4 platform
#   - ./region-audit.sh another-org de-2,us-4 upsun

ORG_NAME=$1
REGIONS=$2
VENDOR=$3

VENDOR_NAME=""
REGION_ROOT=""
CONSOLE_LINK=""
CLI_COMMAND=""

FILENAME=region-audit.md
IFS=',' read -r -a regions <<< "$REGIONS"

audit_regions () {

    touch $FILENAME
    printf "# Region audit\n\n" > $FILENAME
    echo "- Organization: $ORG_NAME" >> $FILENAME
    echo "- Vendor: $VENDOR_NAME" >> $FILENAME
    echo "- Regions: $REGIONS" >> $FILENAME
    echo "- Timestamp: $(date '+%Y-%m-%d %H:%M:%S')." >> $FILENAME

    for region in "${regions[@]}"
    do
        printf "\n## $region.$REGION_ROOT\n\n" >> $FILENAME
        PROJECT_CMD="$CLI_COMMAND project:list -o $ORG_NAME -c0 --region=$region.$REGION_ROOT --pipe"
        PROJECTS=$(eval $PROJECT_CMD)
        RESULT_SIZE=${#PROJECTS}
        if [ "$RESULT_SIZE" = "0" ]; then
            echo "There are no projects on region ($region)." >> $FILENAME
        else
            while IFS= read -r pid
            do
                TITLE_CMD="$CLI_COMMAND project:info -p $pid title"
                TITLE=$(eval $TITLE_CMD)
                LINK=$CONSOLE_LINK/$pid
                echo "- [ ] [$TITLE ($pid)]($LINK)" >> $FILENAME
            done < <(printf '%s\n' "$PROJECTS")
        fi
    done
}

if [ "$VENDOR" = "upsun" ]; then
    REGION_ROOT="upsun.com"
    VENDOR_NAME="Upsun"
    CONSOLE_LINK=https://console.upsun.com/$ORG_NAME
    CLI_COMMAND="upsun"

    audit_regions
elif [ "$VENDOR" = "platform" ]; then
    VENDOR_NAME="Platform.sh"
    REGION_ROOT="platform.sh"
    CONSOLE_LINK=https://console.platform.sh/$ORG_NAME
    CLI_COMMAND="platform"

    audit_regions
else 
    printf "\n\nPlease provide a valid vendor: platform, upsun.\n\nExample:\n\n     ./region-audit ORG_NAME REGIONS platform\n\nAborting.\n\n"
    exit 1
fi
