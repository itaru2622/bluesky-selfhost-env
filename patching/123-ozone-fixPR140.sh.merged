#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/ozone

pushd ${d_}

sed -i 's#"next": "14.0.1"#"next": "14.2.5"#' service/package.json

popd
