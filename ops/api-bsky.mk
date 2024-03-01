
# output file path of API response.
resp ?=/dev/null

#HINT: make api_CreateAccount email=...  password=...  handle=...  (cf. handle: DOMAIN will be appended in auto.)
api_CreateAccount:	_mkmsg_createAccount  _sendMsg

#HINT: make api_CreateAccount_feedgen
api_CreateAccount_feedgen: getFeedgenUserinfo _mkmsg_createAccount _sendMsg _echo_reqAccount

_sendMsg:
	@curl -L -X ${method} ${url} ${header} ${msg} | tee -a ${resp}



_mkmsg_createAccount:
	$(eval url='https://pds.${DOMAIN}/xrpc/com.atproto.server.createAccount')
	$(eval method=POST)
	$(eval header=-H 'Content-Type: application/json'  -H 'Accept: application/json')
	$(eval msg=-d '{ "email": "${email}" ,"handle": "${handle}.${DOMAIN}", "password": "${password}" }')

getFeedgenUserinfo:
	$(eval handle=feedgen)
	$(eval email=no-reply-${handle}@${DOMAIN})
	$(eval password=`cat ${passfile} | grep FEEDGENERATOR_PASSWORD | sed 's/.*=//'`)
	$(eval resp=${wDir}/data/accounts/${handle}.secrets)

_echo_reqAccount:
	@echo "handle:     ${handle}"
	@echo "email:      ${email}"
	@echo "password:   ${password}"
	@echo "resp(path): ${resp}"

_echo_apiops:
	@echo "url:    ${url}"
	@echo "method: ${method}"
	@echo "header: ${header}"
	@echo "msg:    ${msg}"
