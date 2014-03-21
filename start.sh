#!/bin/bash

cd /root/occurrences

[[ ! -e config.yml ]] && cp config.yml.dist config.yml

nohup rackup > rackup.log 2>&1 &

/usr/sbin/sshd -D

