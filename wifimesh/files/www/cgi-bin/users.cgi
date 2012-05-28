#!/bin/sh
# Copyright © 2011-2012 WiFi Mesh: New Zealand Ltd.
# All rights reserved.

cat <<EOF_01
Content-Type: text/html
Pragma: no-cache

lol
EOF_01

get_parameter() {
	echo "$query" | tr '&' '\n' | grep "^$1=" | head -1 | sed "s/.*=//" 
}

if [ "$REQUEST_METHOD" = POST ]; then
	query=$(head --bytes="$CONTENT_LENGTH")
else
	query="$QUERY_STRING"
fi

if [ $(get_parameter action) = "block" ]; then
	cat <<EOF_97
		echo "1"
		echo $(get_parameter mac)
	EOF_99
else if [ $(get_parameter action) = "unblock" ]; then
	cat <<EOF_97
		echo "2"
		echo $(get_parameter mac)
	EOF_99
else
	cat <<EOF_98
		echo "no match found"
	EOF_98
fi