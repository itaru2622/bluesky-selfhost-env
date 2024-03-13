#!/usr/bin/bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/atproto
p1_=${pDir}/010-atproto-devenv-debug.diff
p2_=${pDir}/010-atproto-devenv-debug-others.diff

echo "applying patch: under ${d_} for ${p1_} ${p2_}"

pushd ${d_}
patch -p1 < ${p1_}
patch -p1 < ${p2_}
popd
