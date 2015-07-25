FROM aquarium-base
MAINTAINER appsplat-team@ooyala.com

RUN apt-get update -qq
RUN apt-get install -y zookeeper

CMD ["/usr/share/zookeeper/bin/zkServer.sh", "start-foreground"]

