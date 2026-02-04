#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/indigo
p_=${pDir}/152-indigo-relay-allows-privateIP-scenario.diff

echo "applying patch: under ${d_} for ${p_}"

pushd ${d_}
patch -p1 < ${p_}
popd
