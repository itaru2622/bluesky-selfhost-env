#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"

pushd ${rDir}/social-app/src

# starts patch, more           >>>>>>>>>>

# for no-auth API call, cf. https://github.com/bluesky-social/bsky-docs/issues/63
f=./state/queries/index.ts
if [ -f $f ] && [ -n "`grep -R public.api.bsky.app $f`" ];then
	sed -i "s/public.api.bsky.app/public.api.${DOMAIN}/g" $f
	echo "public.api.bsky.app => public.api.${DOMAIN}  for $f"
fi

popd

# starts patch, more           <<<<<<<<<<
