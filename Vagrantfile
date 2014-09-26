hostname = "atlantis-aquarium-vm"
domain   = "local"

Vagrant.configure("2") do |config|
  config.vm.define "aquarium" do |aquarium|
    aquarium.vm.box = ENV["ATLANTIS_VM_BOX"] || "ubuntu1204"
    aquarium.vm.box_url = "http://mirrors.ooyala.com/vagrant/ubuntu1204.box"

    aquarium.vm.hostname = [hostname,domain].join('.')
    aquarium.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 2048]
      v.customize ["modifyvm", :id, "--cpus", 4]
    end

    # Mounts for Atlantis
    aquarium.vm.synced_folder (ENV['ATLANTIS_REPO_ROOT'] || "#{ENV['HOME']}/repos"), "/home/vagrant/repos"

    # Caching
    aquarium.vm.synced_folder "http-cache", "/var/spool/squid3", :owner => "proxy", :group => "proxy"

    # Convenience for storing data across restarts
    aquarium.vm.synced_folder "data", "/home/vagrant/data"

    # Allow controller to be run inside VM
    # TODO(edanaher): This should be done by installing the gem in the VM
    aquarium.vm.synced_folder "bin", "/home/vagrant/bin"
    aquarium.vm.synced_folder "lib", "/home/vagrant/lib"

    # Forward some useful Atlantis ports for convenience
    aquarium.vm.network "forwarded_port", guest: 443, host: 20443
    aquarium.vm.network "forwarded_port", guest: 8000, host: 28000
    aquarium.vm.network "forwarded_port", guest: 8080, host: 28080
    aquarium.vm.network "forwarded_port", guest: 8081, host: 28081
  end
end
