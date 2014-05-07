#!/bin/bash

cd /root/occurrences

[[ ! -e config.yml ]] && cp config.yml.dist config.yml

nohup thin start > rack.log 2>&1 &

/usr/sbin/sshd -D

