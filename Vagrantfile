# Doc at https://docs.vagrantup.com
# Boxes at https://vagrantcloud.com/search
require 'open-uri'

Vagrant.require_version ">= 2.2.4"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"
  config.vm.box_version = "= 9.9.1"
  
  config.vm.network "private_network", type: "dhcp"

  # greet from every configured VM, revealing its hostname
  config.vm.provision "shell", inline: "echo Hello from \$HOSTNAME"

  config.vm.define "master-node" do |node|
    node.vm.hostname = "master-node"
    
    node.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 512]
      v.customize ["modifyvm", :id, "--name", "master-node"]
    end
  end
  
  (1..2).each do |i|
    config.vm.define "worker-node-#{i}" do |node|
      node.vm.hostname = "worker-node-#{i}"
    
      node.vm.provider :virtualbox do |v|
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        v.customize ["modifyvm", :id, "--memory", 512]
        v.customize ["modifyvm", :id, "--name", "worker-node-#{i}"]
      end
    end
  
  end
end
