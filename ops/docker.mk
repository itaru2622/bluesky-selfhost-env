
_dockerUp: _load_vars
	${_envs} docker-compose -f ${f} up -d ${services}

# _env := passfile + below listup vars. cf. sed '1i' command inserts given chars to stdin.
_load_vars:
	$(eval _envs=$(shell cat ${passfile} | sed '1i\
DOMAIN=${DOMAIN} \
asof=${asof} \
dDir=${dDir} \
GOINSECURE=${GOINSECURE} \
NODE_TLS_REJECT_UNAUTHORIZED=${NODE_TLS_REJECT_UNAUTHORIZED} \
LOG_LEVEL_DEFAULT=${LOG_LEVEL_DEFAULT} \
EMAIL4CERTS=${EMAIL4CERTS} \
PDS_EMAIL_SMTP_URL=${PDS_EMAIL_SMTP_URL} \
FEEDGEN_PUBLISHER_DID=${FEEDGEN_PUBLISHER_DID} \
FEEDGEN_PUBLISHER_HANDLE=${FEEDGEN_PUBLISHER_HANDLE}' \
	| cat))
	@echo ${_envs} | sed 's/ /\n/g' | awk -F= '{print $$1,"=",$$2}' | sed 's/ //g'

build:
	DOMAIN=${DOMAIN} asof=${asof} docker-compose -f ${f} build ${services}

docker-start::      setupdir config/caddy/Caddyfile certs/ca-certificates.crt ${passfile} _applySdep _dockerUp
docker-start::      docker-watchlog
docker-start-bsky:: _applySbsky _dockerUp
docker-start-bsky:: docker-watchlog
docker-start-bsky-feedgen:: _applySfeed _dockerUp
docker-start-bsky-feedgen:: docker-watchlog
docker-stop:
	docker-compose -f ${f} down -v ${services}
	docker system  prune -f
	docker volume  prune -f
	docker network prune -f
	sudo rm -rf ${dDir}

docker-watchlog:
	-docker-compose -f ${f} logs -f || true

docker-check-status:
	docker ps -a
	docker volume ls

docker-rm-all:
	-docker ps -a -q | xargs docker rm -f
	-docker volume ls | tail -n +2 | awk '{print $$2}' | xargs docker volume rm -f
	-docker system prune -f

# target to configure variable
_applySdep:
	$(eval services=${Sdep})
_applySbsky:
	$(eval services=${Sbsky})
_applySfeed:
	$(eval services=${Sfeed})
