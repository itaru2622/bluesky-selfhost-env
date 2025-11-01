#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/ozone
p_=${pDir}/120-ozone-runtimeEnvVars.diff
p2_=${pDir}/120-ozone-runtimeEnvVars-firstaid-next15.diff

pushd ${d_}

echo "applying patch: under ${d_} for ${p_}"
patch -p1 <  ${p_}
patch -p1 <  ${p2_}

popd
