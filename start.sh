#!/bin/bash

ENV=production

[[ ! -e /root/occurrences/config.yml ]] && cp /root/occurrences/config.yml.dist /root/occurrences/config.yml

cd /root/occurrences && nohup rackup > rackup.log 2>&1 &

/usr/sbin/sshd -D

