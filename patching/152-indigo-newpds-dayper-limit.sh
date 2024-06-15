#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/indigo
p_=${pDir}/152-indigo-newpds-dayper-limit.diff

echo "applying patch: under ${d_} for ${p_}"

pushd ${d_}
git apply ${p_}
popd
