#!/bin/bash

NODE_VERSION='lts'
WITH_YARN=false

usage() {
    echo "Usage: $0 [-v <string>] [-y]" 1>&2;
    echo "Options: " 1>&2;
    echo " -v: requested NodeJS version (default v$NODE_VERSION)" 1>&2;
    echo " -y: Install Yarn (default false)" 1>&2;
    exit 1;
}

while getopts :hv:y flag
do
    case "${flag}" in
        v) NODE_VERSION=${OPTARG};;
        y) WITH_YARN=true;;
        h | *) # Display help.
            usage
            exit 0
            ;;
    esac
done


NODE_VERSION=$(sed "s/^[=v]*//i" <<< "$NODE_VERSION" | tr '[:upper:]' '[:lower:]')
echo "Requesting the installation of Node v$NODE_VERSION $([[ $WITH_YARN = true ]] && echo 'with yarn')"
echo ""

echo "** Installing n **"
npm install -g n
echo ""

echo "** Installing Node $NODE_VERSION **"
n $NODE_VERSION

if $WITH_YARN;
then
    echo ""
    echo "** Installing Yarn **"
    REQUIRED_NODE_VERSION="16.10"
    if echo "lts latest active lts_active lts_latest lts current supported nightly" | tr " " '\n' | grep -F -q -x "$DEBUG"; then
        corepack enable
    elif [ "$(printf '%s\n' "$REQUIRED_NODE_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_NODE_VERSION" ]; then 
        corepack enable
    else
        npm i -g corepack
    fi
fi
