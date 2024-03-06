##########################################################################################
# starts: definitions, need to care in especial.

# domain of self-hosting bluesky (care TLD, otherwise get failure, ie: NG=>mybluesky.local)
DOMAIN ?=mybluesky.local.com

# email address to get public-signed certs ("internal" for self-signed certs by caddy)
EMAIL4CERTS ?=internal

# mail account, which PDS wants.
PDS_EMAIL_SMTP_URL ?= smtps://change:me@smtp.gmail.com

# feed-generator account in bluesky to send posts
FEEDGEN_PUBLISHER_HANDLE ?=feedgen.${DOMAIN}
FEEDGEN_EMAIL ?=feedgen@example.com


# datetime for resolving git commit hash to work with
asof ?=2024-01-06

# ends: definitions, need to care in especial.
##########################################################################################
##########################################################################################
# other definitions

# alternative of 'asof' to resolve by current daytime.
#asof          ?=$(shell date '+%Y-%m-%dT%H%M%S')
getHashByDate  :=git log --pretty='format:%h' -1 --before=${asof}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# paths for folders and files

# top level folder
wDir :=${PWD}

# data folder to persist container's into filesystem
dDir ?=${wDir}/data

# account folder (for feed-generator and others, created with bluesky API during ops).
aDir ?=${dDir}/accounts

# top level repos folder
rDir ?=${wDir}/repos

# file path to store generated passwords with openssl, during ops.
passfile ?=${wDir}/config/secrets-passwords.env

# docker-compose file
f ?=${wDir}/docker-compose-starter.yaml

# folders of repos
_nrepo   :=atproto indigo social-app feed-generator did-method-plc pds
repoDirs :=$(addprefix ${rDir}/, ${_nrepo})

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# other parameters

# prefix of github (https://github.com/ | git@github.com:)
gh  ?=$(addsuffix /, https://github.com)
#gh ?=$(addsuffix :, git@github.com)

# default log level.
LOG_LEVEL_DEFAULT ?=debug

# services for N-step starting, with single docker-compose file.
Sdep  ?=caddy caddy-sidecar database redis opensearch test-wss test-ws pgadmin
Sbsky ?=plc pds bgs bsky bsky-daemon bsky-indexer bsky-ingester bsky-cdn social-app search mod mod-daemon
Sfeed ?=feed-generator


# load passfile content as Makefile variables if exists
ifeq ($(shell test -e ${passfile} && echo -n exists),exists)
   include ${passfile}
endif

# load URL and DIDs from file regarding self-hosting bluesky (under testing)
#include ops/env-url-did.mk

##########################################################################################
##########################################################################################
# starts:  targets for  operations


# get all sources from github
cloneAll:   ${repoDirs}

# get source in indivisual
# HINT: make clone_one social-app
clone_one:  ${rDir}/${d}

${rDir}/atproto:
	git clone ${gh}bluesky-social/atproto.git $@
${rDir}/indigo:
	git clone ${gh}bluesky-social/indigo.git $@
${rDir}/social-app:
	git clone ${gh}bluesky-social/social-app.git $@
${rDir}/feed-generator:
	git clone ${gh}bluesky-social/feed-generator.git $@
${rDir}/pds:
	git clone ${gh}bluesky-social/pds.git $@
${rDir}/did-method-plc:
	git clone ${gh}did-method-plc/did-method-plc $@
# delete all repos.
delRepoDirAll:
	rm -rf ${rDir}/*

# generate passwords for test env
genPass: ${passfile}
${passfile}:
	./config/pass-gen/gen.sh > $@
	cat $@
	@echo "passwords generated and stored in $@"

# copy CA certificates locally to use all containers(for self-signed certificates.)
certs/ca-certificates.crt:
	cp -p /etc/ssl/certs/ca-certificates.crt $@

setupdir:
	mkdir -p ${dDir}/pds ${dDir}/appview/cache ${dDir}/image/static ${dDir}/image/tmp ${dDir}/feed-generator ${aDir}

################################
# include other ops.
################################
include ops/git.mk
include ops/docker.mk
include ops/patch.mk
include ops/api-bsky.mk

# execute the command under folders (one or multiple).
# HINT: make exec under=./repos/* cmd='git status|cat` => execute git status for all repos.
# HINT: make exec under=./repos/* cmd='git checkout main' => checkout to main for all repos.
exec: ${under}
	for d in ${under}; do \
		echo "### exec cmd @ $${d}" ;\
		(cd $${d};   ${cmd} ); \
	done;

# to show ops configurations
# HINT: make echo
echo:
	@echo ""
	@echo "########## >>>>>>>>>>>>>>"
	@echo "DOMAIN:   ${DOMAIN}"
	@echo "asof:     ${asof}"
	@echo ""
	@echo "PDS_EMAIL_SMTP_URL: ${PDS_EMAIL_SMTP_URL}"
	@echo "FEEDGEN_EMAIL: ${FEEDGEN_EMAIL}"
	@echo "FEEDGEN_PUBLISHER_HANDLE: ${FEEDGEN_PUBLISHER_HANDLE}"
	@echo "FEEDGEN_PUBLISHER_PASSWORD: ${FEEDGEN_PUBLISHER_PASSWORD}"
	@echo ""
	@echo "wDir:     ${wDir}"
	@echo "passfile: ${passfile}"
	@echo "dDir:     ${dDir}"
	@echo "aDir:     ${aDir}"
	@echo "rDir:     ${rDir}"
	@echo "_nrepo:   ${_nrepo}"
	@echo "repoDirs: ${repoDirs}"
	@echo "f:        ${f}"
	@echo "gh:       ${gh}"
	@echo ""
	@echo "OZONE_PUBLIC_URL=${OZONE_PUBLIC_URL}"
	@echo "LOG_LEVEL_DEFAULT=${LOG_LEVEL_DEFAULT}"
	@echo "########## <<<<<<<<<<<<<<"
