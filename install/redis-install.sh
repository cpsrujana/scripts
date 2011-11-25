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
wget -q $REDIS_URL
tar zxf $REDIS_TGZ

# Move into the directory and build
cd $REDIS_DIR
make > /tmp/redis.build.log 2>&1

# Copy the executables to the /opt/redis directory
mkdir /opt/redis
cp src/redis-benchmark /opt/redis/
cp src/redis-cli /opt/redis/
cp src/redis-server /opt/redis/
cp src/redis-check-aof /opt/redis/
cp src/redis-check-dump /opt/redis/

# Download the pre-defined config
curl -sL http://git.io/pu0alA > /etc/default/redis

# Download the init script, and make executable
curl -sL http://git.io/w4GcUg > /etc/init.d/redis
chmod +x /etc/init.d/redis

# Start redis
/etc/init.d/redis start