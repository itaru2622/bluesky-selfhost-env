#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/ozone
p_=${pDir}/120-ozone-runtimeEnvVars.diff

pushd ${d_}

echo "applying patch: under ${d_} for ${p_}"
git apply ${p_}

popd
