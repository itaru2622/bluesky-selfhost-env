# <a id="top"/>self-hosting bluesky 

https://github.com/itaru2622/bluesky-selfhost-env

## Contents:
  - [Motivation](#motivation)
  - [Current Status](#status)
  - [Operations for self-hosting bluesky](#ops)
      - [configuration](#ops0-configparams)
      - [prepare on your network](#ops1-prepare)
      - [check](#ops2-check)
      - [deploy](#ops3-run)
      - [play](#ops5-play)
      - [shutdown](#ops6-stop)   
  - [Hacks](#hack)
      - [Create accounts on your bluesky in easy](#hack-ops-CreateAccount)
      - [Build from source by yourself](#hack-clone-and-build)
      - Check Env Vars [in docker-compose](#hack-EnvVars-Compose) and [in sources](#hack-EnvVars-Sources)
      - [Create a table showing {env x container => value} from source and docker-compose](#hack-EnvVars-Table)
  - [Appendix](#appendix)
      - [Screen shots](#screenshots)
      - [Sourses in Use](#sources)
      - [Sample DNS Server Config(bind9)](#sample-dns-config)
      - [Historical Status](#old_status)
  - [References](#refs)

## <a id="motivation" />Motivation

this repository aims to get self-hosted bluesky env in easy with:

 - configurable hosting domain:  easy to tunable by environment variable (DOMAIN)
 - reproducibility: disclosure all configs and operations, including reverse proxy rules, and patches to sources.
 - simple:          all bluesky components runs on one host, by docker-compose.
 - less remapping:  simple rules as possible, among FQDN <=> reverse proxy <=> docker-container, for easy understanding and tunning.

at current, my latest release is <strong>2024-04-07r1</strong> based on codes <strong>2024-04-07</strong> of bluesky-social.<br>

## <a id="status"/>Current status regarding self-hosting

as described below, most features started working on self-hosting environment, but it may not work with full capabilities yet.
some of reasons are described in https://github.com/bluesky-social/atproto/discussions/2334<BR>

test results with 'asof-2024-04-07r1':<BR>

   -  ok: relaxing restriction on handle length in PDS (applyed https://github.com/bluesky-social/atproto/pull/2392)
   -  ok: create account on pds (via social-app,  bluesky API).
   -  ok: sign-in social-app (with multiple accounts)
   -  ok: basic usages on social-app
       -  ok: edit profilie (display name)
       -  ok: post articles
       -  ok: vote 'like' / repost to article
       -  ok: follow/un-follow others, via their profile page.
       -  ok: notification receiving when others vote 'like' or 'follow'
       -  ok: search posts/users/feeds
   -  ok: integration with firehose/websocket to pds/bgs(relay) => craw-able.
   -  ok: integration with feed-generator (NOTE: official feed-generator sample has some delay, so it may need reload on social-app).
   -  not tested: integration with moderation(ozone).


[back to top](#top)
## <a id="ops"/>operations for self-hosting bluesky (powered by Makefile)

below, it assumes self-hosting domain is <strong>mysky.local.com</strong> (defined in Makefile).<br>
you can change the domain name by environment variable as below:

### <a id="ops0-configparams"/>0) configure params for ops

```bash
# 1) set domain name for self-hosting bluesky
export DOMAIN=whatever.yourdomain.com

# 2) set asof date, to distinguish docker images / its sources.
#    2024-04-18(for latest prebuild, in %Y-%m-%d), or latest (following docker image naming manner in lazy).
export asof=2024-04-18

# 3) set email addresses.

# 3-1) EMAIL4CERTS:  to lets encrypt for signing certificates.
export EMAIL4CERTS=your@mail.address
# for self-signed certificates, use below(`internal` is reserved keyword).
# It is recommended to use `internal` for avoid meeting rate limits, until you are sure it ready to self-hosting.
export EMAIL4CERTS=internal

# 3-2) PDS_EMAIL_SMTP_URL: for PDS,  like smtps://youraccount:password@smtp.gmail.com
export PDS_EMAIL_SMTP_URL=smtps://

# 3-3) FEEDGEN_EMAIL: for feed-generator account in bluesky
export FEEDGEN_EMAIL=feedgen@example.com

# 4) check your configuration, from the point of view of ops.
make echo

# 5) generate secrets for bluesky containers, and check those value:
make genSecrets

## install make command as below, if you don't have yet.
apt install -y make
```

### <a id="ops1-prepare"/>1) prepare on your network

1) make DNS A-Records in your self-hosting network.<BR>

at least, following two A-Records are required.<BR>
refer [appendix](#sample-dns-config) for sample DNS server(bind9) configuration.

```
     -    ${DOMAIN}
     -  *.${DOMAIN}
```

2) generate and install CA certificate (usecases for private/closed network, and others using self-signed certificates).
    -  after generation, copy crt and key as ./certs/root.{crt,key}
    -  note: don't forget to install root.crt to your host machine and browser.

the easiest way to get self-signed CA certificates is below.
```
# get and store self-signed CA certificate into ./certs/root.{crt,key}, by using caddy.
make getCAcert
# install CA cert on host machine.
make installCAcert

# don't forget to install certificate to browser.
```

### <a id="ops2-check"/>2) check if it's ready to self-host bluesky

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
curl -L https://pds.${DOMAIN}/xrpc/any-request | jq
curl -L https://some-hostname.pds.${DOMAIN}/xrpc/any-request | jq

#  those should be redirect to social-app
curl -L https://pds.${DOMAIN}/others | jq
curl -L https://some-hostname.pds.${DOMAIN}/others | jq

# stop test containers, without persisting data
make    docker-stop-with-clean f=./docker-compose-debug-caddy.yaml
```
=> if testOK then go ahead, otherwise check your environment.


### <a id="ops3-run"/>3) deploy bluesky on your env.

first, describes deploying bluesky with prebuild images.<BR>
[later](#hack-clone-and-build) describes how to build images from sources by yourself.

```bash
# 0) pull prebuild docker images from docker.io, to enforce skip building images.
make docker-pull

# 1) deploy required containers (database, caddy etc).
make docker-start

# wait until log message becomes silent.

# 2) deploy bluesky containers(plc, bgs, appview, pds, ozone, ...)
make docker-start-bsky
```

### <a id="ops4-run-fg"/>4) deploy feed-generator on your env.

```bash
# 1) check if social-app is ready to serve.
curl -L https://social-app.${DOMAIN}/

# 2) create account for feed-generator
make api_CreateAccount_feedgen

# 3) start bluesky feed-generator
make docker-start-bsky-feedgen  FEEDGEN_PUBLISHER_DID=did:plc:...

# 4) announce existence of feed ( by scripts/publishFeedGen.ts on feed-generator).
make publishFeed
```

### <a id="ops5-play"/>5) play with self-hosted blusky.

on your browser, access ```https://social-app.${DOMAIN}/``` such as ```https://social-app.mysky.local.com/```

refer [screenshots](./docs/screenshots), for UI operations to create/sign-in account on your self-hosting bluesky.

### <a id="ops6-stop"/>6) stop all containters

```bash
# choice1) shutdown containers but keep data alive.
make docker-stop

# choice2) shutdown containers and clean those data
make docker-stop-with-clean
```

[back to top](#top)
## <a id="hack"/>Hack

### <a id="hack-ops-CreateAccount"/>create accounts on your bluesky in easy

```bash
export u=foo
make api_CreateAccount handle=${u}.pds.${DOMAIN} password=${u} email=${u}@example.com resp=./data/accounts/${u}.secrets

#then, to make another accounts, just re-assign $u and call the above ops, like below.
export u=bar
!make

export u=baz
!make
```

### <a id="hack-clone-and-build"/>build docker images from sources by yourself

after configuring [params](#ops0-configparams) and [optional env](#hack-ops-development),
operate as below:

```bash
# get sources from all repositories
make    cloneAll

# create work branches and keep staying on them for all repositories (repos/*; optional but recommended for safe.)
make    createWorkBranch
```

then build docker images as below:

```bash
# 0) apply mimimum patch to build images, regardless self-hosting.
#      as described in https://github.com/bluesky-social/atproto/discussions/2026 for feed-generator/Dockerfile etc.
# NOTE: this ops checkout new branch before applying patch, and keep staying new branch
make patch-dockerbuild

# 1) build images with original
make build DOMAIN= f=./docker-compose-builder.yaml

# below ops is now obsoleted and unsupported bacause of fragile(high cost and low return). also below patch has no effect on PDS scaling out(multiple PDS domains).
# ~~ 2) apply optional patch for self-hosting, and re-build image ~~
# ~~  'optional' means, applying this patch is not mandatory to get self-hosting environment. ~~
# ~~ NOTE: this ops checkout new branch before applying patch, and keep staying new branch ~~
#
# ~~ make _patch-selfhost-even-not-mandatory ~~
# ~~ make build services=social-app f=./docker-compose-builder.yaml ~~
```

[back to top](#top)
### <a id="hack-ops-development"/>ops on development with your remote fork repo.

when you set fork_repo_prefix variable before cloneAll,
this ops registers your remote fork repository with ```git remote add fork ....```
then you have additional easy ops against multiple repositores, as below.

```bash
export fork_repo_prefix=git@github.com:YOUR_GITHUB_ACCOUNT/

make cloneAll

# manage(push and pull) branches and tags for all repos by single operation against your remote fork repositories.
make exec under=./repos/* cmd='git push fork branch'
make exec under=./repos/* cmd='git tag -a "asof-XXXX-XX-XX" '
make exec under=./repos/* cmd='git push fork --tags'

# push something on justOneRepo to your fork repository.
make exec under=./repos/justOneRepo cmd='git push fork something'

# refer Makefile for details and samples.
```

[back to top](#top)
### <a id="hack-EnvVars-Compose"/>check Env Vars in docker-compose

1) get all env vars in docker-compose

```bash
# names and those values
_yqpath='.services[].environment, .services[].build.args'
_yqpath='.services[].environment'

# lists of var=val
cat ./docker-compose-builder.yaml | yq -y "${_yqpath}" \
  | grep -v '^---' | sed 's/^- //' | sort -u -f

# output in yaml
cat ./docker-compose-builder.yaml | yq -y "${_yqpath}" \
  | grep -v '^---' | sed 's/^- //' | sort -u -f  \
  | awk -F= -v col=":" -v q="'" -v sp="  " -v list="-" '{print   sp list sp q $1 q col sp q $2 q}' \
  | sed '1i defs:' | yq -y


# list of names
cat ./docker-compose-builder.yaml | yq -y "${_yqpath}" \
  | grep -v '^---' | sed 's/^- //' | sort -u -f \
  | awk -F= '{print $1}' | sort -u -f
```

2) env vars regarding {URL | DID | DOMAIN} == mapping rules in docker-compose

```bash
# get {name=value} of env vars regarding { URL | DID | DOMAIN }
cat ./docker-compose-builder.yaml | yq -y .services[].environment \
 | grep -v '^---' | sed 's/^- //' | sort -u -f \
 | grep -e :// -e did: -e {DOMAIN}

# get names of env vars regarding { URL | DID | DOMAIN }
cat ./docker-compose-builder.yaml | yq -y .services[].environment \
 | grep -v '^---' | sed 's/^- //' | sort -u -f \
 | grep -e :// -e did: -e {DOMAIN} \
 | awk -F= '{print $1}' | sort -u -f \
 | tee /tmp/url-or-did.txt
```

3) get mapping rules in reverse proxy (caddy )

```bash
# dump rules, no idea to convert into  easy readable format...
cat config/caddy/Caddyfile
```

[back to top](#top)
### <a id="hack-EnvVars-Sources"/>check Env Vars in sources

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

3) find {URL | DID | bsky } near env names in sources

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
### <a id="hack-EnvVars-Table"/>create a table showing {env x container => value} from source and docker-compose.

this hask uses the result(/tmp/envs.txt) of [the above](#hack-EnvVars-Sources) as input.

```bash
# create table showing { env x container => value } with ops-helper script.
cat ./docker-compose-builder.yaml | ./ops-helper/compose2envtable.py -l /tmp/envs.txt -o ./docs/env-container-val.xlsx
```

[back to top](#top)
### <a id="hack-self-signed-certs"/>regarding self-signed certificates x HTTPS x containers.

this self-hosting env tried to use self-signed certificates as usual trusted certificate by installing certificates into containers.
The expected behavior is: by sharing /etc/ssl/certs/ca-certificates.crt amang all containers, containers distinguish those in ca-certificates.crt are trusted.

unfortunately, this approach works just in some containers but not all.
It seems depending on distribution(debian/alpine/...) and language(java/nodejs/golang). the rule cannot be found in actual behaviors.
then, all of below methods are involved for safe, when it uses self-signed certificates.

- host deploys /etc/ssl/certs/ca-certificates.crts to containers by volume mount.
- define env vars for self-signed certificates, such as GOINSECURE, NODE_TLS_REJECT_UNAUTHORIZED for each language.


[back to top](#top)
## <a id="appendix"/>Appendix

### <a id="screenshots"/> screen shots:

| create account | sign-in|
|:---|:---|
|<img src="./docs/screenshots/1-bluesky-create-account.png" style="height:45%; width:45%">|<img src="./docs/screenshots/1-bluesky-sign-in.png"  style="height:45%; width:45%">|
|<img src="./docs/screenshots/2-bluesky-choose-server.png"  style="height:45%; width:45%">|<img src="./docs/screenshots/2-bluesky-choose-server.png"  style="height:45%; width:45%">|
|<img src="./docs/screenshots/3-bluesky-create-account.png"  style="height:45%; width:45%">|<img src="./docs/screenshots/3-bluesky-sign-in.png"  style="height:45%; width:45%">|

### <a id="sources"/>sources in use:

| components     | url (origin)                                           |
|----------------|:-------------------------------------------------------|
| atproto        | https://github.com/bluesky-social/atproto.git          |
| indigo         | https://github.com/bluesky-social/indigo.git           |
| social-app     | https://github.com/bluesky-social/social-app.git       |
| feed-generator | https://github.com/bluesky-social/feed-generator.git   |
| pds            | https://github.com/bluesky-social/pds.git              |
| ozone          | https://github.com/bluesky-social/ozone.git            |
| did-method-plc | https://github.com/did-method-plc/did-method-plc.git   |

other dependencies:

| components     | url (origin)                                                            |
|----------------|:------------------------------------------------------------------------|
| reverse proxy  | https://github.com/caddyserver/caddy (official docker image of caddy:2) |
| DNS server     | bind9 or others, such as https://github.com/itaru2622/docker-bind9.git  |

[back to top](#top)

### <a id="sample-dns-config"/>DNS server configuration sample (bind9)

description of test network:

```
DOMAIN for self-hosting: mysky.local.com

IP:
  - docker host for selfhost: 192.168.1.51
  - DNS server:               192.168.1.27
  - DNS forwarders:           8.8.8.8 (upper level DNS server;dns.google.)

DNS A-Records:
  -   mysky.local.com  : 192.168.1.51
  - *.mysky.local.com  : 192.168.1.51
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
mysky		A	192.168.1.51
$ORIGIN mysky.local.com.
*			A	192.168.1.51
```

cf. the most simple way to use the above DNS server(192.168.1.27) in temporal,<br>
add it in /etc/resolv.conf as below on all testing machines
(docker host, client machines for browser)

```
nameserver 192.168.1.27
```

[back to top](#top)
### <a id="old_status"/>Historical status regarding self-hosting

test results with 'asof-2024-04-07':<BR>

   -  ok: create user on pds (via bluesky API).
   -  ok: create user on pds on social-app
   -  ok: sign-in via social-app (with multiple accounts)
   -  ok: edit profilie (display name) on social-app
   -  ok: post articles on social-app
   -  ok: vote 'like' to article on social-app
   -  ok: reply to article on social-app
   -  ok: start following in others profile page on social-app
   -  ok: receive notification in home,  when others marks 'like' or 'follow', on social-app.
   -  ok: find posts in 'search' on social-app
   -  ok: find users in 'search' on social-app
         - ok: find users with 'display-name' after user configures it in his/her profile page.
         - ok: find users with full qualified handle name before display-name configured in his/her profile page.
   -  ok: discover feed in '#feeds' on social-app after feed-generator joined and executed feed-generator/scripts/publishFeedGen.ts.
   -  ok: pin/unpin feeds to home on social-app after discovering
   -  ok: feed-generator subscribes and pushes posts into its feed channel => view them on social-app. (NOTE: it has some delay, so reload on social-app).
   -  ok: websocket subscribing to pds/bgs with firehose/websocat.
   -  not tested: regarding moderation

test results with 'asof-2024-04-03':<BR>

   -  ok: create user on pds (via bluesky API).
   -  ok: create user on pds on social-app
   -  ok: sign-in via social-app (with multiple accounts)
   -  ok: edit profilie (display name) on social-app
   -  ok: post articles on social-app
   -  ok: vote 'like' to article on social-app
   -  ok: reply to article on social-app
   -  ok: start following in others profile page on social-app
   -  ok: receive notification in home,  when others marks 'like' or 'follow', on social-app.
   -  ok: find posts in 'search' on social-app
   -  ok: find users in 'search' on social-app
         - ok: find users with 'display-name' after user configures it in his/her profile page.
         - ok: find users with full qualified handle name before display-name configured in his/her profile page.
   -  ok: discover feed in '#feeds' on social-app after feed-generator joined and executed feed-generator/scripts/publishFeedGen.ts.
   -  ok: pin/unpin feeds to home after discovering
   -  not tested: post an article in feed.
   -  not tested: view post in feed (channel) on social-app.
   -  not tested: regarding moderation
   -  ok: websocket subscribing; tested with firehose/websocat to pds/bgs, and feed-generator

test results with 'asof-2024-03-16' (now archiving status):<BR>

   -  ok: create user on pds (via bluesky API).
   -  NG: create user on pds on social-app (get stuck after submitting 'continue'. <=> in dev-env, we have 'clear' in upper right corner on social-app to get out from stuck.)
   -  ok: sign-in via social-app (with multiple accounts)
   -  ok: edit profilie (display name) on social-app
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
   -  ok: pin/unpin feeds to home after discovering
   -  not tested: post an article in feed.
   -  not tested: view post in feed (channel) on social-app.
   -  not tested: regarding moderation
   -  ok: websocket subscribing; tested with firehose/websocat to pds/bgs, and feed-generator


test results with 'asof-2024-01-06' (now archiving status):<BR>

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
   -  ok: websocket subscribing; tested with firehose/websocat to pds/bgs, and feed-generator

It seems: indexer and feed-generator are not working by unknown reason even those are staying 'up' status.

[back to top](#top)
## <a id="refs"/>References

special thanks to prior works on self-hosting.
   - https://github.com/ikuradon/atproto-starter-kit/tree/main
   - https://github.com/bluesky-social/atproto/discussions/2026 and https://syui.ai/blog/post/2024/01/08/bluesky/

hacks in bluesky:
   - https://github.com/bluesky-social/social-app/blob/main/docs/build.md
   - https://github.com/bluesky-social/indigo/blob/main/HACKING.md
   - https://github.com/bluesky-social/ozone/blob/main/HOSTING.md
   - https://github.com/bluesky-social/pds/blob/main/installer.sh

[back to top](#top)
