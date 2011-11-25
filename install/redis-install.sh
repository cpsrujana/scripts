#!/bin/bash

#########################################
# This script will install redis,
# and download a pre-configured config
#########################################

# Redis Defaults
REDIS_URL="http://redis.googlecode.com/files/redis-2.4.3.tar.gz"
REDIS_TGZ="redis-2.4.3.tar.gz"
REDIS_DIR="redis-2.4.3"

# Download and unpack Nginx
wget $REDIS_URL
tar zvxf $REDIS_TGZ

# Move into the directory and configure
cd $REDIS_DIR