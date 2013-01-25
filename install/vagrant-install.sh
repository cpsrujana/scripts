#!/bin/bash

#########
# TODO: Add an option for different database installs
#########

txtrst=$(tput sgr0)
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow

appdir="/opt/apps"
database="none"
redis="false"

if [ "$(whoami)" != "root" ]; then
  echo "${txtred}You must be root to run this script.${txtrst}"
  exit 1
fi

#################
# System Update
#################
echo "${txtgrn}Updating your system${txtrst}"
apt-get update

########################################
# Install the required dependencies
########################################
echo "${txtgrn}Installing Dependencies${txtrst}"

apt-get -y -qq install build-essential \
libxml2-dev \
libxslt-dev \
libcurl4-openssl-dev \
libreadline-dev \
libncurses5-dev \
libpcre3-dev \
libyaml-dev \
libc6-dev \
ncurses-dev \
bison \
autoconf \
git-core \
imagemagick \
ghostscript \
libmagick9-dev \
curl \
wget \
vim \
less \
screen \
mkpasswd \
mysql-client \
libmysqlclient-dev

#################
# Install Ruby
#################
echo "${txtgrn}Installing Ruby${txtrst}"

RUBY_URL="http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p327.tar.gz"
RUBY_TBZ="ruby-1.9.3-p327.tar.gz"
RUBY_DIR="ruby-1.9.3-p327"

# Download and unpack Nginx
wget -q $RUBY_URL
tar xvjpf $RUBY_TBZ

# Move into the directory and configure
cd $RUBY_DIR

# Build and Install
./configure
make
make install

#################
# App Dir
#################
echo "${txtgrn}Creating Application Directory${txtrst}"
mkdir -p $appdir
chown -R root:www-data $appdir
chmod -R 2775 $appdir
chmod -R +s $appdir

#################
# Install Node.JS
#################
git clone git://github.com/ry/node.git
cd node && ./configure && make && make install

#################
# Install Redis
#################
echo "${txtgrn}Installing Redis${txtrst}"

# Redis Defaults
REDIS_URL="http://redis.googlecode.com/files/redis-2.4.3.tar.gz"
REDIS_TGZ="redis-2.4.3.tar.gz"
REDIS_DIR="redis-2.4.3"

# Download and unpack Nginx
wget -q $REDIS_URL
tar zxf $REDIS_TGZ

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
curl -sL http://git.io/pu0alA > /etc/default/redis

# Download the init script, and make executable
curl -sL http://git.io/w4GcUg > /etc/init.d/redis
chmod +x /etc/init.d/redis

# Start redis
/etc/init.d/redis start

############################
# Install the selected DB
############################
echo "${txtgrn}Installing MySQL${txtrst}"

# Configure MySQL
echo "${txtgrn}Continuing with MySQL Installation${txtrst}"
echo "mysql-server-5.1 mysql-server/root_password password $MYSQL_PASSWORD" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password $MYSQL_PASSWORD" | debconf-set-selections
apt-get -y -qq install mysql-server mysql-client

echo "${txtgrn}Sleeping while MySQL starts up for the first time...${txtrst}"
sleep 5

# Start MySQL
service mysql restart