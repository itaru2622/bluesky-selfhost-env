# <a id="top"/>self-hosting entire bluesky

https://github.com/itaru2622/bluesky-selfhost-env

## Contents:
  - [Motivation](#motivation)
  - [Current Status](#status)
  - [Steps to self-host Bluesky](#ops)
      - [Configuration](#ops0-configparams)
      - [Prepare your network](#ops1-prepare)
      - [Check](#ops2-check)
      - [Deploy](#ops3-run)
      - [Play](#ops5-play)
      - [Shutdown](#ops6-stop)   
  - [Hacks](#hack)
      - [Create accounts on your bluesky in easy](#hack-ops-CreateAccount)
      - [Build from source by yourself](#hack-clone-and-build)
      - Check Env Vars [in docker-compose](#hack-EnvVars-Compose) and [in sources](#hack-EnvVars-Sources)
      - [Create a table showing {env x container => value} from source and docker-compose](#hack-EnvVars-Table)
  - [Appendix](#appendix)
      - [Screen shots](#screenshots)
      - [Sourses in Use](#sources)
      - [Sample DNS Server Config(bind9)](#sample-dns-config)
  - [References](#refs)

## <a id="motivation" />Motivation

This repository aims to deploy a self-hosted bluesky stack easily by:

 - Domain Variable Deployment: The instance's domain can be easily changed with the ${DOMAIN} environment variable
 - Reproducability: This repo discloses all configurations, operations, reverse proxy rules and patches to the original code in it's source code.
 - Simplicity: All required containers and processes are designed to run on one host via Docker Compose.
 - Less Variable Mapping: Environment Variables are stream-lined to make deployment understandable and easily tunable. For example, one variable controls all these variables: FQDN <=> reverse proxy <=> docker-container

At the time of writing, the latest release is <strong>2025-01-26</strong> based on the source code provided on <strong>2025-01-26</strong> by bluesky-social.<br>

## <a id="status"/>Current status regarding self-hosting

Below is a list of features that work as expected in this self-hosted stack.<br>
Unfortunately, all features may not work at this time. Some reasoning may be found [here](https://github.com/bluesky-social/atproto/discussions/2334)<br>

Feature test results for releases `asof-2024-06-02` and later:<br>

   -  ✅ Working: Creating accounts on the personal data server (PDS) via the bsky social-app, and blusky API.
   -  ✅ Working: Basic bsky social-app functionality
       -  ✅ Working: Signing in, editing your profile, posting/reposting, searching posts/users/feeds, liking posts and following users
       -  ✅ Working: Notifications on likes and follows from other users
       -  ✅ Working: Subscribe/Unsubscribe labels in profile page.
       -  ✅ Working: Report to labeler for any post.
       -  ❎ NOT Working: Direct Messages (DMs) with other users
   -  ✅ Working: Integration with [feed-generator](https://github.com/bluesky-social/feed-generator) NOTE: If there is delay, try reloading the social-app.
   -  ✅ Working: Moderation with [ozone](https://github.com/bluesky-social/ozone).
       -  ✅ Working: Sign-in and configuring settings with the ozone-UI.
       -  ✅ Working: View reports labels.
       -  ✅ Working: Assign labels to posts/accounts in the ozone-UI then publish corresponding events to subscribeLabels.
       -  ✅ Working: View post changes on social-app according to label assignments, when using the [workaround tool](https://github.com/itaru2622/bluesky-selfhost-env/blob/master/ops-helper/apiImpl/subscribeLabels2BskyDB.ts).
          -  NOTE: Without the workaround tool, the view is not changed. Refer to https://github.com/bluesky-social/atproto/issues/2552
   -  ✅ Working: Subscribe to events from the PDS/BGS/ozone with Firehose or Websocket.
   -  ✅ Working:: Subscribe to events from Jetstream. (Added 2024-10-19r1)
   -  ❎ NOT Working (yet): Various other features.

[Back to top](#top)
## <a id="ops"/>Steps to self-host Bluesky (powered by Makefile)

The following guide will use <strong>mysky.local.com</strong> as the example domain.<br>
Use the instructions below to set your own domain name as an environment variable for the Makefile.

### <a id="ops0-configparams"/>0) Configure variables, parameters and install tools for operation

```bash
# 1) Set the domain for Bluesky to be hosted on
export DOMAIN=mysky.local.com

# 2) Set the asof date to select which Bluesky build (Docker containers/Configs) you want to deploy.
#        Set this variable to 2025-01-26 for the latest prebuild, in %Y-%m-%d, or latest to follow Dockers "lazy" tagging system.
export asof=2025-01-26

# 3) Configure email addresses

# 3-1) Set EMAIL4CERTS to define the email you want to use to verify your domains SSL certificate with Let's Encrypt
export EMAIL4CERTS=your@mail.address  # Replace with your email address and remove the next line for public certs
export EMAIL4CERTS=internal  # Remove the previous line and use "internal" to use a self-signed certificate. It is recommeneded to use the "internal" cert until you have verified your setup works.

# 3-2) Set PDS_EMAIL_SMTP_URL for outgoing mail from the PDS. Please use the format "smtps://USERNAME:APP-PASSWORD@YOURMAILPROVIDER.COM"
export PDS_EMAIL_SMTP_URL=smtps://

# 3-3) Set FEEDGEN_EMAIL for the feed-generator account within bluesky.
export FEEDGEN_EMAIL=feedgen@example.com

## Install dependencies
# Debian and Derivatives
apt install -y make pwgen
# Fedora and Derivatives
dnf install -y make pwgen
# Arch and Derivatives
pacman -Sy make pwgen

cd ops-helper/apiImpl ; npm install
sudo curl -o /usr/local/bin/websocat -L https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl; sudo chmod a+x /usr/local/bin/websocat

# 4) Check your configuration and make sure your env. variables are correct
make echo

# 5) Generate Bluesky secret keys
make genSecrets
```

### <a id="ops1-prepare"/>1) Prepare your network

1) Create DNS A-Records for your self-hosting network.<br>

The following two A-Records are required.<br>
Refer to [appendix](#sample-dns-config) for a sample DNS server(bind9) configuration.

```
     -    ${DOMAIN}
     -  *.${DOMAIN}
```

2) Generate and install the CA Certificate (For private networks and self-signed certificates)
    -  After generating, copy root.crt and root.key in ./certs/root.{crt,key}
    -  Note: Don't forget to install root.crt to your host machine and browser.

How to generate a self-signed certificate:
```
# Generate and store self-signed CA certificate into ./certs/root.{crt,key} using the provided Caddy docker container.
make getCAcert
# Install the CA cert on the host machine.
make installCAcert

# Don't forget to install certificate to your browser.
```

### <a id="ops2-check"/>2) Check if Bluesky is ready to be deployed.

```bash
# Check if your DNS is registered properly. These commands should return your host machines IP.
dig  ${DOMAIN}
dig  any.${DOMAIN}

# Start the test containers.
make    docker-start f=./docker-compose-debug-caddy.yaml services=

# Test HTTPS and WSS with your docker environment.
curl -L https://test-wss.${DOMAIN}/
websocat wss://test-wss.${DOMAIN}/ws

# Test if the reverse proxy is properly mapped/configured for Bluesky
#  These should redirect to the Personal Data Server (PDS)
curl -L https://pds.${DOMAIN}/xrpc/any-request | jq
curl -L https://some-hostname.pds.${DOMAIN}/xrpc/any-request | jq

#  These should redirect to the Bluesky social-app.
curl -L https://pds.${DOMAIN}/others | jq
curl -L https://some-hostname.pds.${DOMAIN}/others | jq

# Stop the test containers and remove the created docker volumes and data
make    docker-stop-with-clean f=./docker-compose-debug-caddy.yaml
```
=> If all the tests ran successfully proceed to the next step, otherwise check your environment variables, certs, and dependencies.


### <a id="ops3-run"/>3) Deploy the Bluesky stack on your machine.

This section covers deploying the Bluesky stack with pre-built docker images.<br>
[Building from source](#hack-clone-and-build) is covered later in this guide.

```bash
# 0) Pull the pre-built docker images from docker.io to skip building images from source
make docker-pull

# 1) Deploy the required containers (Caddy, Database, etc)
make docker-start

# Wait until the log messages stop

# 2) Deploy the Bluesky containers (Appview, BGS, ozone, PDS, etc)
make docker-start-bsky

# This step is no longer needed after patching/152-indigo-newpds-dayper-limit.diff
# 3) Set bgs parameter for perDayLimit via REST API.
# ~~~ make api_setPerDayLimit ~~~
```

### <a id="ops4-run-fg"/>4) Deploy the feed-generator in the stack.

```bash
# 1) Check if the social-app is up and ready.
curl -L https://social-app.${DOMAIN}/

# 2) Create the feed-generator account
make api_CreateAccount_feedgen

# 3) Start the feed-generator
make docker-start-bsky-feedgen  FEEDGEN_PUBLISHER_DID=did:plc:...

# 4) Announce the existence of the feed to the stack ( by scripts/publishFeedGen.ts on feed-generator).
make publishFeed
```

### <a id="ops4-run-ozone"/>4-2) Deploy ozone in the stack

```bash
# 1) Create an account for the ozone service/admin
#  You need to use a valid email address because ozone/PDS sends a confirmation email.
make api_CreateAccount_ozone                    email=your-valid@email.address.com handle=...

# 2) start ozone
# ozone uses the same DID for  OZONE_SERVER_DID and OZONE_ADMIN_DIDS, at [HOSTING.md](https://github.com/bluesky-social/ozone/blob/main/HOSTING.md)
make docker-start-bsky-ozone  OZONE_SERVER_DID=did:plc:  OZONE_ADMIN_DIDS=did:plc:

# 3) Start the workaround tool to index label assignments into the appview DB via subscribeLabels.
# ./ops-helper/apiImpl/subscribeLabels2BskyDB.ts --help
./ops-helper/apiImpl/subscribeLabels2BskyDB.ts

# 4) [Required occasionaly] update DidDoc before signing in to ozone (required since build asof-2024-07-05)
#    First request and get PLC sign by email
make api_ozone_reqPlcSign                       handle=... password=...
#    update didDoc with above sign
make api_ozone_updateDidDoc   plcSignToken=     handle=...  ozoneURL=...

# 5) [Optional] Add member to the ozone team (i.e: add role to user):
#    valid roles are: tools.ozone.team.defs#roleAdmin | tools.ozone.team.defs#roleModerator | tools.ozone.team.defs#roleTriage
make api_ozone_member_add   role=  did=did:plc:
```

### <a id="ops4-run-jetstream"/>4-3) Deploy jetstream in the stack.
```bash
make docker-start-bsky-jetstream
```


### <a id="ops5-play"/>5) Try out the self-hosted Bluesky stack.

In your browser visit ```https://social-app.${DOMAIN}/```. Example: ```https://social-app.mysky.local.com/```

Refer to [screenshots](./docs/screenshots) for UI operations to create/sign-in to your account on your self-hosted bluesky.

### <a id="ops5-play-jetstream"/>5-1) Subscribe to jetstream

```bash
# Subscribe to almost all collections from jetstream
websocat "wss://jetstream.${DOMAIN}/subscribe?wantedCollections=app.bsky.actor.profile&wantedCollections=app.bsky.feed.like&wantedCollections=app.bsky.feed.post&wantedCollections=app.bsky.feed.repost&wantedCollections=app.bsky.graph.follow&wantedCollections=app.bsky.graph.block&wantedCollections=app.bsky.graph.muteActor&wantedCollections=app.bsky.graph.unmuteActor"
```

### <a id="ops5-play-ozone"/>5-2) Try out ozone (moderation) in the self-hosted Bluesky stack.

In your browser visit ```https://ozone.${DOMAIN}/configure``` Example: ```https://ozone.mysky.local.com/configure```

### <a id="ops6-stop"/>6) Stop all containters and bring down the stack

```bash
# Option 1) Shutdown the containers but have your data persist
make docker-stop

# Option 2) Shutdown the containers and wipe your data.
make docker-stop-with-clean
```

[back to top](#top)
## <a id="hack"/>Hacks

### <a id="hack-ops-CreateAccount"/>Create accounts in Bluesky easily

```bash
export u=foo
make api_CreateAccount handle=${u}.pds.${DOMAIN} password=${u} email=${u}@example.com resp=./data/accounts/${u}.secrets

# To make another account re-assign $u and re-enter the above commands like below.
export u=bar
!make

export u=baz
!make
```

### <a id="hack-clone-and-build"/>Build docker images from source by yourself

After [configuring your stack](#ops0-configparams) and [optional env](#hack-ops-development),
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

When you set the fork_repo_prefix variable before cloneAll it registers your remote fork repository with ```git remote add fork ....```
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
cat ./docker-compose-builder.yaml | ./ops-helper/compose2envtable/main.py -l /tmp/envs.txt -o ./docs/env-container-val.xlsx
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
| jetstream      | https://github.com/bluesky-social/jetstream.git        |

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
