#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/ozone

pushd ${d_}

# Nodejs v20 is already EOL so bumps to later version.
sed -i 's/node:20.11-alpine3.18/node:24-alpine/g' Dockerfile

# The below line(require package.json) raises errors when bumps nodejs>20. so delete temporally. env.version is the optional parameter in logic.
sed -i "\#const pkg = require('@atproto/ozone/package.json')#d" service/index.js
sed -i "\#env.version ??= pkg.version#d"                        service/index.js

popd
