#!/usr/bin/bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"

pushd ${rDir}/feed-generator

# starts patch >>>>>>>>>>

# starts: easy config by env vars >>>

f=./scripts/publishFeedGen.ts
if [ -f $f ] && [ -n "`grep -R 'const handle =' $f`" ];then
	sed -i "s#const handle = ''#const handle = process.env.FEEDGEN_PUBLISHER_HANDLE ?? ''#g" $f
	echo "handle  <empty> => process.env.FEEDGEN_PUBLISHER_HANDLE for $f"
fi
if [ -f $f ] && [ -n "`grep -R 'const password =' $f`" ];then
	sed -i "s#const password = ''#const password = process.env.FEEDGEN_PUBLISHER_PASSWORD ?? ''#g" $f
	echo "password  <empty> => process.env.FEEDGEN_PUBLISHER_PASSWORD  for $f"
fi
if [ -f $f ] && [ -n "`grep -R 'const recordName =' $f`" ];then
	sed -i "s#const recordName = ''#const recordName = process.env.FEEDGEN_RECORD_NAME ?? ''#g" $f
	echo "recordName  <empty> => process.env.FEEDGEN_RECORD_NAME  for $f"
fi
if [ -f $f ] && [ -n "`grep -R 'const displayName =' $f`" ];then
	sed -i "s#const displayName = ''#const displayName = process.env.FEEDGEN_DISPLAY_NAME ?? ''#g" $f
	echo "displayName  <empty> => process.env.FEEDGEN_DISPLAY_NAME  for $f"
fi
if [ -f $f ] && [ -n "`grep -R 'const description =' $f`" ];then
	sed -i "s#const description = ''#const description = process.env.FEEDGEN_DESCRIPTION ?? ''#g" $f
	echo "description  <empty> => process.env.FEEDGEN_DESCRIPTION  for $f"
fi

# ends: easy config by env vars <<<


popd

# ends patch <<<<<<<<<<
