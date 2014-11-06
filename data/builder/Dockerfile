FROM aquarium-base
MAINTAINER appsplat-team@ooyala.com

# We need a custom Java package
RUN echo 'deb [arch=amd64] http://ppa.launchpad.net/webupd8team/java/ubuntu precise main' >> /etc/apt/sources.list.d/oracle-java.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886

# Set up docker-in-docker
RUN echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
RUN apt-get update -qq
RUN apt-get install -qqy --force-yes lxc-docker

# Install java before addiing files for better caching
RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
RUN apt-get install oracle-java7-installer -y

ADD atlantis-builder.deb /tmp/atlantis-builder.deb
RUN dpkg -i /tmp/atlantis-builder.deb || true
ADD atlantis-builderd.deb /tmp/atlantis-builderd.deb
RUN dpkg -i /tmp/atlantis-builderd.deb || true

# Ew... the deb waits for the manager to start up, which requires runsv.
RUN runsvdir /etc/service & svpid=$! && apt-get install -f -y && kill $svpid
#RUN apt-get install -f -y || true

# And the dpkg hardcodes the real id_rsa.pub; copy in our local one.
ADD builder_id_rsa.pub /opt/atlantis/builder/.ssh/id_rsa.pub
ADD builder_id_rsa.pub /opt/atlantis/builder/layers/base/root/.ssh/authorized_keys

ADD ./start.sh /usr/local/bin/start.sh
VOLUME /var/lib/docker
CMD ["bash", "/usr/local/bin/start.sh"]
