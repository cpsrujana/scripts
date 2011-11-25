#!/bin/bash

#####################################################
# This script will install nginx,
# and download a pre-defined config from this repo
#####################################################

# Nginx Defaults
NGINX_URL="http://www.nginx.org/download/nginx-1.0.2.tar.gz"
NGINX_TGZ="nginx-1.0.2.tar.gz"
NGINX_DIR="nginx-1.0.2"

# Download and unpack Nginx
wget $NGINX_URL
tar zvxf $NGINX_TGZ

# Move into the directory and configure
cd $NGINX_DIR

./configure \
--prefix=/opt/nginx \
--with-http_gzip_static_module \
--pid-path=/var/run \
--with-pcre \
>> /tmp/nginx.build.log 2>&1

# Build and Install
make >> /tmp/nginx.build.log 2>&1
make install >> /tmp/nginx.build.log 2>&1

# Download the config
curl -sL http://git.io/IGCwnw > /opt/nginx/conf/nginx.conf

# Create the log dir
mkdir /var/logs/nginx

# Start Nginx
/opt/nginx/sbin/nginx