#!/bin/sh
url="http://10.0.0.1:5000/computer/"

send() {
  mac_address=$(ip a s | grep ether | xargs | cut -d ' ' -f2)
  url_with_mac="${url}${mac_address}"

  body="$1"
  curl -s -X PATCH -H "Content-Type: application/json" -d "$body" "${url_with_mac}"
}

# Usage:
#  report '{"step":1}'       -> send full JSON
#  report 1                  -> send {"step":1}
if [ -z "$1" ]; then
  echo "Usage: report <json-or-step>"
  exit 1
fi

# If the argument is not a JSON, it's a step. Convert it to JSON.
case "$1" in
  \{*) body="$1" ;;
  *) body="{\"step\":$1}" ;;
esac

send "$body"