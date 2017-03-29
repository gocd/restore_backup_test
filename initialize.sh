set -e

/bin/cat << EOF > /etc/yum.repos.d/base.repo
[base]
name=CentOS-$releasever - Base
baseurl=http://fmtsd01.thoughtworks.com/centos/6.8/os/$basearch/
enabled=1
fastestmirror_enabled=0
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
EOF

/bin/cat << EOF > /etc/yum.repos.d/centos-release-scl-rh.repo
[centos-release-scl-rh]
name=Yum Repository
baseurl=http://mirror.centos.org/centos/$releasever/sclo/$basearch/rh/
enabled=1
fastestmirror_enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
EOF

yum makecache
yum install -y epel-release centos-release-scl
yum install -y unzip git rh-ruby22-rubygem-rake
