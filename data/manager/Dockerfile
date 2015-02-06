FROM aquarium-base
MAINTAINER appsplat-team@ooyala.com

RUN apt-get -y install libzookeeper-mt
ADD atlantis-manager.deb /tmp/atlantis-manager.deb
ADD server.toml /etc/atlantis/manager/server.toml
RUN dpkg -i /tmp/atlantis-manager.deb || true

# Ew... the deb waits for the manager to start up, which requires runsv.
RUN runsvdir /etc/service & svpid=$! && apt-get install -f -y && kill $svpid
#RUN apt-get install -f -y || true
