
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
* [`Install a specific version of Node on non-Node JS container`](#Install-a-specific-version-of-Node-on-non-Node-JS-container)


### Install a specific version of Node on non-Node JS container

The [documentation](https://docs.platform.sh/languages/nodejs.html) describes how to specify the Node version to use and/or how to add Yarn to the NodeJS container.

For other containers, such as the PHP one, 

#### Install the LTS version of node
```
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install_node.sh | { bash /dev/fd/3 -v lts; } 3<&0
```

#### Install the 17.5 version of node with Yarn
```
curl -fsS https://raw.githubusercontent.com/platformsh/snippets/main/src/install_node.sh | { bash /dev/fd/3 -v 17.5 -y; } 3<&0
```
