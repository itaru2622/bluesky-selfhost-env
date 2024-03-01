
build:
	DOMAIN=${DOMAIN} asof=${asof} docker-compose -f ${f} build ${services}

docker-start::      setupdir config/caddy/Caddyfile certs/ca-certificates.crt ${passfile} _applySdep _docker_up
docker-start::      docker-watchlog
docker-start-bsky:: _applySbsky _docker_up
docker-start-bsky:: docker-watchlog
docker-stop:
	docker-compose -f ${f} down -v
	docker system  prune -f
	docker volume  prune -f
	docker network prune -f
	sudo rm -rf ./data
#	rm -rf ${passfile}

docker-watchlog:
	-docker-compose -f ${f} logs -f || true

_docker_up:
	. ${passfile} && DOMAIN=${DOMAIN} asof=${asof} EMAIL4CERTS=${EMAIL4CERTS} LOG_LEVEL_DEFAULT=${LOG_LEVEL_DEFAULT} \
	    ADMIN_PASSWORD=$${ADMIN_PASSWORD} \
	    BGS_ADMIN_KEY=$${BGS_ADMIN_KEY} \
	    IMG_URI_KEY=$${IMG_URI_KEY} \
	    IMG_URI_SALT=$${IMG_URI_SALT} \
	    MODERATOR_PASSWORD=$${MODERATOR_PASSWORD} \
	    OZONE_ADMIN_PASSWORD=$${OZONE_ADMIN_PASSWORD} \
	    OZONE_MODERATOR_PASSWORD=$${OZONE_MODERATOR_PASSWORD} \
	    OZONE_SIGNING_KEY_HEX=$${OZONE_SIGNING_KEY_HEX} \
	    OZONE_TRIAGE_PASSWORD=$${OZONE_TRIAGE_PASSWORD} \
	    PDS_ADMIN_PASSWORD=$${PDS_ADMIN_PASSWORD} \
	    PDS_JWT_SECRET=$${PDS_JWT_SECRET} \
	    PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=$${PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX} \
	    PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX=$${PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX} \
	    SERVICE_SIGNING_KEY=$${SERVICE_SIGNING_KEY} \
	    TRIAGE_PASSWORD=$${TRIAGE_PASSWORD} \
	    POSTGRES_PASSWORD=$${POSTGRES_PASSWORD} \
	    PASS=$${PASS} \
        docker-compose -f ${f} up -d ${services}


setupdir:
	mkdir -p data/pds data/appview/cache data/image/static data/image/tmp

# target to configure variable
_applySdep:
	$(eval services=${Sdep})
_applySbsky:
	$(eval services=${Sbsky})
