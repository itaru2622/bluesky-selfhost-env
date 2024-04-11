#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"

pushd ${rDir}/atproto


f=./packages/pds/src/handle/index.ts
if [ -f $f ] && [ -n "`grep 'handle.length > 30' $f`" ];then
	sed -i "s#handle.length > 30#front.length > 18#" $f
	echo "relax restriction on pds handle.length : 30 => first segment : 18    for $f"
fi

popd
