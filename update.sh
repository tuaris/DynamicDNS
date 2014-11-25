#!/bin/csh

# This script uses the NSLOOKUP utility on FreeBSD 
# to do dynamic DNS updates using the public IP address.
# This uses the RFC 2136 Dynamic DNS updates standard.
# On FreeBSD 10+ you need to install NSUPDATE using ports.

# Setup
# --------------------------------------------------------------------------------

# Basic Settings
set HOSTNAME="foo.bar.domain.tld"
set TTL=30
set SECRET="<enter base64 encoded hmac-md5 secret here>"

# Change the temp file if desired
set TMP_FILE=/tmp/nsupdate

# Advanced configuration
set FETCH=`which fetch`
set NSUPDATE=`which nsupdate`
set DIG=`which dig`

# Thats all you need to change
# --------------------------------------------------------------------------------

set ZONE=`echo $HOSTNAME |awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//' `
set HOST=`echo $HOSTNAME |awk -F. '{ print $1 }'`
set CURRENT_IP=`$FETCH -q -o - http://showthisip.com/\?simple`
set SAVED_IP=`$DIG A $HOSTNAME +noedns +short @${ZONE}`

echo "Current IP is $CURRENT_IP"

# Check if update is needed
if ( "$SAVED_IP" == "" ) then
	echo "Hostname does not currently exist"
	set NEEDSUPDATE=1
else
	echo "Hostname currently set to $SAVED_IP"
	if ( "$SAVED_IP" == "$CURRENT_IP" ) then
		set NEEDSUPDATE=0
	else
		set NEEDSUPDATE=1
	endif
endif

if ( $NEEDSUPDATE == 1 ) then
	echo "Setting hostname to $CURRENT_IP"
	
	# Building Script
	echo "server $ZONE" > $TMP_FILE
	echo "debug yes" >> $TMP_FILE
	echo "zone ${ZONE}." >> $TMP_FILE
	echo "update delete $HOSTNAME" >> $TMP_FILE
	echo "update add $HOSTNAME $TTL A $CURRENT_IP" >> $TMP_FILE
	echo "send" >> $TMP_FILE
	
	# Printing it oun
	echo
	echo "===========START=============="
	cat $TMP_FILE
	echo "============END==============="

	# Performig update
	$NSUPDATE -y ${ZONE}.:${SECRET} -v $TMP_FILE
else
	echo "DNS Update not needed"
endif


