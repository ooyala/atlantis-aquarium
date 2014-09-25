#!/bin/bash

set -ex

function print() {
	echo [33m"$@"[0m
}

print "==== Destroying vagrant ===="
vagrant destroy aquarium
rm -f data/status.json

rm -rf data/*/cidfile* data/*/ip*
