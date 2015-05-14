FROM aquarium-base
MAINTAINER appsplat-team@ooyala.com

# TODO(edanaher): Do this dynamically based on gateway, if 3128 responds.
#RUN echo 'Acquire::http::Proxy "http://172.17.42.1:3128";' > /etc/apt/apt.conf.d/99http-proxy
RUN apt-get update -qq
RUN apt-get install -y zookeeper

CMD ["/usr/share/zookeeper/bin/zkServer.sh", "start-foreground"]

