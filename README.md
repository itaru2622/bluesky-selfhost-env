# <a id="top"/>self-hosting entire bluesky

https://github.com/itaru2622/bluesky-selfhost-env

## Contents:
  - [Motivation](#motivation)
  - [Current Status](#status)
  - [Operations for self-hosting bluesky](#ops)
      - [configuration](#ops0-configparams)
      - [prepare your network](#ops1-prepare)
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
  - [References](#refs)

## <a id="motivation" />Motivation

This repository aims to get self-hosted a bluesky environment easy, with:

 - Configurable hosting domain: easily tuned by environment variable (${DOMAIN}).
 - Reproducibility: full disclosure of all configurations and operations, including reverse proxy rules and patches to the original code of bluesky-social.
 - Simplicity: all bluesky components run on one host, powered by docker-compose.
 - Minimal remapping: the simplest possible mapping rules between FQDN, reverse proxy, and docker-container, for easy understanding and tuning.

Currently, my latest release is <strong>2025-11-01</strong>, based on the <strong>2025-11-01</strong> code from bluesky-social.<br>

### Special notes about big impact changes in upstream regarding selfhost

- changes in Aug-Sep 2025, atproto-proxy(bluesky proxy header) is required by social-app, which value can tune only at build time.
  It breaks 'build once, run with any domain' manner on this tool, and the manner is recovered by involving local static CDN in social-app container.
  this technique is inspired from STATIC_CDN_HOST in social-app(bskyweb) codes.
  to achieve it, social-app got some patches for bskyweb + Dockerfile + additional shell command and docker-compose*.yaml.<br>
   - in docker-compose-build.yaml, EXPO_PUBLIC_BLUESKY_PROXY_DID=@@EXPO_PUBLIC_BLUESKY_PROXY_DID@@ as build arg, to embed placeholder(mark) within js files.
   - on booting phase at runtime, it rewrites placeholder with real val by runtime env EXPO_PUBLIC_BLUESKY_PROXY_DID=did:web:..., before being used by social-app.
   - refer comments in docker-compose.yaml for detail.

## <a id="status"/>Current status regarding self-hosting

As shown below, most features work as expected in the self-hosting environment.<br>
Unfortunately, some features may not work correctly; the reasons for this are described in https://github.com/bluesky-social/atproto/discussions/2334<br>

Test results with 'asof-2024-06-02' and later:<BR>

   -  ok: Create account on pds (via social-app, bluesky API).
   -  ok: Basic usages on social-app
       -  ok: Sign in, edit profile, post/repost articles, search posts/users/feeds, vote like/follow.
       -  ok: Receive notifications when others vote like/follow you.
       -  ok: Subscribe/unsubscribe to labeler in profile page.
       -  ok: Report to labeler for any post.
       -  not yet: DM(chat) with others.
   -  ok: Integrate with [feed-generator](https://github.com/bluesky-social/feed-generator) NOTE: it has some delay, reload on social-app.
   -  ok: Moderate with [ozone](https://github.com/bluesky-social/ozone).
       -  ok: Sign in and configure labels on ozone-UI.
       -  ok: Receive the report sent by user.
       -  ok: Assign label to the post/account on ozone-UI, then events published to subscribeLabels.
       -  ok: The view of post changes on social-app when using [workaround tool](https://github.com/itaru2622/bluesky-selfhost-env/blob/master/ops-helper/apiImpl/subscribeLabels2BskyDB.ts).
          -  NOTE: without workaround tool, the view is not changed. refer https://github.com/bluesky-social/atproto/issues/2552
   -  ok: Subscribe to events from pds/bgs(relay)/ozone by firehose/websocket.
   -  ok: Subscribe to events from jetstream, since 2024-10-19r1
   -  not yet: Others.

[back to top](#top)
## <a id="ops"/>Operations for self-hosting bluesky (powered by Makefile)

The following operations assume that the self-hosting domain is <strong>mysky.local.com</strong> (defined in Makefile).<br>
You can change the domain name by setting the environment variable as follows:

### <a id="ops0-configparams"/>0) Configure params and install tools for ops

```bash
### <a id="ops0-configparams"/>0) Configure parameters and install tools

```bash
# 1) Set domain name for self-hosting bluesky
export DOMAIN=whatever.yourdomain.com

# 2) Set 'asof' date (YYYY-MM-DD or 'latest') to select docker images and sources.
#    Example: 2025-11-01 (latest prebuild) or 'latest' (following docker image naming).
export asof=2025-11-01

# 3) Set email addresses:

# 3-1) EMAIL4CERTS: for Let's Encrypt certificate signing.
export EMAIL4CERTS=your@mail.address
# Use 'internal' (reserved) for self-signed certificates to avoid rate limits during setup.
export EMAIL4CERTS=internal

# 3-2) PDS_EMAIL_SMTP_URL: for PDS (e.g., smtps://youraccount:your-app-password@smtp.gmail.com)
export PDS_EMAIL_SMTP_URL=smtps://

# 3-3) FEEDGEN_EMAIL: for feed-generator account.
export FEEDGEN_EMAIL=feedgen@example.com

## Install required tools (if missing).
apt install -y make pwgen
(cd ops-helper/apiImpl ; npm install)
(sudo curl -o /usr/local/bin/websocat -L https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl; sudo chmod a+x /usr/local/bin/websocat)

# 4) Check configuration.
make echo

# 5) Generate and check container secrets.
make genSecrets
```

### <a id="ops1-prepare"/>1) Prepare your network

1) Create DNS A-Records in your self-hosting network.<BR>

At a minimum, you will need the following two A-Records.<BR>
Refer the [appendix](#sample-dns-config) for a sample DNS server (bind9) configuration.

```
     -    ${DOMAIN}
     -  *.${DOMAIN}
```

2) Generate and install a CA certificate (necessary for private/closed networks and when working with self-signed certificates).
    -  Once generated, copy the crt and key files to ./certs/root.{crt,key}
    -  Important: Install root.crt on your host machine and within your browser.
Follow the steps below to easily obtain self-signed CA certificates:

```
# Get and store the self-signed CA certificate into ./certs/root.{crt,key} with caddy.
make getCAcert
# Install the CA certificate on the host machine.
make installCAcert

# Remember to install the certificate in your browser.
```

### <a id="ops2-check"/>2) Check if it's ready to self-host bluesky

```bash
# Check DNS server responses for your self-hosting domain
dig  ${DOMAIN}
dig  any.${DOMAIN}

# Check if DNS works as expected. Test from all nodes you want to access your self-hosting bluesky, including host and client machines.
ping ${DOMAIN}
ping any.${DOMAIN}

# Start containers for testing
make    docker-start f=./docker-compose-debug-caddy.yaml services=

# Test HTTPS and WSS with your docker environment
curl -L https://test-wss.${DOMAIN}/
websocat wss://test-wss.${DOMAIN}/ws

# Test reverse proxy mapping to ensure it works as expected for bluesky
#  These should redirect to PDS
curl -L https://pds.${DOMAIN}/xrpc/any-request | jq
curl -L https://some-hostname.pds.${DOMAIN}/xrpc/any-request | jq

#  These should redirect to social-app
curl -L https://pds.${DOMAIN}/others | jq
curl -L https://some-hostname.pds.${DOMAIN}/others | jq

# Stop test containers, without persisting data
make    docker-stop-with-clean f=./docker-compose-debug-caddy.yaml
```

=> If testOK, then go ahead; otherwise, examine your environment.

### <a id="ops3-run"/>3) Deploy bluesky

This section first outlines deploying bluesky with prebuilt images.<BR>
Refer [later](#hack-clone-and-build) for instructions on building images from sources independently.

```bash
# 0) Pull prebuilt docker images from docker.io to explicitly avoid building images.
make docker-pull

# 1) Deploy the essential containers (database, caddy, etc.).
make docker-start

# Wait for log messages to cease.

# 2) Deploy the core bluesky containers (plc, bgs, appview, pds, ozone, ...).
make docker-start-bsky

# The operation below is obsolete due to patching/152-indigo-newpds-dayper-limit.diff
# 3) Configure the bgs parameter for the perDayLimit setting using the REST API.
# ~~~ make api_setPerDayLimit ~~~
```

### <a id="ops4-run-fg"/>4) Deploy the Feed Generator

```bash
# 1) Verify that the social-app is ready to serve content.
curl -L https://social-app.${DOMAIN}/

# 2) Generate an account specifically for the feed generator.
make api_CreateAccount_feedgen

# 3) Launch the bluesky feed-generator.
make docker-start-bsky-feedgen  FEEDGEN_PUBLISHER_DID=did:plc:...

# 4) Publish the feed's existence (using scripts/publishFeedGen.ts on the feed-generator).
make publishFeed
```

### <a id="ops4-run-ozone"/>4-2) Deploy Ozone

```bash
# 1) Generate an account for the ozone service or administrator.
#  A working email address is essential, as ozone/PDS will send a confirmation code to it.
make api_CreateAccount_ozone                    email=your-valid@email.address.com handle=...

# 2) Launch Ozone
# Ozone uses the same DID for both OZONE_SERVER_DID and OZONE_ADMIN_DIDS, as documented in [HOSTING.md](https://github.com/bluesky-social/ozone/blob/main/HOSTING.md)
make docker-start-bsky-ozone  OZONE_SERVER_DID=did:plc:  OZONE_ADMIN_DIDS=did:plc:

# 3) Run the workaround tool to index label assignments into the appview DB through subscribeLabels.
# ./ops-helper/apiImpl/subscribeLabels2BskyDB.ts --help
./ops-helper/apiImpl/subscribeLabels2BskyDB.ts

# 4) [Required occasionally] Refresh the DidDoc prior to ozone sign-in (required since asof-2024-07-05)
#    First, request and get PLC signature by email
make api_ozone_reqPlcSign                       handle=... password=...
#    Then, update the didDoc using obtained signature
make api_ozone_updateDidDoc   plcSignToken=     handle=...  ozoneURL=...

# 5) [Optional] Invite a new member to the ozone team (by assigning a role):
#    Valid roles are: tools.ozone.team.defs#roleAdmin | tools.ozone.team.defs#roleModerator | tools.ozone.team.defs#roleTriage
make api_ozone_member_add   role=  did=did:plc:
```

### <a id="ops4-run-jetstream"/>4-3) Deploy Jetstream
```bash
make docker-start-bsky-jetstream
```


### <a id="ops5-play"/>5) Play with self-hosted blusky.

Access ```https://social-app.${DOMAIN}/``` (e.g., ```https://social-app.mysky.local.com/```) in your browser.

See the [screenshots](./docs/screenshots) for instructions on creating or signing in to an account.

### <a id="ops5-play-jetstream"/>5-1) Subscribe Jetstream

```bash
# Subscribe almost all collections from jetstream
websocat "wss://jetstream.${DOMAIN}/subscribe?wantedCollections=app.bsky.actor.profile&wantedCollections=app.bsky.feed.like&wantedCollections=app.bsky.feed.post&wantedCollections=app.bsky.feed.repost&wantedCollections=app.bsky.graph.follow&wantedCollections=app.bsky.graph.block&wantedCollections=app.bsky.graph.muteActor&wantedCollections=app.bsky.graph.unmuteActor"
```

### <a id="ops5-play-ozone"/>5-2) Play with ozone (moderation)

Access ```https://ozone.${DOMAIN}/configure``` (e.g., ```https://ozone.mysky.local.com/configure```) in your browser.

### <a id="ops6-stop"/>6) Stop all containters

```bash
# Choice 1: Shut down containers, retaining data.
make docker-stop

# Choice 2: Shut down containers and delete the data.
make docker-stop-with-clean
```

[back to top](#top)
## <a id="hack"/>Hack

### <a id="hack-ops-CreateAccount"/>Create accounts on your bluesky easily

```bash
export u=foo
make api_CreateAccount handle=${u}.pds.${DOMAIN} password=${u} email=${u}@example.com resp=./data/accounts/${u}.secrets

# To create more accounts, simply re-assign $u and call the above operation, as shown below.
export u=bar
!make

export u=baz
!make
```

### <a id="hack-clone-and-build"/>Build docker images from sources yourself

After configuring the [parameters](#ops0-configparams) and [optional environment variable](#hack-ops-development), proceed as follows:

```bash
# Get source code from all repositories
make    cloneAll

# Create work branches and stay on them for all repositories (repos/*); optional but recommended for safety.
make    createWorkBranch
```

Then, build the docker images as follows:

```bash
# 0) Apply the minimum necessary patch to build images, regardless of self-hosting.
#    See https://github.com/bluesky-social/atproto/discussions/2026 for details, specifically for feed-generator/Dockerfile etc.
# NOTE: This operation will create a new branch, apply the patch, and stay on that new branch.
make patch-dockerbuild

# 1) Build the images
make build DOMAIN= f=./docker-compose-builder.yaml
```

[back to top](#top)
### <a id="hack-ops-development"/>Streamlined Development Using Your Remote Fork Repository

By setting the fork_repo_prefix variable before cloneAll, it registers your remote fork repository with `git remote add fork ....`
then you have additional easy operations against multiple repositores, as below.

```bash
export fork_repo_prefix=git@github.com:YOUR_GITHUB_ACCOUNT/

make cloneAll

# Easily manage (push and pull) branches and tags for all repositories with a single command targeting your remote fork repositories.
make exec under=./repos/* cmd='git push fork branch'
make exec under=./repos/* cmd='git tag -a "asof-XXXX-XX-XX" '
make exec under=./repos/* cmd='git push fork --tags'

# Push your develop-branch in justOneRepo working folder to your remote fork repository.
make exec under=./repos/justOneRepo cmd='git push fork develop-branch'

# See the Makefile for complete details and usage examples.
```

[back to top](#top)
### <a id="hack-EnvVars-Compose"/>Check Env Vars in docker-compose

1) Get all env vars in docker-compose

```bash
# Names and their values
_yqpath='.services[].environment, .services[].build.args'
_yqpath='.services[].environment'

# List of var=val
cat ./docker-compose-builder.yaml | yq -y "${_yqpath}" \
  | grep -v '^---' | sed 's/^- //' | sort -u -f

# Output in yaml
cat ./docker-compose-builder.yaml | yq -y "${_yqpath}" \
  | grep -v '^---' | sed 's/^- //' | sort -u -f  \
  | awk -F= -v col=":" -v q="'" -v sp="  " -v list="-" '{print   sp list sp q $1 q col sp q $2 q}' \
  | sed '1i defs:' | yq -y


# List of names
cat ./docker-compose-builder.yaml | yq -y "${_yqpath}" \
  | grep -v '^---' | sed 's/^- //' | sort -u -f \
  | awk -F= '{print $1}' | sort -u -f
```

2) Get env vars regarding {URL | DID | DOMAIN} == mapping rules in docker-compose

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

3) Get mapping rules in reverse proxy (caddy )

```bash
# dump rules, no idea to convert into  easy readable format...
cat config/caddy/Caddyfile
```

[back to top](#top)
### <a id="hack-EnvVars-Sources"/>Check Env Vars in sources

1) Get files related env vars in sources

```bash
# Files named *env*
find repos -type f | grep -v -e /.git/  | grep -i env \
  | grep -v -e .jpg$ -e .ts$  -e .json$ -e .png$ -e .js$

# Files containing 'export'
find repos -type f | grep -v /.git/  | xargs grep -l export \
  | grep -v -e .js$ -e .jsx$  -e .ts$ -e .tsx$ -e .go$ -e go.sum$ -e go.mod$ -e .po$ -e .json$ -e .patch$ -e .lock$ -e .snap$
```

2) Get all env vars from source code

```bash
# In an easy way
_files=repos
# Ensure files to search for envs
_files=`find repos -type f | grep -v -e '/.git' -e /__  -e /tests/ -e _test.go -e /interop-test-files  -e /testdata/ -e /testing/ -e /jest/ -e /node_modules/ -e /dist/ | sort -u -f`

# For JavaScripts families, get env vars from process.env.ENVNAME
grep -R process.env ${_files} \
  | cut -d : -f 2- | sed 's/.*process\.//' | grep '^env\.' | sed 's/^env\.//' \
  | sed -r 's/(^[A-Za-z_0-9\-]+).*/\1/' | sort -u -f \
  | tee /tmp/vars-js1.txt

# For JavaScripts families, get env vars from envXXX('MORE_ENVNAME'), Refer to atproto/packages/common/src/env.ts for envXXX
grep -R -e envStr -e envInt -e envBool -e envList ${_files} \
  | cut -d : -f 2- \
  | grep -v -e ^import -e ^export -e ^function  \
  | sed "s/\"/'/g" \
  | grep \' | awk -F\' '{print $2}' | sort -u -f \
  | tee /tmp/vars-js2.txt

# For golang, get env vars from EnvVar(s): []string{"ENVNAME", "MORE_ENVNAME"}
grep -R EnvVar ${_files} \
  | cut -d : -f 3- | sed -e 's/.*string//' -e 's/[,"{}]//g' \
  | tr ' ' '\n' | grep -v ^$ | sort -u -f \
  | tee /tmp/vars-go.txt

# for docker-compose, get env vars from services[].environment
echo {$_files} \
  | tr ' ' '\n' | grep -v ^$ | grep -e .yaml$ -e .yml$ | grep compose \
  | xargs yq -y .services[].environment | grep -v ^--- | sed 's/^- //' \
  | sed 's/: /=/' | sed "s/'//g" \
  | sort -u -f \
  | awk -F= '{print $1}' | sort -u -f \
  | tee /tmp/vars-compose.txt


# Get unique lists
cat /tmp/vars-js1.txt /tmp/vars-js2.txt /tmp/vars-go.txt /tmp/vars-compose.txt | sort -u -f > /tmp/envs.txt

# Pick env vars related to mapping {URL, ENDPOINT, DID, HOST, PORT, ADDRESS}
cat /tmp/envs.txt  | grep -e URL -e ENDPOINT -e DID -e HOST -e PORT -e ADDRESS
```

3) Find {URL | DID | bsky } near env names in sources

```bash
find repos -type f | grep -v -e /.git  -e __ -e .json$ \
  | xargs grep -R -n -A3 -B3 -f /tmp/envs.txt \
  | grep -A2 -B2 -e :// -e did: -e bsky
```

4) Find bsky.{social, app, network} in sources (to check hard-coded domain/FQDN)

```bash
find repos -type f | grep -v -e /.git -e /tests/ -e /__ -e Makefile -e .yaml$ -e .md$  -e .sh$ -e .json$ -e .txt$ -e _test.go$ \
  | xargs grep -n -e bsky.social -e bsky.app -e bsky.network  -e bsky.dev
```

[back to top](#top)
### <a id="hack-EnvVars-Table"/>Create a table showing {env x container => value} from source and docker-compose.

This task uses the result(/tmp/envs.txt) of [the above](#hack-EnvVars-Sources) as input.

```bash
# Create table showing { env x container => value } with the ops-helper script.
cat ./docker-compose-builder.yaml | ./ops-helper/compose2envtable/main.py -l /tmp/envs.txt -o ./docs/env-container-val.xlsx
```

[back to top](#top)
### <a id="hack-self-signed-certs"/>Regarding self-signed certificates x HTTPS x containers.

This self-hosting env tries to use self-signed certificates as trusted certificates by installing them into containers.
The expected behavior is that by sharing /etc/ssl/certs/ca-certificates.crt amang all containers, containers can distinguish that those in ca-certificates.crt are trusted.

Unfortunately, this approach works just in some containers, but not all.
It seems depending on distribution(Debian/Alpine/...) and language(Java/Node.js/Golang). The rule cannot be determined in actual behaviors.
Therefore, all of the methods below are involved for safety when using self-signed certificates.

- The host deploys /etc/ssl/certs/ca-certificates.crts to containers by volume mount.
- Define env vars for self-signed certificates, such as GOINSECURE, NODE_TLS_REJECT_UNAUTHORIZED for each language.


[back to top](#top)
## <a id="appendix"/>Appendix

### <a id="screenshots"/>Screen shots:

| Create account | Sign-in|
|:---|:---|
|<img src="./docs/screenshots/1-bluesky-create-account.png" style="height:45%; width:45%">|<img src="./docs/screenshots/1-bluesky-sign-in.png"  style="height:45%; width:45%">|
|<img src="./docs/screenshots/2-bluesky-choose-server.png"  style="height:45%; width:45%">|<img src="./docs/screenshots/2-bluesky-choose-server.png"  style="height:45%; width:45%">|
|<img src="./docs/screenshots/3-bluesky-create-account.png"  style="height:45%; width:45%">|<img src="./docs/screenshots/3-bluesky-sign-in.png"  style="height:45%; width:45%">|

### <a id="sources"/>Sources in use:

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

Description of test network:

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

The above would be described in bind9 configuration file as below:

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

cf. The simplest way to use the above DNS server(192.168.1.27) temporaly is<br>
to add it to /etc/resolv.conf as shown below on all testing machines
(docker host, client machines for browsers)

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
