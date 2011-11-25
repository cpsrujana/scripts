#!/bin/bash

#######################################
# This script will install MySQL,
# configure it with a root password,
# and tun it to 40% memory usage
#######################################

#######################################
# Install Required Dependencies
#######################################
apt-get -y -q=2 install mysql-client

#######################################
# Install MySQL
#######################################

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

# Start MySQL
service mysql restart