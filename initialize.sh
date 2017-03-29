#!/bin/bash

/bin/cat << EOF > /etc/yum.repos.d/base.repo
[base]
name=CentOS-$1 - Base
baseurl=http://fmtsd01.thoughtworks.com/centos/6.8/os/$2/
enabled=1
fastestmirror_enabled=0
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
mirrorlist=http://mirrorlist.centos.org/?release=$1&arch=$2&repo=os
EOF

/bin/cat << EOF > /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.22 (GNU/Linux)

mQENBFYM/AoBCADR9Q5cb+H5ndx+QkzNBQ88wcD+g112yvnHNlSiBMOnNEGHuKPJ
tujZ+eWXP3K6ucJckT91WxfQ2fxPr9jQ0xpZytcHcZdTfn3vKL9+OwR0npp+qmcz
rK8/EzVz/SWSgBQ5xT/HUvaeoVAbzBHSng0r2njnBAqABKAoTxgyRGKSCWduKD32
7PF2ZpqeDFFhd99Ykt6ar8SlV8ToqH6F7An0ILeejINVbHUxd6+wsbpcOwQ4mGAa
/CPXeqqLGj62ASBv36xQr34hlN/9zQMViaKkacl8zkuvwhuHf4b4VlGVCe6VILpQ
8ytKMV/lcg7YpMfRq4KVWBjCwkvk6zg6KxaHABEBAAG0aENlbnRPUyBTb2Z0d2Fy
ZUNvbGxlY3Rpb25zIFNJRyAoaHR0cHM6Ly93aWtpLmNlbnRvcy5vcmcvU3BlY2lh
bEludGVyZXN0R3JvdXAvU0NMbykgPHNlY3VyaXR5QGNlbnRvcy5vcmc+iQE5BBMB
AgAjBQJWDPwKAhsDBwsJCAcDAgEGFQgCCQoLBBYCAwECHgECF4AACgkQTrhOcfLu
nVXNewgAg7RVclomjTY4w80XiztUuUaFlCHyR76KazdaGfx/8XckWH2GdQtwii+3
Tg7+PT2H0Xyuj1aod+jVTPXTPVUr+rEHAjuNDY+xyAJrNljoOHiz111zs9pk7PLX
CPwKWQLnmrcKIi8v/51L79FFsUMvhClTBdLUQ51lkCwbcXQi+bOhPvZTVbRhjoB/
a9z0d8t65X16zEzE7fBhnVoj4xye/MPMbTH41Mv+FWVciBTuAepOLmgJ9oxODliv
rgZa28IEWkvHQ8m9GLJ0y9mI6olh0cGFybnd5y4Ss1cMttlRGR4qthLhN2gHZpO9
2y4WgkeVXCj1BK1fzVrDMLPbuNNCZQ==
=UtPD
-----END PGP PUBLIC KEY BLOCK-----
EOF

/bin/cat << EOF > /etc/yum.repos.d/centos-release-scl-rh.repo
[centos-release-scl-rh]
name=Yum Repository
baseurl=http://mirror.centos.org/centos/$1/sclo/$2/rh/
enabled=1
fastestmirror_enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
EOF

yum makecache
yum install -y epel-release centos-release-scl
yum install -y unzip git rh-ruby22-rubygem-rake
