---
sidebar_label: Installing the CLI
---

# how to install the Kargo CLI -- `kargo` --

* steps 
  * download the CLI binary
    * ways
      * -- via -- Kargo UI Dashboard
        * | left panel, CLI > choose your OS & CPU architecture
        * 👀recommended one👀
          * Reason:🧠match your Kargo API server🧠

            ![CLI Tab in Kargo UI](./img/cli-installation.png)
      * | Mac, Linux, or WSL

        ```shell
        arch=$(uname -m)
        [ "$arch" = "x86_64" ] && arch=amd64
        curl -L -o kargo https://github.com/akuity/kargo/releases/latest/download/kargo-"$(uname -s | tr '[:upper:]' '[:lower:]')-${arch}"
        chmod +x kargo
        ```

      * | Windows Powershell

        ```shell
        Invoke-WebRequest -URI https://github.com/akuity/kargo/releases/latest/download/kargo-windows-amd64.exe -OutFile kargo.exe
        ```
  * place the binary | your file system / included -- by the -- `PATH` environment variable
