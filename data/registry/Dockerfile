FROM aquarium-base
MAINTAINER appsplat-team@ooyala.com

RUN apt-get update
ADD atlantis-registry.deb /tmp/atlantis-registry.deb
ADD config.json /etc/atlantis/registry/config.json
RUN dpkg -i /tmp/atlantis-registry.deb || true

# Ew... the deb waits for the manager to start up, which requires runsv.
RUN runsvdir /etc/service & svpid=$! && apt-get install -f -y && kill $svpid
#RUN apt-get install -f -y || true
