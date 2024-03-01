#!/usr/bin/bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/indigo
p_=${pDir}/150-indigo-DockerbuildBehindProxy.diff

echo "applying patch: under ${d_} for ${p_}"

pushd ${d_}
patch -p1 < ${p_}
popd
