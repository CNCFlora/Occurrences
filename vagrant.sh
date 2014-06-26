#!/usr/bin/env bash

# basic stuff
add-apt-repository ppa:brightbox/ruby-ng -y
apt-get update
apt-get upgrade -y
apt-get install wget curl git ruby2.1 ruby2.1-dev -y

# setup app deps
if [[ ! -e /root/.app_done ]]; then
    # config ruby gems to use https
    gem sources -r http://rubygems.org/
    gem sources -a https://rubygems.org/

    # uh?
    gem install bundler
    #cd /vagrant && bundle install

    # initial config of app
    su vagrant -lc 'cd /vagrant && gem install bundler'
    su vagrant -lc 'cd /vagrant && bundle install'
    su vagrant -lc 'cd /vagrant && [[ ! -e config.yml ]] && cp config.yml.dist config.yml'
    touch /root/.app_done
fi

# docker register to etcd
if [[ ! -e /usr/bin/docker2etcd ]]; then
    wget https://gist.githubusercontent.com/diogok/24cf050e880731783d40/raw/e0f0e05e532488fec803c68022d514975034e8d8/docker2etcd.rb \
          -O /usr/bin/docker2etcd 
    chmod +x /usr/bin/docker2etcd 
fi
/usr/bin/docker2etcd

# setup couchdb
HUB=$(docker ps | grep datahub | awk '{ print $10 }' | grep -e '[0-9]\{5\}' -o)
curl -X PUT http://localhost:$HUB/cncflora

