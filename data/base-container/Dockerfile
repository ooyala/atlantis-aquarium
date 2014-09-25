FROM registry1.sjc1-s.atlantis.staging.services.ooyala.com/builder/precise64-go1.1.2-0.5.0
MAINTAINER appsplat-team@ooyala.com

RUN rm -r /etc/service/moxy
RUN rm -r /etc/service/rsyslog
ENV SSHD_PORT 22
# TODO(edanaher): Do this dynamically based on gateway, if 3128 responds.
RUN echo 'Acquire::http::Proxy "http://172.17.42.1:3128";' > /etc/apt/apt.conf.d/99http-proxy

# Configure ssh for the fake supervisor key
ADD supervisor_master_id_rsa.pub /root/.ssh/authorized_keys.d/master.pub
ADD supervisor_master_id_rsa.pub /root/.ssh/authorized_keys

CMD ["runsvdir", "/etc/service"]
