FROM aquarium-base
MAINTAINER appsplat-team@ooyala.com

# Set up docker-in-docker
RUN echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
RUN apt-get update -qq
RUN apt-get install -qqy --force-yes lxc-docker

ADD atlantis-supervisor.deb /tmp/atlantis-supervisor.deb
ADD server.toml /etc/atlantis/supervisor/server.toml
RUN dpkg -i /tmp/atlantis-supervisor.deb || true

# Ew... the deb waits for the supervisor to start up, which requires runsv.
RUN runsvdir /etc/service & svpid=$! && apt-get install -f -y --force-yes && kill $svpid && sleep 10
#RUN apt-get install -f -y || true

ADD ./start.sh /usr/local/bin/start.sh
VOLUME /var/lib/docker
CMD ["bash", "/usr/local/bin/start.sh"]
