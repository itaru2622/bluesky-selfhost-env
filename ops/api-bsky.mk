
# output file path of API response.
resp ?=/dev/null

#HINT: make api_setPerDayLimit
api_setPerDayLimit:
	$(eval _token=$(shell cat ${passfile} | grep BGS_ADMIN_KEY | awk -F= '{ print $$2}'))
	curl -k -X POST -L "https://bgs.${DOMAIN}/admin/subs/setPerDayLimit?limit=10000" -H "Authorization: Bearer ${_token}"
	curl -k -X GET  -L "https://bgs.${DOMAIN}/admin/subs/perDayLimit" -H "Authorization: Bearer ${_token}"

#HINT: make api_CreateOzoneServerDid
api_CreateOzoneServerDid:: _mkargs_OzoneServerDid  _execApiCmd
api_CreateOzoneServerDid:: _echo_args _findDid

_mkargs_OzoneServerDid:
	$(eval cmd=./ops-helper/apiImpl/createOzoneServerDidOnPlc.ts)
	$(eval signingKeyHex=$(shell cat ${passfile} | grep OZONE_SIGNING_KEY_HEX | awk -F= '{ print $$2}'))
	$(eval args=--plc https://plc.${DOMAIN} --signingKeyHex ${signingKeyHex})
_execApiCmd:
	${cmd} ${args} | tee -a ${resp}
_echo_args:
	@echo ""
	@echo "cmd:     ${cmd} ${args}"

#HINT: make api_CreateAccount email=...  password=...  handle=...
api_CreateAccount:: _mkmsg_createAccount  _sendMsg
api_CreateAccount:: _echo_reqAccount _findDid

#HINT: make api_DeleteAccount did=...
api_DeleteAccount:
	$(eval pass=$(shell cat ${passfile} | grep PDS_ADMIN_PASSWORD | awk -F= '{ print $$2}'))
	$(eval url='https://pds.${DOMAIN}/xrpc/com.atproto.admin.deleteAccount')
	curl -k -X POST -u "admin:${pass}" ${url} -H 'content-type: application/json' -d '{ "did": "${did}" }'
	-echo '' | grep -s -l ${did} ${aDir}/*.secrets | xargs rm -f

#HINT: make api_CreateAccount_feedgen
api_CreateAccount_feedgen: getFeedgenUserinfo api_CreateAccount

#HINT: make api_CreateAccount_ozone
api_CreateAccount_ozone: getOzoneUserinfo api_CreateAccount

_sendMsg:
	@curl -k -L -X ${method} ${url} ${header} ${msg} | tee -a ${resp}

_mkmsg_createAccount:
	$(eval url='https://pds.${DOMAIN}/xrpc/com.atproto.server.createAccount')
	$(eval method=POST)
	$(eval header=-H 'Content-Type: application/json'  -H 'Accept: application/json')
	$(eval msg=-d '{ "email": "${email}" ,"handle": "${handle}", "password": "${password}" }')

getFeedgenUserinfo:
	$(eval handle=${FEEDGEN_PUBLISHER_HANDLE})
	$(eval email=${FEEDGEN_EMAIL})
	$(eval password=$(shell cat ${passfile} | grep FEEDGEN_PUBLISHER_PASSWORD | awk -F= '{ print $$2}'))
	$(eval resp=${aDir}/${handle}.secrets)

getOzoneUserinfo:
	$(eval handle=${OZONE_ADMIN_HANDLE})
	$(eval email=${OZONE_ADMIN_EMAIL})
	$(eval password=$(shell cat ${passfile} | grep OZONE_ADMIN_PASSWORD | awk -F= '{ print $$2}'))
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
