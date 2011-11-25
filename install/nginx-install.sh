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
--with-pcre

# Build and Install
make && make install

# Download the config
curl -L http://git.io/IGCwnw > /opt/nginx/conf/nginx.conf

# Start Nginx
echo "# Starting Nginx"
/opt/nginx/sbin/nginx