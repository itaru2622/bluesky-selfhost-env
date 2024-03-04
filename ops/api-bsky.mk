
# output file path of API response.
resp ?=/dev/null

#HINT: make api_CreateAccount email=...  password=...  handle=...
api_CreateAccount:: _mkmsg_createAccount  _sendMsg
api_CreateAccount:: _echo_reqAccount _findDid

#HINT: make api_CreateAccount_feedgen
api_CreateAccount_feedgen: getFeedgenUserinfo api_CreateAccount

_sendMsg:
	@curl -L -X ${method} ${url} ${header} ${msg} | tee -a ${resp}

_mkmsg_createAccount:
	$(eval url='https://pds.${DOMAIN}/xrpc/com.atproto.server.createAccount')
	$(eval method=POST)
	$(eval header=-H 'Content-Type: application/json'  -H 'Accept: application/json')
	$(eval msg=-d '{ "email": "${email}" ,"handle": "${handle}", "password": "${password}" }')

getFeedgenUserinfo:
	$(eval handle=${FEEDGEN_PUBLISHER_HANDLE})
	$(eval email=${FEEDGENERATOR_EMAIL})
	$(eval password=$(shell cat ${passfile} | grep FEEDGEN_PUBLISHER_PASSWORD | awk -F= '{ print $$2}'))
	$(eval resp=${aDir}/${handle}.secrets)

_echo_reqAccount:
	@echo ""
	@echo "handle:     ${handle}"
	@echo "email:      ${email}"
	@echo "password:   ${password}"
	@echo "resp(path): ${resp}"

_echo_apiops:
	@echo "url:    ${url}"
	@echo "method: ${method}"
	@echo "header: ${header}"
	@echo "msg:    ${msg}"

_findDid:
	@echo -n "### DID: "
	-@cat ${resp} | jq .did | sed 's/"//g'
