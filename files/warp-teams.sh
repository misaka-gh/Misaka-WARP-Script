#!/bin/bash

URL=${URL:-'https://gist.githubusercontent.com/fscarmen/56aaf02d743551737c9973b8be7a3496/raw/61bf63e68e4e91152545679b8f11c72cac215128/2021.12.21'}
TEAMS=$(curl -sSL "$URL" | sed "s/\"/\&quot;/g")
PRIVATEKEY=$(expr "$TEAMS" : '.*private_key&quot;>\([^<]*\).*')
PUBLICKEY=$(expr "$TEAMS" : '.*public_key&quot;:&quot;\([^&]*\).*')
ADDRESS4=$(expr "$TEAMS" : '.*v4&quot;:&quot;\(172[^&]*\).*')
ADDRESS6=$(expr "$TEAMS" : '.*v6&quot;:&quot;\([^[&]*\).*')

echo $TEAMS