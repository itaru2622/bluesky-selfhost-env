
docker_network ?= bsky_${DOMAIN}
dockerCompose ?= docker compose
auto_watchlog ?= true
COMPOSE_PROFILES ?= $(shell echo ${_nrepo} | sed 's/ /,/g')

_dockerUp: _load_vars _dockerUP_network
	${_envs} ${dockerCompose} -f ${f} up -d ${services}

# _env := passfile + below listup vars. cf. sed '1i' command inserts given chars to stdin.
_load_vars:
	$(eval _envs=$(shell cat ${passfile} | sed '1i\
DOMAIN=${DOMAIN} \
bgsFQDN=${bgsFQDN} \
bskyFQDN=${bskyFQDN} \
feedgenFQDN=${feedgenFQDN} \
jetstreamFQDN=${jetstreamFQDN} \
ozoneFQDN=${ozoneFQDN} \
palomarFQDN=${palomarFQDN} \
pdsFQDN=${pdsFQDN} \
plcFQDN=${plcFQDN} \
publicApiFQDN=${publicApiFQDN} \
socialappFQDN=${socialappFQDN} \
docker_network=${docker_network} \
asof=${asof} \
dDir=${dDir} \
rDir=${rDir} \
GOINSECURE=${GOINSECURE} \
NODE_TLS_REJECT_UNAUTHORIZED=${NODE_TLS_REJECT_UNAUTHORIZED} \
LOG_LEVEL_DEFAULT=${LOG_LEVEL_DEFAULT} \
EMAIL4CERTS=${EMAIL4CERTS} \
PDS_EMAIL_SMTP_URL=${PDS_EMAIL_SMTP_URL} \
FEEDGEN_PUBLISHER_DID=${FEEDGEN_PUBLISHER_DID} \
FEEDGEN_PUBLISHER_HANDLE=${FEEDGEN_PUBLISHER_HANDLE} \
OZONE_ADMIN_HANDLE=${OZONE_ADMIN_HANDLE} \
OZONE_ADMIN_EMAIL=${OZONE_ADMIN_EMAIL} \
OZONE_ADMIN_DIDS=${OZONE_ADMIN_DIDS} \
OZONE_SERVER_DID=${OZONE_SERVER_DID} \
' \
	| cat))
	@echo ${_envs} | sed 's/ /\n/g' | awk -F= '{print $$1,"=",$$2}' | sed 's/ //g'

_dockerUP_network:
	-docker network create ${docker_network}
docker-pull:
	DOMAIN= asof=${asof} ${dockerCompose} -f ${f} pull
build:
	COMPOSE_PROFILES=${COMPOSE_PROFILES} DOMAIN=${DOMAIN} asof=${asof} ${dockerCompose} -f ${f} build ${services}

docker-start::      setupdir ${wDir}/config/caddy/Caddyfile ${wDir}/certs/root.crt ${wDir}/certs/ca-certificates.crt ${passfile} _applySdep _dockerUp
ifeq ($(auto_watchlog),true)
docker-start::      docker-watchlog
endif

docker-start-bsky:: _applySbsky _dockerUp
ifeq ($(auto_watchlog),true)
docker-start-bsky:: docker-watchlog
endif

docker-start-bsky-feedgen:: _applySfeed _dockerUp
ifeq ($(auto_watchlog),true)
docker-start-bsky-feedgen:: docker-watchlog
endif

docker-start-bsky-ozone:: _applySozone _dockerUp
ifeq ($(auto_watchlog),true)
docker-start-bsky-ozone:: docker-watchlog
endif

docker-start-bsky-jetstream:: _applySjetstream _dockerUp
ifeq ($(auto_watchlog),true)
docker-start-bsky-jetstream:: docker-watchlog
endif

# execute publishFeed on feed-generator
publishFeed:
	DOMAIN=${DOMAIN} asof=${asof} docker_network=${docker_network} ${dockerCompose} -f ${f} exec feed-generator /app/scripts/publishFeed.exp ${FEEDGEN_PUBLISHER_HANDLE} "${FEEDGEN_PUBLISHER_PASSWORD}" https://${pdsFQDN} whats-alf

# execute reload on caddy container
reloadCaddy:
	DOMAIN=${DOMAIN} asof=${asof} docker_network=${docker_network} ${dockerCompose} -f ${f} exec caddy caddy reload -c /etc/caddy/Caddyfile

docker-stop:
	${dockerCompose} -f ${f} down ${services}
docker-stop-with-clean:
	${dockerCompose} -f ${f} down -v ${services}
	docker volume  prune -f
	docker system  prune -f
	docker network rm -f ${docker_network}
	sudo rm -rf ${dDir}

docker-watchlog:
	-${dockerCompose} -f ${f} logs -f || true

docker-check-status:
	docker ps -a
	docker volume ls

docker-rm-all:
	-docker ps -a -q | xargs docker rm -f
	-docker volume ls | tail -n +2 | awk '{print $$2}' | xargs docker volume rm -f
	-docker system prune -f

_gen_compose_for_binary:
	cat docker-compose-builder.yaml | yq4 'del(.services[].build)' > docker-compose.yaml

# target to configure variable
_applySdep:
	$(eval services=${Sdep})
_applySbsky:
	$(eval services=${Sbsky})
_applySfeed:
	$(eval services=${Sfeed})
_applySozone:
	$(eval services=${Sozone})
_applySjetstream:
	$(eval services=${Sjetstream})
