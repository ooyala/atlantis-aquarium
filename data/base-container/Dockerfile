FROM ubuntu:14.04
MAINTAINER appsplat-team@ooyala.com

RUN apt-get update
RUN apt-get -y install curl runit openssh-server
RUN rm -rf /etc/service/rsyslog
ENV SSHD_PORT 22

# Add sshd to /etc/service
RUN mkdir /etc/service/sshd /var/log/sshd
ADD sshd /etc/service/sshd

# TODO(edanaher): Do this dynamically based on gateway, if 3128 responds.
RUN echo 'Acquire::http::Proxy "http://172.17.42.1:3128";' > /etc/apt/apt.conf.d/99http-proxy
RUN https_proxy=https://172.17.42.1:3128 curl -sL https://golang.org/dl/go1.3.linux-amd64.tar.gz | tar -xz -C /usr/local
RUN cd /usr/bin; for x in $(find /usr/local/go/bin -type f); do ln -s $x; done;
# Configure ssh for the fake supervisor key
ADD id_rsa.pub /root/.ssh/authorized_keys.d/master.pub
ADD id_rsa.pub /root/.ssh/authorized_keys

CMD ["runsvdir", "/etc/service"]
