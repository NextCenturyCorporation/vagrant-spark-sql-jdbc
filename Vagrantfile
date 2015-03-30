# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.4.3"
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	config.vm.define :master do |master|
		master.vm.box = "centos65"
		master.vm.box_url = "https://github.com/2creatives/vagrant-centos/releases/download/v6.5.1/centos65-x86_64-20131205.box"
		master.vm.provider "vmware_fusion" do |v|
			v.vmx["memsize"]  = "3072"
		end
		master.vm.provider "virtualbox" do |v|
		  v.name = "spark-sql-jdbc"
		  v.customize ["modifyvm", :id, "--memory", "3072"]
		end
		master.vm.network :private_network, ip: "192.168.34.10"
		master.vm.hostname = "spark-sql-jdbc"
		master.vm.provision :shell, :path=> 'setup.sh'
	end
end
