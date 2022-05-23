run() {
    # Run the compilation process.
    cd $PLATFORM_CACHE_DIR || exit 1;

    PHP_VERSION=$(php -r "echo PHP_VERSION;")
    VERSION_PREFIX="v$1-php$PHP_VERSION"
    VERSION_PREFIX="${VERSION_PREFIX//\./_}"

    if [ ! -f "${PLATFORM_CACHE_DIR}/$2/swoole-src/modules/$VERSION_PREFIX-$2.so" ]; then
        ensure_source "$2"
        checkout_version "v$1"
        compile_source
        move_extension $2 "$VERSION_PREFIX"
    fi

    copy_lib "$2" "$VERSION_PREFIX"
    enable_lib "$2"
}

enable_lib() {
    # Tell PHP to enable the extension.
    echo "---------------------------------"
    echo "Enabling Open Swoole extension."
    echo -e "\nextension=${PLATFORM_APP_DIR}/$1.so" >> $PLATFORM_APP_DIR/php.ini
}

copy_lib() {
    # Copy the compiled library to the application directory.
    echo "---------------------------------"
    echo "Installing Open Swoole extension."
    cp $PLATFORM_CACHE_DIR/$1/swoole-src/modules/$2-$1.so $PLATFORM_APP_DIR/$1.so
}

move_extension() {
    echo "---------------------------------"
    echo "Moving built extension to identified folder."
    mv $PLATFORM_CACHE_DIR/$1/swoole-src/modules/$1.so $PLATFORM_CACHE_DIR/$1/swoole-src/modules/$2-$1.so
}

checkout_version () {
    # Check out the specific Git tag that we want to build.
    git checkout "$1"
}

ensure_source() {
    # Ensure that the extension source code is available and up to date.
    mkdir -p "$PLATFORM_CACHE_DIR/$1"
    cd "$PLATFORM_CACHE_DIR/$1";

    if [ -d "swoole-src" ]; then
        cd swoole-src || exit 1;
        git fetch --all --prune
    else
        git clone https://github.com/$1/swoole-src.git
        cd swoole-src || exit 1;
    fi
}

compile_source() {
    # Compile the extension.
    phpize clean && \
    phpize && \
    ./configure && \
    make && \
    make install
}

ensure_environment() {
    # If not running in a Platform.sh build environment, do nothing.
    if [ -z "${PLATFORM_CACHE_DIR}" ]; then
        echo "Not running in a Platform.sh build environment.  Aborting Open Swoole installation."
        exit 0;
    fi
}

ensure_arguments() {
    # If no Swoole repository was specified, don't try to guess.
    if [ -z $1 ]; then
        echo "No version of the Swoole project specified. (swoole/openswoole)."
        exit 1;
    fi

    if [[ ! "$1" =~ ^(swoole|openswoole)$ ]]; then
        echo "The requested Swoole project is not supported: ${1} Aborting.\n"
        exit 1;
    fi

    # If no version was specified, don't try to guess.
    if [ -z $2 ]; then
        echo "No version of the ${1} extension specified.  You must specify a tagged version on the command line."
        exit 1;
    fi
}

ensure_environment
ensure_arguments "$1" "$2"

SWOOLE_PROJECT=$1;
SWOOLE_VERSION=$(sed "s/^[=v]*//i" <<< "$2" | tr '[:upper:]' '[:lower:]')

run "$SWOOLE_VERSION" "$SWOOLE_PROJECT"
