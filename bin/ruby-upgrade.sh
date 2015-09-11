#!/bin/bash
sudo apt-get update

sudo apt-get install -y ruby1.9.1 ruby1.9.1-dev \
  rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 \
  build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev

sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 400 \
  --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz \
            /usr/share/man/man1/ruby1.9.1.1.gz \
  --slave   /usr/bin/ri ri /usr/bin/ri1.9.1 \
  --slave   /usr/bin/irb irb /usr/bin/irb1.9.1 \
  --slave   /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.1

# choose your interpreter
# changes symlinks for /usr/bin/ruby , /usr/bin/gem
if [ -f /usr/bin/gem1.9.1 ]; then
  sudo update-alternatives --set gem /usr/bin/gem1.9.1
fi
# now try
ruby --version
sudo gem install docopt
