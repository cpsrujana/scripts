#!/bin/bash

#########
# TODO: Add an option for different database installs
#########

STTY_ORIG=`stty -g`
APPDIR="/opt/apps"
DATABASE="mysql"
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
curl -L http://git.io/0UeTHA > /etc/gemrc
su - $RVMUSR -c "rvm install $RUBY -C --sysconfdir=/etc"
su - $RVMUSR -c "rvm use --default $RUBY@global"

#################
# Install God
#################
su - $RVMUSR -c "gem install god"
su - $RVMUSR -c "rvm wrapper $RUBY@global bootup god"

# Create the god directory
mkdir /etc/god

# God Configuration Scripts
curl -L http://git.io/si9nvQ > /etc/default/god
curl -L http://git.io/GIkhIA > /etc/god/file_watch.god
curl -L http://git.io/M_3Wwg > /etc/god/nginx.god
curl -L http://git.io/Rw6Jog > /etc/god/mysql.god

# Download, init.d script, make executable and start
curl -L http://git.io/9IpMAw > /etc/init.d/god
chmod +x /etc/init.d/god
/etc/init.d/god start

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

create_deployment_user                                            # Start the server

#################
# App Dir
#################
mkdir -p $APPDIR
chown -R root:www-data $APPDIR
chmod -R 2775 $APPDIR
chmod -R +s $APPDIR

#################
# Install Nginx
#################
echo "# Installing Nginx"

bash < <(curl -s http://git.io/n9C8kg)

############################
# Install the selected DB
############################
echo "# Installing $DATABASE"

if [[ $DATABASE == "mysql" ]]
then
  bash < <(curl -s http://git.io/6kmGow)
fi

# Restore STTY
stty $STTY_ORIG