FROM ubuntu:14.04 
MAINTAINER appsplat-team@ooyala.com

RUN apt-get update
RUN apt-get -y install curl
RUN rm -rf /etc/service/rsyslog
ENV SSHD_PORT 22
# TODO(edanaher): Do this dynamically based on gateway, if 3128 responds.
RUN echo 'Acquire::http::Proxy "http://172.17.42.1:3128";' > /etc/apt/apt.conf.d/99http-proxy
RUN https_proxy=https://172.17.42.1:3128 curl -sL https://golang.org/dl/go1.3.linux-amd64.tar.gz | tar -xz -C /usr/local
RUN cd /usr/bin; for x in $(find /usr/local/go/bin -type f); do ln -s $x; done;
# Configure ssh for the fake supervisor key
ADD supervisor_master_id_rsa.pub /root/.ssh/authorized_keys.d/master.pub
ADD supervisor_master_id_rsa.pub /root/.ssh/authorized_keys

CMD ["runsvdir", "/etc/service"]
