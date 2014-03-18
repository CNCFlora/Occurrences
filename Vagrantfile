# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "hashicorp/precise32"

  config.vm.provision :shell, :path => "bootstrap.sh"

  config.vm.network "private_network", ip: "192.168.50.12"
  config.vm.network :forwarded_port, host: 9292, guest: 9292, auto_correct: true
end

