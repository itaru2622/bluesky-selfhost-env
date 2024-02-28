# bluesky selfhost environment

NOTE: testing with code asof 2024-01-06 of bluesky-social codes.
under investigating for recent codes.

## references

special thanks to below prior works on selfhosting.
   - https://github.com/bluesky-social/atproto/discussions/2026
   - https://syui.ai/blog/post/2024/01/08/bluesky/
   - https://github.com/ikuradon/atproto-starter-kit/tree/main

## source code to use

| components     | url (origin)                                           |
|----------------|--------------------------------------------------------|
| did-method-plc | https://github.com/did-method-plc/did-method-plc.git   |
| atproto        | https://github.com/bluesky-social/atproto.git          |
| indigo         | https://github.com/bluesky-social/indigo.git           |
| social-app     | https://github.com/bluesky-social/social-app.git       |
| caddy(revProxy)| official docker image of cady:2                        |
| bind9(DNS srv) | https://github.com/itaru2622/docker-bind9.git or others|


below ops assumes your self hosting domain is: mybluesky.local.com

## ops powered by Makefile

1) get codes and checkout by DayTime(2024-01-06)

```bash
# clone codes from all repos
make    cloneAll

# checkout codes asof 2024-01-06 for all sources.
make    mkBranch_asof asof=2024-01-06 branch=work
```


2) prepare for your network

```
2.1) make DNS A recods for your self hosting domain, at least:
     -    mybluesky.local.com
     -  *.mybluesky.local.com

2.2) prepare CA certificate (if self-signed )
     -  put it into ./certs/root.{crt,key}
     -  you also needs to deploy certificates to your hostmachine and browser.
```

3) test your network if it is ready to selfhost bluesky.

```bash
# check DNS server responses for your selfhost domain
dig  mybluesky.local.com
dig  any.mybluesky.local.com

# start containers for test
export  DOMAIN=mybluesky.local.com
make    docker-start f=docker-compose-debug-caddy.yaml Sdep=

# check HTTPS and WSS with your docker environment
curl https://test-caddy.mybluesky.local.com/
open https://test-ws.mybluesky.local.com/ on browser.

# stop test containers.
make    docker-stop f=docker-compose-debug-caddy.yaml
```
=> if testOK then go ahead, otherwise check your environment.


4) prepare selfhosting...

```bash
# 4.1) build docker images for bluesky (with original code)
DOMAIN= docker-compose -f docker-compose-starter.yaml build

# 4.2) apply patch (as described in https://syui.ai/blog/post/2024/01/08/bluesky/)
make patch-selfhost

# 4.3) build social-app for selfhosting...
make build-social-app
```

5) run bluesky with selfhosting

```bash
export  DOMAIN=mybluesky.local.com

# start required containers.
make docker-start f=./docker-compose-starter.yaml

# wait until log message becomes silent.

# start main containers.
make docker-start-bsky f=./docker-compose-starter.yaml
```

## play with https://social-app.mybluesky.local.com/  in your browser.

```bash
# stop all containers.
make docker-stop f=./docker-compose-starter.yaml
```

## sample of bind9 DNS server configuration

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
        forwarders        { 8.8.8.8 ; };  # { 8.8.8.8; };
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
