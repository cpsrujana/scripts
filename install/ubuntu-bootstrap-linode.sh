#!/bin/bash

#<udf name="hostname" label="System Host Name">
#<udf name="adminuser" default="admin" label="Admin user name">
#<udf name="adminpassword" label="Admin user password">
#<udf name="deployuser" default="admin" label="Admin user name">
#<udf name="deploypassword" label="Admin user password">
#<udf name="mysql_password" label="MySQL Password">

#########
# TODO: Add an option for different database installs
#########

txtrst=$(tput sgr0)
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow

stty_orig=`stty -g`
appdir="/opt/apps"
database="mysql"
rvmusr=`whoami`
ruby="1.9.2-head"
redis="true"

if [ "$(whoami)" != "root" ]; then
  echo "${txtred}You must be root to run this script.${txtrst}"
  exit 1
fi

#################
# Hostname
#################
echo $HOSTNAME > /etc/hostname
echo -e "\n127.0.0.1 $HOSTNAME.local $HOSTNAME\n" >> /etc/hosts
service hostname start

#################
# System Update
#################
echo "${txtgrn}Updating your system${txtrst}"

apt-get -y -qq2 update

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
echo "${txtgrn}Installing RVM and Ruby on Rails${txtrst}"

bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)
. "/usr/local/rvm/scripts/rvm"

###########################
# Setup RVM environment
###########################
echo '[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"' >> /home/$rvmusr/.profile
echo "${txtgrn}Adding users to rvm and www-data groups${txtrst}"
usermod -a -G rvm,www-data $rvmusr

###################################
# Install ruby, and set default
###################################
echo "${txtgrn}Installing Ruby${txtrst}"
curl -sL http://git.io/0UeTHA > /etc/gemrc
su - $rvmusr -c "rvm install $ruby -C --sysconfdir=/etc"
su - $rvmusr -c "rvm use --default $ruby@global"

#################
# Install God
#################
echo "${txtgrn}Installing God${txtrst}"
su - $rvmusr -c "gem install god"
su - $rvmusr -c "rvm wrapper $ruby@global bootup god"

# Create the god directory
mkdir /etc/god

# God Configuration Scripts
curl -sL http://git.io/si9nvQ > /etc/default/god
curl -sL http://git.io/GIkhIA > /etc/god/file_watch.god
curl -sL http://git.io/M_3Wwg > /etc/god/nginx.god
curl -sL http://git.io/Rw6Jog > /etc/god/mysql.god
curl -sL http://git.io/KmtPdQ > /etc/god/redis.god

# Download, init.d script, make executable and start
curl -sL http://git.io/9IpMAw > /etc/init.d/god
chmod +x /etc/init.d/god
/etc/init.d/god start

#################
# Admin User
#################
echo "${txtgrn}Creating Deployment User${txtrst}"
useradd $ADMINUSER -s /bin/bash -d /home/$ADMINUSER -m -p `mkpasswd $ADMINPASSWORD`
usermod -a -G rvm,www-data $ADMINUSER

#################
# Deployment User
#################
echo "${txtgrn}Creating Deployment User${txtrst}"
useradd $DEPLOYUSER -s /bin/bash -d /home/$DEPLOYUSER -m -p `mkpasswd $DEPLOYPASSWORD`
usermod -a -G rvm,www-data $DEPLOYUSER

#################
# App Dir
#################
echo "${txtgrn}Creating Application Directory${txtrst}"
mkdir -p $appdir
chown -R root:www-data $appdir
chmod -R 2775 $appdir
chmod -R +s $appdir

#################
# Install Redis
#################
if [[ $redis == "true" ]]
then
  echo "${txtgrn}Installing Redis${txtrst}"
  bash < <(curl -sL http://git.io/6hJU6Q)
fi

#################
# Install Nginx
#################
echo "${txtgrn}# Installing Nginx${txtrst}"
bash < <(curl -sL http://git.io/n9C8kg)

############################
# Install the selected DB
############################
if [[ $database == "mysql" ]]
then
  echo "${txtgrn}Installing MySQL${txtrst}"
  bash <(curl -sL http://git.io/6kmGow)
fi

# Restore STTY
stty $stty_orig