# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Don't forget to install vagrant-hostmanager plugin
  # vagrant plugin install vagrant-hostmanager
  config.vm.box = "ubuntu/focal64"

  config.vm.provider "virtualbox" do |vb|
    # vb.gui = true
    vb.memory = "6144"
    vb.cpus = 4
    vb.name = "mvbox"
  end

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true
  config.hostmanager.aliases = %w(magento.box)

  config.vm.hostname = "magento.box"

  config.vm.network "forwarded_port", guest: 80, host: 8080, auto_correct: true
  config.vm.network "forwarded_port", guest: 9200, host: 9200, host_ip: "127.0.0.1"
  config.vm.network "private_network", ip: "192.168.68.8"

  # config.vm.synced_folder ".", "/var/www/html", :nfs => { :mount_options => ["dmode=777","fmode=666"] }
  # config.vm.synced_folder ".", "/var/www/html", :mount_options => ["dmode=777","fmode=666"]
  # config.vm.synced_folder ".", "/var/www/html", owner: "vagrant", group: "www-data", mount_options: ["dmode=775,fmode=664"]
  # config.vm.synced_folder ".", "/var/www/html"

  config.vm.provision :shell, :inline => "sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/Asia/Kolkata /etc/localtime", run: "always"
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL

  config.vm.provision "shell", path: "bootstrap.sh"
end
