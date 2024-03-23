# <a id="top"/>self-hosting bluesky 

## Contents:
  - [Motivation](#motivation)
  - [Current Status](#status)
  - [References](#refs)
  - [Sourses in Use](#sources)
  - [Operations to get and run self-hosting bluesky](#ops)
  - [Hacks](#hack)
  - [Sample DNS Server Config(bind9)](#sample-dns-config)

## <a id="motivation" />Motivation

this repository aims to get self-hosted bluesky env in easy with:

 - configurable hosting domain:  easy to tunable by environment variable (DOMAIN)
 - reproducibility: disclosure all configs and operations, including reverse proxy rules.
 - simple:          all bluesky components runs on one host, by docker-compose.
 - less remapping:  simple rules as possible, among FQDN <=> reverse proxy <=> docker-container, for easy understanding and tunning.

at current, working with code asof <strong>2024-03-16</strong> of bluesky-social.<br>
it may not work with latest codes.

## <a id="status"/>Current status regarding self-hosting

with 'asof-2024-03-16' branch, as described below, most features started working on self-hosting environment, but it may not work with full capabilities yet.
some of reasons are described in https://github.com/bluesky-social/atproto/discussions/2334<BR>

at current, this self-hosting env provides below capabilities:

   -  ok: create user on pds (via bluesky API).
   -  NG: create user on pds on social-app (get stuck after submitting 'continue'. <=> in dev-env, we have 'clear' in upper right corner on social-app to get out from stuck.)
   -  ok: sign-in via social-app (with multiple accounts)
   -  ok: post articles on social-app
   -  ok: vote 'like' to article on social-app
   -  ok: reply to article on social-app
   -  ok: start following in others profile page on social-app
   -  ok: receive notification in home,  when others marks 'like' or 'follow', on social-app.
   -  ok: find posts in 'search' on social-app
   -  ??: find users in 'search' on social-app
         - ok: find users with 'display-name' after user configures it in his/her profile page.
         - none(without any error): find users with full qualified handle name before display-name configured in his/her profile page.
   -  ok: discover feed in '#feeds' on social-app after feed-generator joined and executed feed-generator/scripts/publishFeedGen.ts.
   -  not tested: post an article in feed.
   -  not tested: view post in feed (channel) on social-app.
   -  not tested: regarding moderation
   -  ok: websocket subscribing; tested with feed-generator, and websocat to pds/bgs.


with 'asof-2024-01-06' branch, as described below, basic feature started working on self-hosting environment, but still needs some work for full capabilities.

   -  ok: create user on pds via social-app, and bluesky API.
   -  ok: sign-in via social-app (with multiple accounts)
   -  ok: post articles on social-app
   -  ok: vote 'like' to  article on social-app
   -  ok: reply to article on social-app
   -  ok: start following in others profile page on social-app
   -  ok: receive notification in home,  when others marks 'like' or 'follow', on social-app.
   -  ok: find posts in 'search' on social-app
   -  NG: find users in 'search' on social-app  <- reason unknown yet.
   -  NG: find feeds in 'search' on social-app  <- investigation not started
   -  not tested: regarding moderation
   -  ok: websocket working; tested with wss://test-wss.${DOMAIN}/ and ws://test-ws.${DOMAIN}/

It seems: indexer and feed-generator are not working by unknown reason even those are staying 'up' status.

[back to top](#top)

## <a id="refs"/>References

special thanks to prior works on self-hosting.
   - https://github.com/ikuradon/atproto-starter-kit/tree/main
   - https://github.com/bluesky-social/atproto/discussions/2026 and https://syui.ai/blog/post/2024/01/08/bluesky/

hacks in bluesky:
   - https://github.com/bluesky-social/social-app/blob/main/docs/build.md
   - https://github.com/bluesky-social/indigo/blob/main/HACKING.md

[back to top](#top)
## <a id="sources"/>sources in use

| components     | url (origin)                                           |
|----------------|:-------------------------------------------------------|
| atproto        | https://github.com/bluesky-social/atproto.git          |
| indigo         | https://github.com/bluesky-social/indigo.git           |
| social-app     | https://github.com/bluesky-social/social-app.git       |
| feed-generator | https://github.com/bluesky-social/feed-generator.git   |
| did-method-plc | https://github.com/did-method-plc/did-method-plc.git   |

other dependencies:

| components     | url (origin)                                                            |
|----------------|:------------------------------------------------------------------------|
| recverse proxy | https://github.com/caddyserver/caddy (official docker image of caddy:2) |
| DNS server     | bind9 or others, such as https://github.com/itaru2622/docker-bind9.git  |

[back to top](#top)
## <a id="ops"/>operations (powered by Makefile)

below, it assumes self-hosting domain is mybluesky.local.com (defined in Makefile).<br>
you can overwrite the domain name by environment variable as below:

### <a id="ops0-configparamss"/>0) configure params for ops

```bash
# 1) set domain name for self-hosting bluesky
export DOMAIN=whatever.yourdomain.com

# 2) set asof daytime, for bluesky-social codes (current testing with 2024-03-16)
export asof=2024-03-16

# 3) set PDS_EMAIL_SMTP_URL like smtps://yourmail:password@smtp.gmail.com
export PDS_EMAIL_SMTP_URL=smtps://

# 4) set FEEDGEN_EMAIL for account in bluesky
export FEEDGEN_EMAIL=feedgen@your.valid.com

# 4) check your configuration, from the point of view of ops.
make echo

# 5) generate passwords for bluesky containers, and check those value:
make genPass
```

### <a id="ops1-clone"/>1) get sources and checkout

```bash
# get sources from all repositories
make    cloneAll

# checkout codes according to asof param, for all sources.
make   mkBranch_asof branch=work
```

### <a id="ops2-prepare"/>2) prepare on your network

```
1) make DNS A-Records for your self-hosting domain, at least:
     -    ${DOMAIN}
     -  *.${DOMAIN}

2) generate and install CA certificate (for self-signed certificate)
     -  after generation, copy crt and key as ./certs/root.{crt,key}
     -  note: don't forget to install root.crt to your host machine and browser.
```

### <a id="ops3-check"/>3) check if it's ready to self-host bluesky

```bash
# check DNS server responses for your self-host domain
dig  ${DOMAIN}
dig  any.${DOMAIN}

# start containers for test
make    docker-start f=./docker-compose-debug-caddy.yaml services=

# test HTTPS and WSS with your docker environment
curl -L https://test-wss.${DOMAIN}/
open -L https://test-wss.${DOMAIN}/ on browser.
wscat -c https://test-wss.${DOMAIN}/ws with CUI nodejs wscat package

# test reverse proxy mapping if it works as expected for bluesky
#  those should be redirect to PDS
curl -L https://${DOMAIN}/xrpc/any-request | jq
curl -L https://some-hostname.${DOMAIN}/xrpc/any-request | jq

#  those should be redirect to social-app
curl -L https://${DOMAIN}/others | jq
curl -L https://some-hostname.${DOMAIN}/others | jq

# stop test containers.
make    docker-stop f=./docker-compose-debug-caddy.yaml
```
=> if testOK then go ahead, otherwise check your environment.


### <a id="ops4-build"/>4) build docker images, to prepare self-hosting...

```bash
# 0) apply mimimum patch for self-docker-image-build, regardless self-hosting.
#      as described in https://github.com/bluesky-social/atproto/discussions/2026 for feed-generator/Dockerfile etc.
# NOTE: this ops checkout new branch before applying patch, and keep staying new branch
make patch-dockerbuild

# 1) build images with original
make build DOMAIN=

# 2) apply patch for self-hosting
#      as described in https://syui.ai/blog/post/2024/01/08/bluesky/
# NOTE: this ops checkout new branch before applying patch, and keep staying new branch
make patch-selfhost

# 3) build social-app for self-hosting...
make build services="social-app feed-generator"
```

### <a id="ops5-run"/>5) run bluesky with selfhosting

```bash
# 1) start required containers (database, caddy etc).
make docker-start

# wait until log message becomes silent.

# 2) start bluesky containers, finally...
make docker-start-bsky
```

### <a id="ops6-run-fg"/>6) run bluesky feed-generator

```bash
# 1) check if social-app is ready to serve.
curl -L https://social-app.${DOMAIN}/

# 2) create account for feed-generator
make api_CreateAccount_feedgen

# 3) start boosky feed-generator
make docker-start-bsky-feedgen  FEEDGEN_PUBLISHER_DID=did:plc:...
```

### <a id="ops7-play"/>7) play with self-hosted blusky.

on your browser, access ```https://social-app.${DOMAIN}/``` such as ```https://social-app.mybluesky.local.com/```

### <a id="ops8-stop"/>8) stop all containters

```bash
make docker-stop
```

[back to top](#top)
## <a id="hack"/>Hack

### <a id="hack1-ops-CreateAccount"/>1) create accounts in easy

```bash
export u=foo
make api_CreateAccount handle=${u}.${DOMAIN} password=${u} email=${u}@example.com resp=${aDir}/${u}.secrets

#then, to make other account, just re-assign $u and call the above ops, like below.
export u=bar
!make

export u=baz
!make
```

[back to top](#top)
### <a id="hack1-EnvVars2"/>2) check Env Vars in docker-compose

1) get all env vars in docker-compose

```bash
# names and those values
_yqpath='.services[].environment, .services[].build.args'
_yqpath='.services[].environment'

# lists of var=val
cat ./docker-compose-starter.yaml | yq -y "${_yqpath}" \
  | grep -v '^---' | sed 's/^- //' | sort -u -f

# output in yaml
cat ./docker-compose-starter.yaml | yq -y "${_yqpath}" \
  | grep -v '^---' | sed 's/^- //' | sort -u -f  \
  | awk -F= -v col=":" -v q="'" -v sp="  " -v list="-" '{print   sp list sp q $1 q col sp q $2 q}' \
  | sed '1i defs:' | yq -y


# list of names
cat ./docker-compose-starter.yaml | yq -y "${_yqpath}" \
  | grep -v '^---' | sed 's/^- //' | sort -u -f \
  | awk -F= '{print $1}' | sort -u -f
```

2) env vars regarding {URL | DID | DOMAIN} == mapping rules in docker-compose

```bash
# get {name=value} of env vars regarding { URL | DID | DOMAIN }
cat ./docker-compose-starter.yaml | yq -y .services[].environment \
 | grep -v '^---' | sed 's/^- //' | sort -u -f \
 | grep -e :// -e did: -e {DOMAIN}

# get names of env vars regarding { URL | DID | DOMAIN }
cat ./docker-compose-starter.yaml | yq -y .services[].environment \
 | grep -v '^---' | sed 's/^- //' | sort -u -f \
 | grep -e :// -e did: -e {DOMAIN} \
 | awk -F= '{print $1}' | sort -u -f \
 | tee /tmp/url-or-did.txt
```

3) get mapping rules in reverse proxy (caddy )

```bash
# dump rules, no idea to convert into  easy reading format...
cat config/caddy/Caddyfile
```

[back to top](#top)
### <a id="hack1-EnvVars1"/>2) check Env Vars in sources

1) files related env vars in sources

```bash
# files named *env*
find repos -type f | grep -v -e /.git/  | grep -i env \
  | grep -v -e .jpg$ -e .ts$  -e .json$ -e .png$ -e .js$

# files containing 'export'
find repos -type f | grep -v /.git/  | xargs grep -l export \
  | grep -v -e .js$ -e .jsx$  -e .ts$ -e .tsx$ -e .go$ -e go.sum$ -e go.mod$ -e .po$ -e .json$ -e .patch$ -e .lock$ -e .snap$
```

2) get all env vars from source code

```bash
#in easy
_files=repos
#ensure files to search  envs
_files=`find repos -type f | grep -v -e '/.git' -e /__  -e /tests/ -e _test.go -e /interop-test-files  -e /testdata/ -e /testing/ -e /jest/ -e /node_modules/ -e /dist/ | sort -u -f`

# for javascripts families from process.env.ENVNAME
grep -R process.env ${_files} \
  | cut -d : -f 2- | sed 's/.*process\.//' | grep '^env\.' | sed 's/^env\.//' \
  | sed -r 's/(^[A-Za-z_0-9\-]+).*/\1/' | sort -u -f \
  | tee /tmp/vars-js1.txt

# for javascripts families from envXXX('MORE_ENVNAME'), refer atproto/packages/common/src/env.ts for envXXX
grep -R -e envStr -e envInt -e envBool -e envList ${_files} \
  | cut -d : -f 2- \
  | grep -v -e ^import -e ^export -e ^function  \
  | sed "s/\"/'/g" \
  | grep \' | awk -F\' '{print $2}' | sort -u -f \
  | tee /tmp/vars-js2.txt

# for golang  from EnvVar(s): []string{"ENVNAME", "MORE_ENVNAME"}
grep -R EnvVar ${_files} \
  | cut -d : -f 3- | sed -e 's/.*string//' -e 's/[,"{}]//g' \
  | tr ' ' '\n' | grep -v ^$ | sort -u -f \
  | tee /tmp/vars-go.txt

# for docker-compose from services[].environment
echo {$_files} \
  | tr ' ' '\n' | grep -v ^$ | grep -e .yaml$ -e .yml$ | grep compose \
  | xargs yq -y .services[].environment | grep -v ^--- | sed 's/^- //' \
  | sed 's/: /=/' | sed "s/'//g" \
  | sort -u -f \
  | awk -F= '{print $1}' | sort -u -f \
  | tee /tmp/vars-compose.txt


# get unique lists
cat /tmp/vars-js1.txt /tmp/vars-js2.txt /tmp/vars-go.txt /tmp/vars-compose.txt | sort -u -f > /tmp/envs.txt

# pick env vars related to mapping {URL, ENDPOINT, DID, HOST, PORT, ADDRESS}
cat /tmp/envs.txt  | grep -e URL -e ENDPOINT -e DID -e HOST -e PORT -e ADDRESS
```

3) find {URL | DID | bsky } near env names

```bash
find repos -type f | grep -v -e /.git  -e __ -e .json$ \
  | xargs grep -R -n -A3 -B3 -f /tmp/envs.txt \
  | grep -A2 -B2 -e :// -e did: -e bsky
```

4) find bsky.{social,app,network} in sources ( to check hard-coded domain/FQDN )

```bash
find repos -type f | grep -v -e /.git -e /tests/ -e /__ -e Makefile -e .yaml$ -e .md$  -e .sh$ -e .json$ -e .txt$ -e _test.go$ \
  | xargs grep -n -e bsky.social -e bsky.app -e bsky.network  -e bsky.dev
```

[back to top](#top)
## <a id="sample-dns-config"/>DNS server configuration sample (bind9)

description of test network:

```
DOMAIN for self-hosting: mybluesky.local.com

IP:
  - docker host for selfhost: 192.168.1.51
  - DNS server:               192.168.1.27
  - DNS forwarders:           8.8.8.8 (upper level DNS server;dns.google.)

DNS A-Records:
  -   mybluesky.local.com  : 192.168.1.51
  - *.mybluesky.local.com  : 192.168.1.51
```

the above would be described in bind9 configuration file as below:

```
::::::::::::::
/etc/bind/named.conf
::::::::::::::
include "/etc/bind/rndc.key";
controls {
        inet 127.0.0.1 allow { 127.0.0.1; } keys { "rndc-key"; };
};
options {
        directory         "/etc/bind";
        // UDP 53, from any
        listen-on         { any; };
        // HTTP 80, from any
        listen-on  port 80  tls none http default  { any; };
        listen-on-v6      { none; };
        forwarders        { 8.8.8.8 ; };  # dns.gogle.
        allow-recursion   { any; };
        allow-query       { any; };
        allow-query-cache { any; };
        allow-transfer    { any; };
};
zone "local.com" { type master; file "zone-local.com"; allow-query { 0.0.0.0/0; }; allow-update { 0.0.0.0/0; }; allow-transfer { 0.0.0.0/0; }; };
::::::::::::::
/etc/bind/zone-local.com
::::::::::::::
$ORIGIN .
$TTL 259200	; 3 days
local.com		IN SOA	local.com. root.local.com. (
				2024022809 ; serial
				3600       ; refresh (1 hour)
				900        ; retry (15 minutes)
				86400      ; expire (1 day)
				3600       ; minimum (1 hour)
				)
			NS	local.com.
			A	192.168.1.27
$ORIGIN local.com.
$TTL 3600	; 1 hour
mybluesky		A	192.168.1.51
$ORIGIN mybluesky.local.com.
*			A	192.168.1.51
```

cf. the most simple way to use the above DNS server(192.168.1.27) in temporal,<br>
add it in /etc/resolv.conf as below on all testing machines
(docker host, client machines for browser)

```
nameserver 192.168.1.27
```
[back to top](#top)
