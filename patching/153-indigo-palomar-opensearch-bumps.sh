#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/indigo
v_=2

echo "applying patch: under ${d_}"

pushd ${d_}
sed -i -E "s#^FROM opensearchproject/([a-z].*):2.*#FROM opensearchproject/\1:${v_}#" cmd/palomar/Dockerfile.opensearch*
popd
