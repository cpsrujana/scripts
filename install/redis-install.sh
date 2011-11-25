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

# Move into the directory and build
cd $REDIS_DIR
make

# Copy the executables to the /opt/redis directory
mkdir /opt/redis
cp src/redis-benchmark /opt/redis/
cp src/redis-cli /opt/redis/
cp src/redis-server /opt/redis/
cp src/redis-check-aof /opt/redis/
cp src/redis-check-dump /opt/redis/

# Download the pre-defined config
curl -L http://git.io/w4GcUg > /etc/default/redis
chmod +x /etc/init.d/redis

# Start redis
echo "# Starting Redis"
/etc/init.d/redis start