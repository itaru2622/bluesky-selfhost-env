#!/usr/bin/bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"

pushd ${rDir}/feed-generator

# starts patch >>>>>>>>>>

# starts: regarding self-hosting consideraction. >>>>
d=.
if [ -n "`grep -R '://bsky.social' ${d}`" ];then
	for f in `grep -R 'bsky.social' ${d} |cut -d : -f 1`; do sed -i "s/bsky.social/${DOMAIN}/g" $f; done
	echo "bsky.social => ${DOMAIN}"
fi

f=./src/server.ts
if [ -f $f ] && [ -n "`grep -R 'plc.directory' $f`" ];then
	sed -i "s#plc.directory#plc.${DOMAIN}#g" $f
	echo "plc.directory => plc.${DOMAIN}  for $f"
fi

# ends: regarding self-hosting consideraction. <<<<

popd

# ends patch <<<<<<<<<<
