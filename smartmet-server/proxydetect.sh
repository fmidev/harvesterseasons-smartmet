#!/bin/bash -x

tmpf=`mktemp`
proxyfile=/tmp/proxysetup

# Setup proxy environment variables, if needed and setup yum proxy
test -r $proxyfile || (
    # Try with current proxy settings
    timeout 5 curl -s www.google.com >$tmpf
    if [ "$?" != "0" ] ; then
	https_proxy=http://wwwcache.fmi.fi:8080
	http_proxy=http://wwwcache.fmi.fi:8080
	ftp_proxy=http://wwwcache.fmi.fi:8080
	export https_proxy http_proxy ftp_proxy
	timeout 5 curl -s www.google.com >/dev/null || exit 2
    fi
    rm -f $tmpf
    
    if [ "$http_proxy" ] ; then
	cat >$proxyfile <<EOF
https_proxy=$https_proxy
http_proxy=$http_proxy
ftp_proxy=$ftp_proxy
export https_proxy http_proxy ftp_proxy
EOF
    else
	# Apparently, no proxies are needed. Create empty file
	touch $proxyfile
    fi
)

# Read already generated proxy settings
test ! -r $proxyfile || . $proxyfile

# Fix yum.conf if needed
test -z "$http_proxy" || test ! -w /etc/yum.conf || \
    grep -q "^proxy=" /etc/yum.conf || (
	echo proxy=$http_proxy >> /etc/yum.conf
    )

