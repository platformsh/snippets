#!/bin/bash

run() {
	# Run the compilation process.
	cd $PLATFORM_CACHE_DIR || exit 1;

	os_arch=$(uname -m | sed 's/_/-/')
	php_version=$(php -r 'echo substr(PHP_VERSION, 0, 3);')
	relay_build="relay-${1}-php${php_version}-debian-${os_arch}+zts"

	if [ ! -f "${PLATFORM_CACHE_DIR}/${relay_build}/redis-pkg.so" ]; then
		ensure_patchelf
		ensure_zstd
		ensure_source "$1" "$relay_build"
	fi

	copy_lib "$relay_build"
	enable_lib
}

copy_lib() {
	# Copy the compiled library to the application directory.

	echo "Installing Relay extension."
	ldd "${PLATFORM_CACHE_DIR}/${1}/relay-pkg.so"
	cp "${PLATFORM_CACHE_DIR}/${1}/relay-pkg.so" "${PLATFORM_APP_DIR}/relay.so"
}

enable_lib() {
	# Tell PHP to enable the extension.

	echo "Enabling Relay extension."
	echo -e "\nextension=${PLATFORM_APP_DIR}/relay.so" >> "${PLATFORM_APP_DIR}/php.ini"
}

ensure_source() {
	# Download the Relay extension.

	if [ ! -d $2 ]; then
		relay_pkg_url="https://cachewerk.s3.amazonaws.com/relay/$1/${2//+/%2B}.tar.gz"

		echo "Downloading: ${relay_pkg_url}"
		curl -s -S -L $relay_pkg_url | tar xz -C $PLATFORM_CACHE_DIR

		cd $2 || exit 1;

		# Inject UUID into Relay extension.
		uuid=$(cat /proc/sys/kernel/random/uuid)
		sed -i "s/BIN:31415926-5358-9793-2384-626433832795/BIN:$uuid/" relay-pkg.so

		ldd relay-pkg.so
		${PLATFORM_APP_DIR}/patchelf --replace-needed libzstd.so.1 ${PLATFORM_APP_DIR}/lib/libzstd.so relay-pkg.so
		ldd relay-pkg.so
	fi
}

ensure_patchelf() {
	# Install Patchelf.

	if [ ! -d "${PLATFORM_APP_DIR}/patchelf" ]; then
		echo "Installing Patchelf."

		mkdir -p patchelf
		cd patchelf || exit 1
		curl -s -S -L "https://github.com/NixOS/patchelf/releases/download/0.14.5/patchelf-0.14.5-x86_64.tar.gz" | tar xz
		cp bin/patchelf "${PLATFORM_APP_DIR}/patchelf"
		cd .. || exit 1
	fi
}

ensure_zstd() {
	# Install Zstandard.

	dep_version="1.5.2"
	dep_package="zstd-${dep_version}"
	dep_url="https://github.com/facebook/zstd/archive/v${dep_version}.tar.gz"

	if [ ! -d "${PLATFORM_APP_DIR}/lib" ]; then
		echo "Installing Zstandard."

		curl -s -S -L $dep_url | tar xz

		pushd "${dep_package}/lib" || exit 1
		make install-shared install-static PREFIX=${PLATFORM_APP_DIR}
		popd || exit 1
	fi
}

ensure_environment() {
	# If not running in a Platform.sh build environment, do nothing.
	if [ -z "${PLATFORM_CACHE_DIR}" ]; then
		echo "Not running in a Platform.sh build environment.  Aborting Relay installation."
		exit 0;
	fi
}

ensure_arguments() {
	# If no version was specified, don't try to guess.
	if [ -z $1 ]; then
		echo "No version of the Relay extension specified.  You must specify a tagged version on the command line."
		exit 1;
	fi
}

ensure_environment
ensure_arguments "$1"
run "$1"
