# -*- mode: ruby -*-
# vi: set ft=ruby

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

def r(name)
    parts = /([^\/]+)\/(.+)/.match(name)
    repo = ENV['DOCKER_REGISTRY'] || parts[1]
    cont = parts[2]
    "#{repo}/#{cont}"
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.network "private_network", ip: "192.168.50.12"
  config.vm.network :forwarded_port, host: 9292, guest: 9292, auto_correct: true

  config.vm.provision "docker" do |d|
    d.run r("cncflora/etcd"), name: "etcd", args: "-p 8001:80 -p 4001:4001"
    d.run r("cncflora/connect"), name: "connect", args: "-P -v /var/connect:/var/lib/floraconnect:rw"
    d.run r("bradrydzewski/couchdb:1.5"), name: "couchdb", args: "-p 5984:5984 -v /var/couchdb:/usr/local/var/lib/couchdb:rw"
    d.run r("dockerfile/elasticsearch"), name: "elasticsearch", args: "-p 9200:9200"
    d.run r("cncflora/bots"), name: "bots", cmd: "/root/run.sh http://localhost:5984 http://localhost:9200 cncflora2"
    d.run r("cncflora/dwc-services"), name: "dwc-services", args: "-P"
  end

  config.vm.provision :shell, :path => "vagrant.sh"
end

