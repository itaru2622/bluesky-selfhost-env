#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/social-app
p_=${pDir}/162-social-app-bskyweb-pr12020.diff

pushd ${d_}

echo "applying patch: under ${d_} for ${p_}"
patch -p1 <  ${p_}

popd
