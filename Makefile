##########################################################################################
# starts: definitions, need to care in especial.

# domain of self-hosting bluesky (care TLD, otherwise get failure, ie: NG=>mysky.local)
DOMAIN ?=mysky.local.com

# email address to get public-signed certs ("internal" for self-signed certs by caddy)
EMAIL4CERTS ?=internal

# mail account, which PDS wants.
PDS_EMAIL_SMTP_URL ?= smtps://change:me@smtp.gmail.com

# feed-generator account in bluesky to send posts ( last part may need to be equal to PDS_HOSTNAME)
FEEDGEN_PUBLISHER_HANDLE ?=feedgen.pds.${DOMAIN}
FEEDGEN_EMAIL ?=feedgen@example.com

# ozone account in bluesky for moderation
OZONE_ADMIN_HANDLE ?=ozone-admin.pds.${DOMAIN}
OZONE_ADMIN_EMAIL  ?=ozone-admin@example.com

# datetime to distinguish docker images and sources (date in %Y-%m-%d or 'latest' in docker image naming manner)
asof ?=latest
#asof ?=2024-04-03
#asof ?=$(shell date +'%Y-%m-%d')


ifeq ($(EMAIL4CERTS), internal)
GOINSECURE :=${DOMAIN},*.${DOMAIN}
NODE_TLS_REJECT_UNAUTHORIZED :=0
else
GOINSECURE ?=
NODE_TLS_REJECT_UNAUTHORIZED ?=1
endif

# ends: definitions, need to care in especial.
##########################################################################################
##########################################################################################
# other definitions

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# paths for folders and files

# top level folder
wDir ?=${PWD}

# data folder to persist container's into filesystem
dDir ?=${wDir}/data

# account folder (for feed-generator and others, created with bluesky API during ops).
aDir ?=${dDir}/accounts

# top level repos folder
rDir ?=${wDir}/repos

# file path to store generated passwords with openssl, during ops.
passfile ?=${wDir}/config/secrets-passwords.env

# docker-compose file
f ?=${wDir}/docker-compose.yaml
#f ?=${wDir}/docker-compose-builder.yaml

# folders of repos
#_nrepo   :=atproto indigo social-app feed-generator did-method-plc pds ozone
_nrepo   ?=atproto indigo social-app ozone jetstream
repoDirs ?=$(addprefix ${rDir}/, ${_nrepo})

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# other parameters

# prefix of github (https://github.com/ | git@github.com:)
gh  ?=$(addsuffix /, https://github.com)
gh_git ?=$(addsuffix :, git@github.com)

fork_repo_prefix ?=
#fork_repo_prefix =${gh_git}itaru2622/bluesky-

# default log level.
LOG_LEVEL_DEFAULT ?=debug

# choose service/container to use from variations.
#  ozone: ozone-atproto ozone-standalone ozone-stanalone-dev
Container_ozone ?=ozone-standalone
Container_socialapp ?=social-app

# services for N-step starting, with single docker-compose file.
Sdep  ?=caddy caddy-sidecar database redis opensearch plc test-wss test-ws test-indigo pgadmin
#Sbsky ?=pds bgs bsky social-app palomar
Sbsky ?=pds bgs bsky ${Container_socialapp} palomar
Sfeed ?=feed-generator
Sozone ?=${Container_ozone}
ifeq ($(Container_ozone), ozone-atproto)
# ozone-atproto require ozone-atproto-daemon as side-car.
Sozone +=ozone-atproto-daemon
endif
Sjetstream ?=jetstream

# load passfile content as Makefile variables if exists
ifeq ($(shell test -e ${passfile} && echo -n exists),exists)
   include ${passfile}
endif

##########################################################################################
##########################################################################################
# starts:  targets for  operations


# get all sources from github
cloneAll:   ${repoDirs}

${rDir}/atproto:
	git clone ${gh}bluesky-social/atproto.git $@
ifneq ($(fork_repo_prefix),)
	-(cd $@; git remote add fork ${fork_repo_prefix}atproto.git; git remote update fork)
endif


${rDir}/indigo:
	git clone ${gh}bluesky-social/indigo.git $@
ifneq ($(fork_repo_prefix),)
	-(cd $@; git remote add fork ${fork_repo_prefix}indigo.git; git remote update fork)
endif


${rDir}/social-app:
	git clone ${gh}bluesky-social/social-app.git $@
ifneq ($(fork_repo_prefix),)
	-(cd $@; git remote add fork ${fork_repo_prefix}social-app.git; git remote update fork)
endif


${rDir}/feed-generator:
	git clone ${gh}bluesky-social/feed-generator.git $@
ifneq ($(fork_repo_prefix),)
	-(cd $@; git remote add fork ${fork_repo_prefix}feed-generator.git; git remote update fork)
endif


${rDir}/pds:
	git clone ${gh}bluesky-social/pds.git $@
ifneq ($(fork_repo_prefix),)
	-(cd $@; git remote add fork ${fork_repo_prefix}pds.git; git remote update fork)
endif


${rDir}/ozone:
	git clone ${gh}bluesky-social/ozone.git $@
ifneq ($(fork_repo_prefix),)
	-(cd $@; git remote add fork ${fork_repo_prefix}ozone.git; git remote update fork)
endif


${rDir}/did-method-plc:
	git clone ${gh}did-method-plc/did-method-plc.git $@
ifneq ($(fork_repo_prefix),)
	-(cd $@; git remote add fork ${fork_repo_prefix}did-method-plc.git; git remote update fork)
endif


${rDir}/jetstream:
	git clone ${gh}bluesky-social/jetstream.git $@
ifneq ($(fork_repo_prefix),)
	-(cd $@; git remote add fork ${fork_repo_prefix}jetstream.git; git remote update fork)
endif


# delete all repos.
delRepoDirAll:
	rm -rf ${rDir}/[a-z]*

# generate secrets for test env
genSecrets: ${passfile}
${passfile}: ./config/gen-secrets.sh
	wDir=${wDir} ./config/gen-secrets.sh > $@
	cat $@
	@echo "secrets generated and stored in $@"

setupdir:
	mkdir -p ${aDir}

################################
# include other ops.
################################
include ops/git.mk
include ops/certs.mk
include ops/docker.mk
include ops/patch.mk
include ops/api-bsky.mk

# execute the command under folders (one or multiple).
# HINT: make exec under=./repos/* cmd='git status                        | cat'  => show        git status for all repos.
# HINT: make exec under=./repos/* cmd='git branch --show-current         | cat'  => show        current branch for all repos
# HINT: make exec under=./repos/* cmd='git log --decorate=full | head -3 | cat ' => show        last commit log for all repos
# HINT: make exec under=./repos/* cmd='git remote update fork            | cat'  => update      remote named fork for all repos
# HINT: make exec under=./repos/* cmd='git checkout work                 | cat'  => checkout to work branch for all repos.
# HINT: make exec under=./repos/* cmd='git push fork --tags              | cat'  => push        tags to remote named fork
exec: ${under}
	for d in ${under}; do \
		r=`basename $${d})`; \
		echo "############ exec cmd @ $${d} $${r} ########################################" ;\
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
	@echo "EMAIL4CERTS: ${EMAIL4CERTS}"
	@echo "PDS_EMAIL_SMTP_URL: ${PDS_EMAIL_SMTP_URL}"
	@echo "FEEDGEN_EMAIL: ${FEEDGEN_EMAIL}"
	@echo "FEEDGEN_PUBLISHER_HANDLE: ${FEEDGEN_PUBLISHER_HANDLE}"
	@echo "FEEDGEN_PUBLISHER_PASSWORD: ${FEEDGEN_PUBLISHER_PASSWORD}"
	@echo "OZONE_ADMIN_EMAIL: ${OZONE_ADMIN_EMAIL}"
	@echo "OZONE_ADMIN_HANDLE: ${OZONE_ADMIN_HANDLE}"
	@echo "OZONE_ADMIN_PASSWORD: ${OZONE_ADMIN_PASSWORD}"
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
	@echo "fork_repo_prefix: ${fork_repo_prefix}"
	@echo ""
	@echo "LOG_LEVEL_DEFAULT=${LOG_LEVEL_DEFAULT}"
	@echo "Container_ozone:    ${Container_ozone}"
	@echo "Container_socialapp:${Container_socialapp}"
	@echo "########## <<<<<<<<<<<<<<"
