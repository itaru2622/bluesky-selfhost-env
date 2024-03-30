#!/usr/bin/bash

# cf. https://syui.ai/blog/post/2024/01/08/bluesky/

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"

pushd ${rDir}/social-app/src

# starts patch, based on syui.ai >>>>>>>>>>

if [ -n "`grep -R bsky.social .`" ];then
	for f in `grep -R bsky.social . |cut -d : -f 1`; do sed -i "s/bsky.social/${DOMAIN}/g" $f; done
	echo "bsky.social => ${DOMAIN}"
fi

if [ -n "`grep -R "isSandbox: false" .`" ];then
	for f in `grep -R "isSandbox: false" . |cut -d : -f 1`; do sed -i "s/isSandbox: false/isSandbox: true/g" $f; done
	echo "isSandbox: false => true"
fi

if [ -n "`grep -R SANDBOX .`" ];then
	for f in `grep -R SANDBOX . |cut -d : -f 1`; do sed -i "s/SANDBOX/${DOMAIN}/g" $f; done
	echo "SANDBOX => ${DOMAIN}"
fi

f=./view/com/modals/ServerInput.tsx
if [ -f $f ] && [ -n "`grep -R Bluesky.Social $f`" ];then
	sed -i "s/Bluesky.Social/${DOMAIN}/g" $f
	echo "Bluesky.Social => ${DOMAIN}  for $f"
fi


f=./state/queries/preferences/moderation.ts
if [ -f $f ] && [ -n "`grep -R 'Bluesky Social' $f`" ];then
	sed -i "s/Bluesky Social/${DOMAIN}/g" $f
	echo "Bluesky Social => ${DOMAIN} for $f"
fi

f=./view/com/auth/create/Step1.tsx
if [ -f $f ] && [ -n "`grep -R 'Bluesky' $f`" ];then
	sed -i "s/Bluesky/${DOMAIN}/g" $f
	echo "Bluesky => ${DOMAIN}    for $f"
fi

f=./lib/strings/url-helpers.ts
if [ -f $f ] && [ -n "`grep -R 'Bluesky Social' $f`" ];then
	sed -i "s/Bluesky Social/${DOMAIN}/g" $f
	echo "Bluesky Social => ${DOMAIN}     for $f"
fi

popd

# ends patch, based on syui.ai <<<<<<<<<<
