#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"

d_=${rDir}/atproto

echo "applying patch: under ${d_} for services/*/Dockerfile"

pushd ${d_}

sed -i '/# Move files into the image and install/a COPY ./[a-zA-Z]*.* ./' services/*/Dockerfile

popd
