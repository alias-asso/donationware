#! /bin/bash

# The CURL command is run in the background to avoid blocking the DHCP server, which would cause timeouts for the client.

{
    curl -s -X POST "http://localhost:5000/computer/$1" > /dev/null 2>&1
} &

exit 0