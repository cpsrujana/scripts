#!/bin/bash

#########
# TODO: Add an option for different database installs
# TODO: Add an option for updating, and installing requirements for different systems
# TODO: Move variable installs to remote scripts
#########

STTY_ORIG=`stty -g`
APPDIR="/opt/apps"
DATABASE="none"
SYSTEM=
RVMUSR=`whoami`
RUBY="1.9.2-head"
DEPLOY_USER="deploy"

usage()
{
cat << EOF
usage: $0 options

This script installs rvm, nginx, and mysql(optional)

OPTIONS:
  -h    Show this message
  -a    Set the directory for your rails apps - default: $APPDIR
  -d    Database to install. (mysql, postgres, sqlite, none) - default: none
  -r    Ruby version to install - default: $RUBY
  -u    Default RVM user - default: $RVMUSR
EOF
}

while getopts "a:d:r:u:h" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    a)
      APPDIR=$OPTARG
      ;;
    d)
      DATABASE=$OPTARG
      ;;
    r)
      RUBY=$OPTARG
      ;;
    u)
      RVMUSR=$OPTARG
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

stty -echo

if [ "$(whoami)" != "root" ]; then
  echo "You must be root to run this script."
  exit 1
fi

#################
# System Update
#################
echo "# Updating your system"

apt-get -y -q=2 update

########################################
# Install the required dependencies
########################################
echo "# Installing Dependencies"

apt-get -y -q=2 install build-essential \
libxml2-dev \
libxslt-dev \
libcurl4-openssl-dev \
libreadline-dev \
libncurses5-dev \
libpcre3-dev \
libmysqlclient-dev \
sqlite3 \
libsqlite3-dev \
libc6-dev \
ncurses-dev \
bison \
autoconf \
git-core \
imagemagick \
ghostscript \
libmagick9-dev \
mysql-client \
curl \
wget \
vim \
less \
ruby \
screen \
mkpasswd

#################
# Install rvm
#################
echo "# Installing RVM and Ruby on Rails"

bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)
. "/usr/local/rvm/scripts/rvm"

###########################
# Setup RVM environment
###########################
echo '[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"' >> /home/$RVMUSR/.profile
echo "# Adding users to rvm and www-data groups"
usermod -a -G rvm,www-data $RVMUSR

###################################
# Install ruby, and set default
###################################
curl -L http://bit.ly/sRbqye > /etc/gemrc
su - $RVMUSR -c "rvm install $RUBY -C --sysconfdir=/etc"
su - $RVMUSR -c "rvm use --default $RUBY"

#################
# Install Rails
#################
# Disabled, installed per app via bundler
# gem install rails bundler --no-ri --no-rdoc

#################
# Install God
#################
su - $RVMUSR -c "gem install god"
mkdir /etc/god

# God Configuration
curl -L http://bit.ly/trHF90 > /etc/init.d/god
curl -L http://bit.ly/ufNax2 > /etc/default/god
curl -L http://bit.ly/ryFCTB > /etc/god/file_watch.god
curl -L http://bit.ly/uNOUDQ > /etc/god/nginx.god
curl -L http://bit.ly/sxkZRP > /etc/god/mysql.god

#################
# Deployment User
#################
function create_deployment_user {
  echo "What would you like your deployment password to be?"
  read DEPLOY_PASSWORD

  if [ -n "$DEPLOY_PASSWORD" ]; then
    echo "Confirm your deployment password:"
    read DEPLOY_PASSWORD_CONFIRM
    
    if [ -n "$DEPLOY_PASSWORD_CONFIRM" ]; then
      if [ ! "$DEPLOY_PASSWORD" == "$DEPLOY_PASSWORD_CONFIRM" ]; then
        echo "Passwords did not match"
        create_deployment_user
      else
        echo "Creating Deployment User"
        useradd $DEPLOY_USER -s /bin/bash -d /home/$DEPLOY_USER -m -p `mkpasswd $DEPLOY_PASSWORD`
        usermod -a -G rvm,www-data $DEPLOY_USER
      fi
    fi
  else
    echo "Password cannot be blank"
    create_deployment_user
  fi
}

create_deployment_user

#################
# Install Nginx
#################
echo "# Installing Ngnx"

NGINX_URL="http://www.nginx.org/download/nginx-1.0.2.tar.gz"
NGINX_TGZ="nginx-1.0.2.tar.gz"
NGINX_DIR="nginx-1.0.2"

wget $NGINX_URL
tar zvxf $NGINX_TGZ
cd $NGINX_DIR

./configure --prefix=/opt/nginx --with-http_gzip_static_module --pid-path=/var/run --with-pcre

make
make install

curl -L http://bit.ly/w2Xmzj > /opt/nginx/conf/nginx.conf         # Nginx Base Config
/opt/nginx/sbin/nginx                                             # Start the server

#################
# App Dir
#################
mkdir -p $APPDIR
chown -R root:www-data $APPDIR
chmod -R 2775 $APPDIR
chmod -R +s $APPDIR

##########################
# MySQL
##########################

if [[ $DATABASE == "mysql" ]]
then

  MYSQL_PERCENT=40
  function set_mysql_password {
    echo "What would you like your MySQL password to be?"
    read MYSQL_PASSWORD

    if [ -n "$MYSQL_PASSWORD" ]; then
      echo "Confirm your MySQL password:"
      read MYSQL_PASSWORD_CONFIRM
      
      if [ -n "$MYSQL_PASSWORD_CONFIRM" ]; then
        if [ ! "$MYSQL_PASSWORD" == "$MYSQL_PASSWORD_CONFIRM" ]; then
          echo "Passwords did not match"
          set_mysql_password
        fi
      fi
    else
      echo "Password cannot be blank"
      set_mysql_password
    fi
  }
  set_mysql_password

  echo "# Installing MySQL"

  echo "mysql-server-5.1 mysql-server/root_password password $MYSQL_PASSWORD" | debconf-set-selections
  echo "mysql-server-5.1 mysql-server/root_password_again password $MYSQL_PASSWORD" | debconf-set-selections
  apt-get -y install mysql-server mysql-client

  echo "Sleeping while MySQL starts up for the first time..."
  sleep 5

  # Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%
  sed -i -e 's/^#skip-innodb/skip-innodb/' /etc/mysql/my.cnf # disable innodb - saves about 100M

  MEM=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) # how much memory in MB this system has
  MYMEM=$((MEM*MYSQL_PERCENT/100)) # how much memory we'd like to tune mysql with
  MYMEMCHUNKS=$((MYMEM/4)) # how many 4MB chunks we have to play with

  # mysql config options we want to set to the percentages in the second list, respectively
  OPTLIST=(key_buffer sort_buffer_size read_buffer_size read_rnd_buffer_size myisam_sort_buffer_size query_cache_size)
  DISTLIST=(75 1 1 1 5 15)

  for opt in ${OPTLIST[@]}; do
    sed -i -e "/\[mysqld\]/,/\[.*\]/s/^$opt/#$opt/" /etc/mysql/my.cnf
  done

  for i in ${!OPTLIST[*]}; do
    val=$(echo | awk "{print int((${DISTLIST[$i]} * $MYMEMCHUNKS/100))*4}")
    if [ $val -lt 4 ]
      then val=4
    fi
    config="${config}\n${OPTLIST[$i]} = ${val}M"
  done

  sed -i -e "s/\(\[mysqld\]\)/\1\n$config\n/" /etc/mysql/my.cnf
  sed -i -e "s/\(\[mysqld\]\)/\1\npid = \/var\/run\/mysqld\/mysqld.pid/" /etc/mysql/my.cnf
  service mysql restart
fi

stty $STTY_ORIG