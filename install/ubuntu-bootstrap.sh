#!/bin/bash

#########
# TODO: Add an option for different database installs
#########

txtrst=$(tput sgr0)
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow

stty_orig=`stty -g`
appdir="/opt/apps"
database="none"
rbuser=`whoami`
deploy_usr="deploy"
redis="false"

usage()
{
cat << EOF
usage: $0 options

This script installs the latest ruby, nginx 1.0.2, nodejs, redis(optional), and mysql(optional)

OPTIONS:
  -h    Show this message
  -a    Set the directory for your rails apps - default: $appdir
  -d    Database to install. (mysql, postgres, sqlite, none) - default: none
  -r    Ruby version to install - default: $ruby
  -u    Default RVM user - default: $rbuser
  -i    Install Redis - default: $redis
EOF
}

while getopts "a:d:r:u:i:h" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    a)
      appdir=$OPTARG
      ;;
    d)
      database=$OPTARG
      ;;
    u)
      rbuser=$OPTARG
      ;;
    i)
      redis=$OPTARG
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

stty -echo

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
libcurl4-openssl-dev \
libreadline-dev \
libncurses5-dev \
libpcre3-dev \
libyaml-dev \
libsqlite3-dev \
libc6-dev \
zlib1g-dev \
ncurses-dev \
bison \
autoconf \
git-core \
imagemagick \
ghostscript \
curl \
wget \
vim

#################
# Deployment User
#################
echo "${txtgrn}Creating Deployment User${txtrst}"
function create_deployment_user {
  echo "${txtylw}What would you like your deployment password to be?${txtrst}"
  read deploy_password

  if [ -n "$deploy_password" ]; then
    echo "${txtylw}Confirm your deployment password:${txtrst}"
    read deploy_password_confirm

    if [ -n "$deploy_password_confirm" ]; then
      if [ ! "$deploy_password" == "$deploy_password_confirm" ]; then
        echo "${txtred}Passwords did not match${txtrst}"
        create_deployment_user
      else
        useradd $deploy_usr -s /bin/bash -d /home/$deploy_usr -m -p `mkpasswd $deploy_password`
      fi
    fi
  else
    echo "${txtred}Password cannot be blank${txtrst}"
    create_deployment_user
  fi
}

create_deployment_user

#################
# Install Ruby
#################
echo "${txtgrn}Installing Ruby${txtrst}"
bash < <(curl -sL http://git.io/dDzlvg)

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