#!/usr/bin/env bash

# ruby, java, git, curl and couchdb
apt-get update
apt-get install aptitude wget curl git tmux vim libxslt-dev libxml2-dev ruby ruby1.9.1-dev libssl-dev -y

# config ruby gems to https
gem sources -r http://rubygems.org
gem sources -r http://rubygems.org/
gem sources -a https://rubygems.org
gem install bundler

# add rbenv
su vagrant -c 'git clone https://github.com/sstephenson/rbenv.git /home/vagrant/.rbenv'
su vagrant -c 'echo export PATH="/home/vagrant/.rbenv/bin:\$PATH" >> /home/vagrant/.bashrc'
su vagrant -c 'echo eval \"\$(rbenv init -)\" >> /home/vagrant/.bashrc'
su vagrant -c 'git clone https://github.com/sstephenson/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build'

# initial config of app
su vagrant -c 'cd /vagrant && rbenv install $(cat .ruby-version) && rbenv rehash'
su vagrant -c 'cd /vagrant && bundle install'
su vagrant -c 'cd /vagrant && [[ ! -e config.yml ]] && cp config.yml.dist config.yml'

