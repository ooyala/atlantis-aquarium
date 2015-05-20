FROM aquarium-base
MAINTAINER appsplat-team@ooyala.com

RUN apt-get update
ADD go-docker-registry.deb /tmp/go-docker-registry.deb
ADD config.json /etc/go-docker-registry/config.json
RUN dpkg -i /tmp/go-docker-registry.deb || true

#docker issue #5529, enable ssh to container
RUN sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' /etc/pam.d/sshd

# Ew... the deb waits for the manager to start up, which requires runsv.
RUN runsvdir /etc/service & svpid=$! && apt-get install -f -y && kill $svpid
#RUN apt-get install -f -y || true

