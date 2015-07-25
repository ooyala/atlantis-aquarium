#!/bin/bash

set -ex

function print() {
  echo [33m"$@"[0m
}

function build-with-retry() {
  print "=== Building $@ ==="
  n=0
  until [ $n -ge 3 ]
  do
    bin/atlantis-aquarium build $@ && return
    n=$[$n+1]
    print "=== Build $@ failed, will retry in 10 second ==="     
    sleep 10
  done
  print "=== BUILD $@ FAILED !!! ===" 
  return -1
}

print "==== git clone atlantis components ===="
bin/gather-files

print "==== Bringing vagrant up ===="
vagrant up $aquarium
vagrant ssh $aquarium -c 'bin/ruby-upgrade.sh'


print "==== Provisioning ===="
bin/atlantis-aquarium provision

print "==== Building and starting services ===="
for component in base-aquarium-image zookeeper registry builder manager router supervisor
do
  build-with-retry $component
done

print "==== Building base layers ===="
bin/atlantis-aquarium build-layers --base
sleep 5
bin/atlantis-aquarium build-layers --builder

print "==== Registering components ===="
bin/atlantis-aquarium register-components

print "==== Spinning up sample apps ===="
bin/atlantis-aquarium base-cluster
