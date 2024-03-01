#!/bin/bash

# cf. https://github.com/flaccid/docker-gorilla-websocket-chat/blob/master/docker-entrypoint.sh
if [ "${ENABLE_WSS}" = 'true' ] && [ -e ./home.html ]; then
  echo 'using wss enabled'
  sed -i 's#ws://#wss://#g' ./home.html
  grep :// ./home.html
fi

if [ -z "${SCRIPT}" ] ; then
   SCRIPT=*.go
fi

go run ${SCRIPT}
