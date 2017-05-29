# haproxy-waf [![Build Status](https://travis-ci.org/git001/haproxy-waf2.svg?branch=master)](https://travis-ci.org/git001/haproxy-waf2)

## Introduction

The main work is based on Dragan Dosen patches and of course the SPOE feature of haproxy.

You can see the start and following discussion on the haproxy mailing list.
https://www.mail-archive.com/haproxy@formilux.org/msg26229.html

You are able with this patches to use haproxy as SSL terminator and WAF (Web Application Firewall) based on [mod_defender](https://github.com/VultureProject/mod_defender).

This blog post desribe another possible solution with naxsi and haproxy

https://www.haproxy.com/blog/high-performance-waf-platform-with-naxsi-and-haproxy/

## requirements

You will need this tools to run this docker file on centos

```
yum -y install docker bash-completion git
systemctl start docker
```

## build 

Now you can clone & build this repo with common commands

```
git clone https://github.com/git001/haproxy-waf2.git
cd haproxy-waf2
docker build -t haproxy-waf2 .
```

## test

You can see if the build works with the `docker run` command

```
docker run --entrypoint /usr/local/sbin/haproxy --rm haproxy-waf2 -vv
```

# haproxy use

I have uploaded the image into docker hub

```
https://hub.docker.com/r/me2digital/haproxy-waf2/
```

from where you can use this image with the following command.

```
$ docker run --rm -it --name my-running-haproxy \
    -e TZ=Europe/Vienna \
    -e STATS_PORT=1999 \
    -e STATS_USER=aaa \
    -e STATS_PASSWORD=bbb \
    -e SYSLOG_ADDRESS=127.0.0.1:8514 \
    -e SERVICE_TCP_PORT=13443 \
    -e SERVICE_NAME=test-haproxy \
    -e SERVICE_DEST_PORT=8080 \
    -e SERVICE_DEST='1.2.3.4;5.6.7.8;80.44.22.7' \
    me2digital/haproxy-waf2 /bin/bash
```

The output of the command above should be something like this

```
Current ENV Values
===================
SERVICE_NAME        :test-haproxy
SERVICE_DEST        :1.2.3.4;5.6.7.8;80.44.22.7
SERVICE_DEST_PORT   :8080
TZ                  :Europe/Vienna
SYSLOG_ADDRESS      :127.0.0.1:8514
CONFIG_FILE         :
given DNS_SRV001    :
given DNS_SRV002    :
===================
compute DNS_SRV001  :8.8.8.8
compute DNS_SRV002  :8.8.4.4
using CONFIG_FILE   :/tmp/haproxy.conf
...
```

# waf use

TODO

## Run output

```
docker run --rm -it --entrypoint /bin/bash me2digital/haproxy-waf2
[root@66c23d39fbd2 /]# /usr/local/bin/defender -f /data/naxsi_core.rules
1496069557.347029 [00] Defender active on server 66c23d39fbd2: 42 MainRules loaded
1496069557.347100 [00] Defender scanner disabled for loc /
1496069562.353190 [01] 0 clients connected
1496069562.353303 [10] 0 clients connected
```
