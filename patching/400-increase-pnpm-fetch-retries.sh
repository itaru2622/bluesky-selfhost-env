#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"

echo "applying patch: under ${rDir} for */Dockerfile to increase pnpm fetch-retries"

# pnpm often failes by network matters...
find ${rDir} -type f | grep Dockerfile$ | xargs sed -i 's/pnpm install /pnpm install --fetch-retries=100 /'
