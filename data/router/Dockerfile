FROM aquarium-base
MAINTAINER appsplat-team@ooyala.com

ADD atlantis-router.deb /tmp/atlantis-router.deb
ADD server.internal.toml /etc/atlantis/router/server.internal.toml
ADD server.external.toml /etc/atlantis/router/server.external.toml
RUN dpkg -i /tmp/atlantis-router.deb || true

# Ew... the deb waits for the router to start up, which requires runsv.
RUN runsvdir /etc/service & svpid=$! && apt-get install -f -y && kill $svpid && sleep 10
#RUN apt-get install -f -y || true

# Make internal/external setable at startup
RUN sed -i 's/server.toml/server.${GROUP:-internal}.toml/' /etc/service/atlantis-router/run
