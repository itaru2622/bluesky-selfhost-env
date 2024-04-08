#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"

pushd ${rDir}/atproto


f=./packages/pds/src/handle/index.ts
if [ -f $f ] && [ -n "`grep 'handle.length > 30' $f`" ];then
	sed -i "s#handle.length > 30#handle.length > 255#" $f
	echo "relax restriction on pds handle.length : 30 => 255    for $f"
fi

popd
