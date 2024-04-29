#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/ozone
patches="${pDir}/120-ozone-runtimeEnvVars-trial-envprovider.diff  ${pDir}/120-ozone-runtimeEnvVars-trial-rest.diff  ${pDir}/120-ozone-runtimeEnvVars-trial-others.diff"

pushd ${d_}

for p_ in ${patches}
do
  echo "applying patch: under ${d_} for ${p_}"
  git apply ${p_}
done

popd
