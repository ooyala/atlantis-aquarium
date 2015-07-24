#!/bin/bash

set -e

function start-with-retry() {
    n=0
    until [ $n -ge 5 ]
    do
      bin/atlantis-aquarium start && return
      n=$[$n+1]
      sleep 5
   done
   print "=== Something goes wrong. Start components with aquarium VM failed after 5 attempts!!! ===" 
   return -1

}

if [ "$PWD" != "$HOME/repos/atlantis-aquarium" ]
then
  echo -e "\nPlease git clone atlantis-aquarium under folder $HOME/repos; and run this script from the cloned folder\n"
  exit -1
fi

vagrant up || true
start-with-retry

bin/atlantis-aquarium register-components


