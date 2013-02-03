#!/bin/bash

txtrst=$(tput sgr0)
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow

appdir="/opt/apps"
rbuser=`whoami`
deploy_usr="deploy"

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
echo "${txtgrn}Installing Redis${txtrst}"
bash < <(curl -sL http://git.io/6hJU6Q)

#################
# Install Nginx
#################
echo "${txtgrn}# Installing Nginx${txtrst}"
bash < <(curl -sL http://git.io/n9C8kg)

############################
# Install MySQL
############################
echo "${txtgrn}Installing MySQL${txtrst}"
bash <(curl -sL http://git.io/6kmGow)