#!/bin/bash

/bin/cat << EOF > /etc/yum.repos.d/base.repo
[base]
name=CentOS-$1 - Base
baseurl=http://fmtsd01.thoughtworks.com/centos/6.8/os/$2/
enabled=1
fastestmirror_enabled=0
gpgcheck=0
mirrorlist=http://mirrorlist.centos.org/?release=$1&arch=$2&repo=os
EOF

/bin/cat << EOF > /etc/yum.repos.d/centos-release-scl-rh.repo
[centos-release-scl-rh]
name=Yum Repository
baseurl=http://mirror.centos.org/centos/$1/sclo/$2/rh/
enabled=1
fastestmirror_enabled=0
gpgcheck=0
EOF

yum makecache
yum install -y epel-release centos-release-scl
yum install -y unzip git rh-ruby22-rubygem-rake
