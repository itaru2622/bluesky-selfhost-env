
# definitions, dirs for top level and repo dirs
wDir :=${PWD}
rDir :=${wDir}/repos

# dirs of repo
nrepo    :=atproto indigo social-app pds did-method-plc  
repoDirs :=$(addprefix ${rDir}/, ${nrepo})
# repoDirs: ${rDir}/atproto, ... etc.


# variables for github (gh=https://github.com/ | git@github.com:)
gh   =$(addsuffix /, https://github.com)
gh   =$(addsuffix :, git@github.com)

LOG_LEVEL_DEFAULT  ?=debug

#         domain name of self hosting(NEED to care TLD, ie: NG=>.local)
DOMAIN  ?=mybluesky.local.com

# EMAIL4CERTS:  email address to lets encript or "internal"( caddy builtin CA)
EMAIL4CERTS   ?=internal

# docker composer related
f      ?=docker-compose-starter.yaml
Sdep  ?=caddy test-caddy test-ws database redis opensearch
Sbsky ?=plc pds bgs bsky bsky-daemon bsky-indexer bsky-ingester bsky-cdn social-app search mod mod-daemon

# password for bluesky components
passfile=config/secrets-passwords.env

# get source from github
cloneAll:   ${repoDirs}
${rDir}/atproto:
	git clone ${gh}bluesky-social/atproto.git $@
${rDir}/indigo:
	git clone ${gh}bluesky-social/indigo.git $@
${rDir}/social-app:
	git clone ${gh}bluesky-social/social-app.git $@
${rDir}/pds:
	git clone ${gh}bluesky-social/pds.git $@
${rDir}/did-method-plc:
	git clone ${gh}did-method-plc/did-method-plc $@
delRepoDirAll:
	rm -rf ${rDir}/*
# make clone_one d=social-app
clone_one:  ${rDir}/${d}


# generation for test env
${passfile}:
	./config/pass-gen/gen.sh > $@
genPass: ${passfile}
certs/ca-certificates.crt:
	cp -p /etc/ssl/certs/ca-certificates.crt $@

include ops/git.mk
include ops/docker.mk
include ops/patch.mk

echo:
	@echo "nrepo:    ${nrepo}"
	@echo "repoDirs: ${repoDirs}"
	@echo "gh:       ${gh}"
	@echo "f:        ${f}"

# make exec under=./repos/* cmd='git status|cat`
# make exec under=./repos/* cmd='git checkout main'
exec: ${under}
	for d in ${under}; do \
		echo "### exec cmd @ $${d}" ;\
		(cd $${d};   ${cmd} ); \
	done;
