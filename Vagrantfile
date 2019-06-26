# Doc at https://docs.vagrantup.com
# Boxes at https://vagrantcloud.com/search
require 'open-uri'

Vagrant.require_version ">= 2.2.4"

unless Vagrant.has_plugin?("vagrant-scp")
  raise 'vagrant-scp is not installed! Please run vagrant plugin install vagrant-scp'
end

hosts = {
  masters: [
    "master-node"
  ],
  workers: (1..2).map { |i| "worker-node-#{i}" }
}

generated_ansible_inventory_file="./inventory/generated"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"
  config.vm.box_version = "= 9.9.1"
  
  config.vm.network "private_network", type: "dhcp"

  # greet from every configured VM, revealing its hostname
  config.vm.provision "shell", inline: "echo Hello from \$HOSTNAME"

  (hosts[:masters] + hosts[:workers]).each do |node_name|
    config.vm.define node_name do |node|
      node.vm.hostname = node_name
      
      node.vm.provider :virtualbox do |v|
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        v.customize ["modifyvm", :id, "--memory", 512]
        v.customize ["modifyvm", :id, "--name", node_name]
      end
    end
  
  end
  
  config.trigger.after :up do |trigger|
    File.open(generated_ansible_inventory_file, "w") do |w|
      w.puts "[masters]"        
      hosts[:masters].each { |host| w.puts host }

      w.puts "[workers]"
      hosts[:workers].each { |host| w.puts host }
    end
  end
  
  """
  config.trigger.after :destroy do |trigger|
    File.delete(generated_ansible_inventory_file) if File.exist?(generated_ansible_inventory_file)
  end
  """
end
