
# refer toplevel makefile for undefined variables and targets.

# target to generate self-signed CA certificate in easy.

#  run caddy 
#  HINT: make getCAcerts

getCAcert:
	mkdir -p ${wDir}/certs
	@echo "start caddy as self-signed CA certificate generator."
	docker run -it --rm -d --name caddy -v ${wDir}/config/caddy/Caddyfile4cert:/etc/caddy/Caddyfile caddy:2
	@echo "wait a little for caddy get ready..."
	@sleep 1
	@echo "get self-signed CA certificates from caddy container"
	docker cp caddy:/data/caddy/pki/authorities/local/root.crt ${wDir}/certs/
	docker cp caddy:/data/caddy/pki/authorities/local/root.key ${wDir}/certs/
	docker cp caddy:/data/caddy/pki/authorities/local/intermediate.crt ${wDir}/certs/
	docker cp caddy:/data/caddy/pki/authorities/local/intermediate.key ${wDir}/certs/
	docker rm -f caddy

installCAcert:
	@echo "install self-signed CA certificate into this machine..."
	sudo cp -p ${wDir}/certs/root.crt /usr/local/share/ca-certificates/testCA-caddy.crt
	sudo update-ca-certificates

${wDir}/certs/ca-certificates.crt:
	cp -p /etc/ssl/certs/ca-certificates.crt $@
