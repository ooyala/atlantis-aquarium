#!/bin/bash

set -ex

function print() {
	echo [33m"$@"[0m
}
print "==== Bringing vagrant up ===="
vagrant up $aquarium
vagrant ssh $aquarium -c 'bin/ruby-upgrade.sh'
#vagrant ssh $aquarium -c 'sudo apt-get update'
#vagrant ssh $aquarium -c 'sudo apt-get install -y ruby1.9.1 ruby1.9.1-dev'
#vagrant ssh $aquarium -c 'sudo gem install docopt xhr-ifconfig'

print "==== Provisioning ===="
bin/atlantis-aquarium provision

print "==== Building and starting services ===="
#bin/atlantis-aquarium build all

print "==== Building base layers ===="
#bin/atlantis-aquarium build-layers

print "==== Registering components ===="
#bin/atlantis-aquarium register-components

print "==== Spinning up sample apps ===="
#bin/atlantis-aquarium base-cluster
