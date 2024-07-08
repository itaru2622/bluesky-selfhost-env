#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/ozone
p_=${pDir}/129-ozone-dev.diff

pushd ${d_}

echo "applying patch: under ${d_} for ${p_}"
patch -p1 <  ${p_}

popd
