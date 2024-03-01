
#HINT: make api_CreateAccount email=...  password=...  handle=...  (cf. handle: DOMAIN will be appended in auto.)
api_CreateAccount:	_mkmsg_createAccount  _sendMsg
# cf. how to cook resp ?=> https://stackoverflow.com/questions/48512914/exporting-json-to-environment-variables

_sendMsg:
	@curl -L -X ${method} ${url} ${header} ${msg}

_mkmsg_createAccount:
	$(eval url='https://pds.${DOMAIN}/xrpc/com.atproto.server.createAccount')
	$(eval method=POST)
	$(eval header=-H 'Content-Type: application/json'  -H 'Accept: application/json')
	$(eval msg=-d '{ "email": "${email}" ,"handle": "${handle}.${DOMAIN}", "password": "${password}" }')

_echo_apiops:
	@echo "url:    ${url}"
	@echo "method: ${method}"
	@echo "header: ${header}"
	@echo "msg:    ${msg}"
