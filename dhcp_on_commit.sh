#! /bin/sh

mac_address="$1"
url="http://127.0.0.1:5000/computer"
body="{\"mac_address\": \"$mac_address\"}"
curl -X POST -H "Content-Type: application/json" -d "$body" "$url"