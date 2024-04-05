#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/indigo
p_=${pDir}/151-indigo-toolsAsDocker.diff

echo "applying patch: under ${d_} for ${p_}"

pushd ${d_}
git apply ${p_}
popd
