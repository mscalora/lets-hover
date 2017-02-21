## Synopsis

Scripts to setup and automate letsencrypt certificate use 

## Requirements

### Required Preinstalled Software

* curl
* python 2.7
* openssl

### Software Installed Via Included Script

* dehydrated
* hover-cli

### Required Python Packages

* requests
* liburl3
* pyopenssl
* future
* dnspython
* tld

## Ubuntu Server 16.04 setup

    sudo su
    apt-get update
    apt-get upgrade -y
    apt-get install -y python2.7 python-pip nano zip unzip curl build-essential libssl-dev libffi-dev python-dev
    pip install --upgrade pip
    pip install requests future dnspython tld urllib3 pyopenssl
    mkdir /etc/letsencrypt-ssl
    cd /etc/letsencrypt-ssl
    curl "https://codeload.github.com/mscalora/lets-hover/zip/master" -o /tmp/lets-hover.zip
    unzip -j /tmp/lets-hover.zip
    ./update-tools.sh
