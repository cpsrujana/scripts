#!/bin/bash

#####################################################
# This script will install ruby
#####################################################

# Nginx Defaults
RUBY_URL="ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p247.tar.bz2"
RUBY_TBZ="ruby-2.0.0-p247.tar.bz2"
RUBY_DIR="ruby-2.0.0-p247"

# Download and unpack Nginx
wget -q $RUBY_URL
tar xvjpf $RUBY_TBZ

# Move into the directory and configure
cd $RUBY_DIR

# Build and Install
./configure
make
make install
