#!/bin/bash

cd /root/occurrences

[[ ! -e config.yml ]] && cp config.yml.dist config.yml

unicorn

