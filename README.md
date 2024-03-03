# self-hosting bluesky 

this repository describes the way to self-host bluesky with

 - configurable hosting domain:  easy to tunable by environment variable (DOMAIN)
 - reproducibility: disclosure all configs and operations, including reverse proxy rules.
 - simple:          all bluesky components runs on one host, by docker-compose.
 - less remapping:  simple rules as possible, among FQDN <=> reverse proxy <=> docker-container, for easy understanding and tunning.

at current, working with code asof 2024-01-06 of bluesky-social.<br>
it may not work with latest codes.

## references

special thanks to prior works on self-hosting.
   - https://github.com/bluesky-social/atproto/discussions/2026 and https://syui.ai/blog/post/2024/01/08/bluesky/
   - https://github.com/ikuradon/atproto-starter-kit/tree/main

## sources in use.

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


## operations (powered by Makefile)

below, it assumes self-hosting domain is mybluesky.local.com (defined in Makefile).<br>
you can overwrite the domain name by environment variable as below:

0) configure params for ops

```bash
# 1) set domain name for self-hosting bluesky
export DOMAIN=whatever.yourdomain.com

# 2) set asof daytime, for bluesky-social codes (current testing with 2024-01-06)
export asof=2024-01-06

# 3) set PDS_EMAIL_SMTP_URL like smtps://yourmail:password@smtp.gmail.com
export PDS_EMAIL_SMTP_URL=smtps://

# 4) check your configuration, from the point of view of ops.
make echo
```


1) get sources and checkout by DayTime(2024-01-06)

```bash
# get sources from all repositories
make    cloneAll

# checkout codes according to asof param, for all sources.
make   mkBranch_asof branch=work
```


2) prepare on your network

```
2.1) make DNS A-Records for your self-hosting domain, at least:
     -    ${DOMAIN}
     -  *.${DOMAIN}

2.2) generate and install CA certificate (for self-signed certificate)
     -  after generation, copy crt and key as ./certs/root.{crt,key}
     -  note: don't forget to install root.crt to your host machine and browser.
```

3) check if it's ready to self-host bluesky.

```bash
# check DNS server responses for your self-host domain
dig  ${DOMAIN}
dig  any.${DOMAIN}

# start containers for test
make    docker-start f=./docker-compose-debug-caddy.yaml services=

# test HTTPS and WSS with your docker environment
curl -L https://test-ws.${DOMAIN}/
open -L https://test-ws.${DOMAIN}/ on browser.

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


4) build docker images, to prepare self-hosting...

```bash
# 4.0) apply mimimum patch for self-docker-image-build, regardless self-hosting.
#      as described in https://github.com/bluesky-social/atproto/discussions/2026 for feed-generator/Dockerfile etc.
# NOTE: this ops checkout new branch before applying patch, and keep staying new branch
make patch-dockerbuild

# 4.1) build images with original
make build DOMAIN=

# 4.2) apply patch for self-hosting
#      as described in https://syui.ai/blog/post/2024/01/08/bluesky/
# NOTE: this ops checkout new branch before applying patch, and keep staying new branch
make patch-selfhost

# 4.3) build social-app for self-hosting...
make build services=social-app
```

5) run bluesky with selfhosting

```bash
# generate passwords for bluesky containers, and check those value:
make genPass

# start required containers (database, caddy etc).
make docker-start

# wait until log message becomes silent.

# start bluesky containers, finally...
make docker-start-bsky
```

6) run bluesky feed-generator
```bash
# check if social-app is ready to serve.
curl -L https://social-app.${DOMAIN}/

# create account for feed-generator
make api_CreateAccount_feedgen

# find feedgen DID in the above response.
cat ${aDir}/feedgen.secrets | jq .did | sed 's/"//g'
>did:plc:6xki...

# start boosky feed-generator
make docker-start-bsky-feedgen  FEEDGEN_PUBLISHER_DID=did:plc:6xki...
```

## play with self-hosted blusky.

on your browser, access ```https://social-app.${DOMAIN}/``` such as ```https://social-app.mybluesky.local.com/```

## stop all containters

```bash
make docker-stop
```

## DNS server configuration sample (bind9)

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

## Hack

1) get mapping rules in docker-compose

```bash
cat ./docker-compose-starter.yaml | grep {DOMAIN} | sed 's/^ .*- //' | grep -v \# | grep -v image: | sort -u
```

2) get mapping rule in reverse proxy (caddy )
```bash
# dump rules, no idea to convert into  easy reading format...
cat config/caddy/Caddyfile
```

2) create accounts in easy

```bash
export u=foo
make api_CreateAccount handle=${u} password=${u} email=${u}@example.com resp=${aDir}/${u}.secrets

#then, to make other account, just re-assign $u and call the above, like below.
export u=bar
make api_CreateAccount handle=${u} password=${u} email=${u}@example.com resp=${aDir}/${u}.secrets

export u=baz
make api_CreateAccount handle=${u} password=${u} email=${u}@example.com resp=${aDir}/${u}.secrets
```
