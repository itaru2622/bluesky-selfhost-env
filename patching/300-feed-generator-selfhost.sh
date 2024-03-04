#!/usr/bin/bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"

pushd ${rDir}/feed-generator

# starts patch >>>>>>>>>>

d=scripts
if [ -n "`grep -R bsky.social ${d}`" ];then
	for f in `grep -R bsky.social ${d} |cut -d : -f 1`; do sed -i "s/bsky.social/${DOMAIN}/g" $f; done
	echo "bsky.social => ${DOMAIN}"
fi

popd

# ends patch <<<<<<<<<<
