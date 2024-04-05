#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/atproto
p1_=${pDir}/010-atproto-devenv-debug.diff
p2_=${pDir}/010-atproto-devenv-debug-others.diff

echo "applying patch: under ${d_} for ${p1_} ${p2_}"

pushd ${d_}
git apply ${p1_}
git apply ${p2_}
popd
