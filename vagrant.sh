#!/usr/bin/env bash

# basic stuff
add-apt-repository ppa:brightbox/ruby-ng -y
apt-get update
apt-get upgrade -y
apt-get install wget curl git ruby2.1 ruby2.1-dev -y

# setup app deps
if [[ ! -e /home/vagrant/.app_done ]]; then
    # config ruby gems to use https
    gem sources -r http://rubygems.org/
    gem sources -a https://rubygems.org/

    # uh?
    gem install bundler
    #cd /vagrant && bundle install

    # initial config of app
    #su vagrant -lc 'cd /vagrant && gem install bundle'
    #su vagrant -lc 'cd /vagrant && bundle install'
    su vagrant -lc 'cd /vagrant && [[ ! -e config.yml ]] && cp config.yml.dist config.yml'
    su vagrant -lc 'touch /home/vagrant/.app_done'
fi

# docker register to etcd
if [[ ! -e /usr/bin/docker2etcd ]]; then
    wget https://gist.githubusercontent.com/diogok/9604900/raw/afcc71dbec207a4f7b12a98e695622d902b5b022/register-docker-to-etcd.sh \
          -O /usr/bin/docker2etcd 
    chmod +x /usr/bin/docker2etcd 
fi
/usr/bin/docker2etcd

# setup couchdb
HUB=$(docker ps | grep datahub | awk '{ print $10 }' | grep -e '[0-9]\{5\}' -o)
curl -X PUT http://localhost:$HUB/cncflora

