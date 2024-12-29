#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/feed-generator
p_=${pDir}/110-feed-generator-easyconf-envvars.diff

echo "applying patch: under ${d_} for ${p_}"

pushd ${d_}
patch -p1 < ${p_}

f=./src/server.ts
if [ -f $f ] && [ -n "`grep -R 'https://plc.directory' $f`" ];then
       sed -i "s#plcUrl: 'https://plc.directory'#plcUrl: process.env.FEEDGEN_PLC_URL ?? 'https://plc.directory'#g" $f
       echo "plcUrl: hardcoded   => process.env.FEEDGEN_PLC_URL ?? hardcoded  for $f"
fi
popd

