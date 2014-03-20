#!/bin/bash

cd /root/occurrences && nohup rackup > rackup.log 2>&1 &

/usr/sbin/sshd -D

