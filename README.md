
<br />
<p align="left">
    <a href="https://platform.sh">
        <img src="https://platform.sh/logos/redesign/Platformsh_logo_black.svg" width="150px">
    </a>
</p>
<br /><br />
<p align="center">
    <a href="https://docs.platform.sh">
        <img src="https://platform.sh/images/deploy/console.svg" alt="Logo" height="200">
    </a>
</p>
<br />
<h1 align="center">Platform.sh Template Snippets</h1>

<p align="center">
    <strong>Contribute to the Platform.sh knowledge base, or check out our resources</strong>
    <br />
    <br />
    <a href="https://community.platform.sh"><strong>Join our community</strong></a>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
    <a href="https://platform.sh/blog"><strong>Blog</strong></a>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
    <a href="https://docs.platform.sh"><strong>Documentation</strong></a>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
    <br /><br />
</p>

Platform.sh maintains a list of scripts that may be used within the template to ease its fine-tuning.

## Contents:
* [`raw.githubusercontent.com rate limit`](#rawgithubusercontentcom-rate-limit)
* [`Install a specific version of Node on non-Node JS container`](#Install-a-specific-version-of-Node-on-non-Node-JS-container)
* [`Platformify script`](#platformify-script)
* [`Install Swoole`](#install-swoole)

### raw.githubusercontent.com rate limit

On rare occasion, the rate limit on `raw.githubusercontent.com` my be hit. It can
then be recommended to use a [Personal Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) to benefit
from a much higher rate limit.

```
curl -H "Authorization: Bearer PERSONAL_TOKEN" -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/script.sh | { bash /dev/fd/3 PARAMETERS; } 3<&0
```

### Install a specific version of Node on non-Node JS container

The [documentation](https://docs.platform.sh/languages/nodejs.html) describes how
to specify the Node version to use and/or how to add Yarn to the NodeJS container.

For other containers, such as the PHP one, it may be needed to rely on a specific
version of NodeJS, and use Yarn as well.

#### Install the LTS version of node
```
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install_node.sh | { bash /dev/fd/3 -v lts; } 3<&0
```

#### Install the 17.5 version of node with Yarn
```
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install_node.sh | { bash /dev/fd/3 -v 17.5 -y; } 3<&0
```

#### Use

An example build hook is listed below. If using this snippet, do not add `corepack` as a [build dependency as outlined in the Platform.sh documentation](https://docs.platform.sh/languages/nodejs.html#use-yarn-as-a-package-manager), as it is already done for you. With the `-y` flag, the hook below will install Node.js 14.19.0 along with Yarn, afterwhich yarn commands can be run through corepack.

```yaml
name: app
type: php:8.0
dependencies:
    php:
        composer/composer: '^2'
variables:
    env:
        NODE_VERSION: v14.19.0
build:
    flavor: none
hooks:
    build: |
        set -e 
        composer install
        
        export N_PREFIX=$HOME/.n
        export PATH=$N_PREFIX/bin:$PATH
        curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install_node.sh | { bash /dev/fd/3 -v $NODE_VERSION -y; } 3<&0
        
        PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 corepack yarn install
        PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 corepack yarn packages:build
        corepack yarn run less
        corepack yarn run webpack
```

> **Note:**
>
> By default, `n` will try and install to `/usr/local/n`, which is not allowed on Platform.sh. You can instead specify the install location using the [variable `N_PREFIX` and then adding to `PATH`](https://github.com/tj/n#optional-environment-variables). If you will also need `n` outside of the build hook, add the two `export` lines to `.environment` as well. 

### Platformify script

The `platformify` script will download the `.platform.app.yaml` file and all the
files needed to run a specific project on Platform.sh.

To platformify a Laravel project:
```
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/platformify.sh | { bash /dev/fd/3 -t laravel ; } 3<&0
```

To platformify a Laravel project and a speficic folder:
```
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/platformify.sh | { bash /dev/fd/3 -t laravel -p path/to/dir ; } 3<&0
```

When ran on an empty folder, the script will clone the full template.

### Install Swoole

The `install_swoole` script will install and enable the Swoole or Open Swoole extension in a PHP container.

To install Open Swoole v4.11.0:
```
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install_swoole.sh | { bash /dev/fd/3 openswoole 4.11.0 ; } 3<&0
```

To install Swoole v4.8.10:
```
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install_swoole.sh | { bash /dev/fd/3 swoole 4.8.10 ; } 3<&0
```

### Install Relay (Redis)

The `install-relay` script will install and enable the [Relay](https://relay.so) extension in a PHP container.

To install Relay v0.6.0:
Note the version should be prefixed with `v` (**v**0.6.0)
```
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install-relay.sh | { bash /dev/fd/3 v0.6.0 ; } 3<&0
```

To install Relay @dev:
```
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install-relay.sh | { bash /dev/fd/3 dev ; } 3<&0
```

### Install PhpRedis (Redis)

The `install-phpredis` script will install and enable the [PhpRedis](https://github.com/phpredis/phpredis) extension in a PHP container.

To install PhpRedis v5.1.1:
```
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install-phpredis.sh | { bash /dev/fd/3 5.1.1 ; } 3<&0
```

### Region audit

The `region-audit` script with list projects within a Platform.sh or Upsun organization that are deployed to some subset of regions.

To run the script for Platform.sh

```bash
https://raw.githubusercontent.com/platformsh/snippets/main/src/region-audit.sh | bash -s -- [ORG_NAME] [REGIONS] [platform|upsun]
```

For example

```bash
https://raw.githubusercontent.com/platformsh/snippets/main/src/region-audit.sh | bash -s -- my-org ch-1,uk-1,de-2,us-4 platform
```
