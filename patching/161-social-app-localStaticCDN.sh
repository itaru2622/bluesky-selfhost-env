#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/social-app
p1_=${pDir}/161-social-app-localStaticCDN-rewrite-envs-at-boot.diff
p2_=${pDir}/161-social-app-localStaticCDN-dockerfile.diff
p3_=${pDir}/161-social-app-localStaticCDN-golang.diff

pushd ${d_}

echo "applying patch: under ${d_} for ${p1_}"
patch -p1 <  ${p1_}

echo "applying patch: under ${d_} for ${p2_}"
patch -p1 <  ${p2_}

echo "applying patch: under ${d_} for ${p3_}"
patch -p1 <  ${p3_}

popd
