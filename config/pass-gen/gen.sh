#!/usr/bin/env bash

#
# password generating rule (cf. https://github.com/bluesky-social/pds/blob/main/installer.sh )
#
# openssl based signing key generation
GEN_LONG_PASS="openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32"
# typescript based signing key generator
#GEN_LONG_PASS="docker run -it --rm -v ${wDir}/ops-progs:/app -w /app  itaru2622/typescript:18-bookworm  ts-node ./genSigningKey.ts | nkf -w -Lu -d"
GEN_SHORT_PASS="openssl rand --hex 16"
#GEN_SHORT_PASS="echo 'short-pass'"

####### generate secrets >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

ADMIN_PASSWORD=$(eval "${GEN_LONG_PASS}")
BGS_ADMIN_KEY=$(eval "${GEN_LONG_PASS}")
#IMG_URI_KEY=$(eval "${GEN_LONG_PASS}")
#IMG_URI_SALT=$(eval "${GEN_LONG_PASS}")
MODERATOR_PASSWORD=$(eval "${GEN_LONG_PASS}")
OZONE_ADMIN_PASSWORD=$(eval "${GEN_LONG_PASS}")
#OZONE_MODERATOR_PASSWORD=$(eval "${GEN_LONG_PASS}")
OZONE_SIGNING_KEY_HEX=$(eval "${GEN_LONG_PASS}")
#OZONE_TRIAGE_PASSWORD=$(eval "${GEN_LONG_PASS}")

POSTGRES_USER=pg
POSTGRES_PASSWORD=password
PDS_ADMIN_PASSWORD=$(eval "${GEN_SHORT_PASS}")
PDS_JWT_SECRET=$(eval "${GEN_SHORT_PASS}")

PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=$(eval "${GEN_LONG_PASS}")
PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX=$(eval "${GEN_LONG_PASS}")
SERVICE_SIGNING_KEY=$(eval "${GEN_LONG_PASS}")
TRIAGE_PASSWORD=$(eval "${GEN_LONG_PASS}")

FEEDGEN_PUBLISHER_PASSWORD=$(eval "${GEN_SHORT_PASS}")
BSKY_SERVICE_SIGNING_KEY=$(eval "${GEN_LONG_PASS}")
BSKY_ADMIN_PASSWORD=$(eval "${GEN_SHORT_PASS}")
PASS=$(eval "${GEN_LONG_PASS}")

# the same as atproto/packages/dev-env/src/const.ts
# use short password
ADMIN_PASSWORD=admin-pass
#MODERATOR_PASSWORD=mod-pass
#TRIAGE_PASSWORD=triage-pass
PDS_JWT_SECRET=jwt-secret
EXAMPLE_LABELER=did:example:labeler

# the same passwords for all admins, atproto/packages/dev-env/src/*.ts
OZONE_ADMIN_PASSWORD=${ADMIN_PASSWORD}
PDS_ADMIN_PASSWORD=${ADMIN_PASSWORD}
BSKY_ADMIN_PASSWORDS=${ADMIN_PASSWORD}
#OZONE_TRIAGE_PASSWORD=${TRIAGE_PASSWORD}
#OZONE_MODERATOR_PASSWORD=${MODERATOR_PASSWORD}
BSKY_LABELS_FROM_ISSUER_DIDS=${EXAMPLE_LABELER}

########### dump secrets   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}"
echo "BGS_ADMIN_KEY=${BGS_ADMIN_KEY}"
#echo "IMG_URI_KEY=${IMG_URI_KEY}"
#echo "IMG_URI_SALT=${IMG_URI_SALT}"
echo "MODERATOR_PASSWORD=${MODERATOR_PASSWORD}"
echo "OZONE_ADMIN_PASSWORD=${OZONE_ADMIN_PASSWORD}"
#echo "OZONE_MODERATOR_PASSWORD=${OZONE_MODERATOR_PASSWORD}"
echo "OZONE_SIGNING_KEY_HEX=${OZONE_SIGNING_KEY_HEX}"
#echo "OZONE_TRIAGE_PASSWORD=${OZONE_TRIAGE_PASSWORD}"
echo "PDS_ADMIN_PASSWORD=${PDS_ADMIN_PASSWORD}"
echo "PDS_JWT_SECRET=${PDS_JWT_SECRET}"
echo "PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=${PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX}"
echo "PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX=${PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX}"
echo "POSTGRES_USER=${POSTGRES_USER}"
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
echo "SERVICE_SIGNING_KEY=${SERVICE_SIGNING_KEY}"
echo "TRIAGE_PASSWORD=${TRIAGE_PASSWORD}"

echo "FEEDGEN_PUBLISHER_PASSWORD=${FEEDGEN_PUBLISHER_PASSWORD}"
echo "BSKY_SERVICE_SIGNING_KEY=${BSKY_SERVICE_SIGNING_KEY}"
echo "BSKY_ADMIN_PASSWORDS=${BSKY_ADMIN_PASSWORDS}"
echo "BSKY_LABELS_FROM_ISSUER_DIDS=${BSKY_LABELS_FROM_ISSUER_DIDS}"
echo "EXAMPLE_LABELER=${EXAMPLE_LABELER}"

echo "PASS=${PASS}"
