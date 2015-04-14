# References used:
# https://github.com/phusion/baseimage-docker
# https://github.com/ValdikSS/aceproxy
# https://github.com/ikatson/docker-acestream-proxy/

# Key config files:
# /usr/local/aceproxy/aceconfig.py
FROM phusion/baseimage:0.9.16
MAINTAINER nakanaa

# Set correct environment variables
ENV REFRESHED_AT 14.04.2015
ENV HOME /root
WORKDIR $HOME

# Add AceStream repo for acestream-engine package
RUN echo 'deb http://repo.acestream.org/ubuntu/ trusty main' > /etc/apt/sources.list.d/acestream.list && \
    curl -L http://repo.acestream.org/keys/acestream.public.key | apt-key add -

RUN \
  # Install required packages
  apt-get -q -y update && DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
    unzip \
    acestream-engine \
    vlc-nox \
    python-gevent  \
    python-psutil && \
  # Clean up APT when done
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Make sure setuptools is installed (Stops on error "No module named pkg_resources" otherwise)
RUN curl -L https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py | python && rm -rf *

# Create user vlc; VLC cannot be run as root
RUN adduser --disabled-password --gecos "" vlc

ENV ACEPROXY_VERSION v0.9.1

RUN \
    # Download AceProxy
    curl -LO https://github.com/ValdikSS/aceproxy/archive/${ACEPROXY_VERSION}.zip && \
    # Extract
    unzip *.zip && \
    # Move to /usr/local/
    mv */ /usr/local/aceproxy && \
    # Create symbolic link
    ln -s /usr/local/aceproxy/acehttp.py /usr/bin/acehttp && \
    # Remove downloaded files
    rm -rf *

# Setup runit
RUN mkdir /etc/service/acestream && mkdir /etc/service/vlc
ADD runit/acestream /etc/service/acestream/run
ADD runit/vlc /etc/service/vlc/run

RUN curl -L https://raw.githubusercontent.com/nakanaa/conf-fetcher/master/conf-fetcher.sh -o /etc/my_init.d/01_conf-fetcher.sh && chmod +x /etc/my_init.d/01_conf-fetcher.sh

# Expose ports
# AceProxy port
EXPOSE 8000
# AceStream port
# EXPOSE 62062

# Use baseimage-docker's init system
ENTRYPOINT ["/sbin/my_init", "--"]

# Define default command
CMD ["/usr/bin/acehttp"]