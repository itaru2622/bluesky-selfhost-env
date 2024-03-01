# definitions  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# domain name of self-hosting bluesky (NEED to care TLD, ie: NG=>mybluesky.local)
DOMAIN ?=mybluesky.local.com

# get commit hash by datetime to checkout new branch for work with
asof           ?=$(shell date '+%Y-%m-%dT%H%M%S')
getHashByDate  :=git log --pretty='format:%h' -1 --before=${asof}

# folders, top level and repos
wDir :=${PWD}
rDir :=${wDir}/repos

# folders of repositories; get repoDirs=${rDir}/atproto, ... etc.
_nrepo   :=atproto indigo social-app did-method-plc pds
repoDirs :=$(addprefix ${rDir}/, ${_nrepo})

# prefix of github (https://github.com/ | git@github.com:)
gh  ?=$(addsuffix /, https://github.com)
#gh ?=$(addsuffix :, git@github.com)


# default log level.
LOG_LEVEL_DEFAULT  ?=debug

# email address for lets encript or "internal"(to use caddy builtin ACME)
EMAIL4CERTS   ?=internal

# for docker ops
f     ?=docker-compose-starter.yaml
# services for two-step starting.
Sdep  ?=caddy caddy-sidecar database redis opensearch test-ws
Sbsky ?=plc pds bgs bsky bsky-daemon bsky-indexer bsky-ingester bsky-cdn social-app search mod mod-daemon

# passwords file
passfile=config/secrets-passwords.env

# target(operations) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

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

# include other ops.
include ops/git.mk
include ops/docker.mk
include ops/patch.mk

# execute the command under folders (one or multiple).
# HINT: make exec under=./repos/* cmd='git status|cat` => execute git status for all repos.
# HINT: make exec under=./repos/* cmd='git checkout main' => checkout to main for all repos.
exec: ${under}
	for d in ${under}; do \
		echo "### exec cmd @ $${d}" ;\
		(cd $${d};   ${cmd} ); \
	done;

# to check Makefile configuration
# HINT: make echo
echo:
	@echo "########## >>>>>>>>>>>>>>"
	@echo "DOMAIN:   ${DOMAIN}"
	@echo "asof:     ${asof}"
	@echo "_nrepo:   ${_nrepo}"
	@echo "repoDirs: ${repoDirs}"
	@echo "gh:       ${gh}"
	@echo "f:        ${f}"
	@echo "########## <<<<<<<<<<<<<<"
