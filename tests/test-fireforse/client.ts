#!/usr/bin/env ts-node

/*
**  requires atproto-firehose https://github.com/kcchu/atproto-firehose/tree/main
**

npm install atproto-firehose yargs @types/yargs
npm install ts-node -g
./clients.ts --help
./clients.ts

**
*/

import { subscribeRepos, SubscribeReposMessage, ComAtprotoSyncSubscribeRepos, } from 'atproto-firehose'
import yargs            from 'yargs/yargs';

async function main(opt: any)
{
    const client = subscribeRepos(opt.host, { decodeRepoOps: true })
    client.on('message', (tmp: SubscribeReposMessage) => {
        console.log(tmp)
        if (tmp.ops != undefined && Array.isArray(tmp.ops))
           tmp.ops.forEach((op) => { console.log("ops.payload:=>", op.payload) })
//      if (ComAtprotoSyncSubscribeRepos.isCommit(tmp)) { console.log("commit") }
    })
}

const opt = yargs(process.argv.slice(2)).options({
  host:        { type: 'string', default: process.env.DOMAIN ? `wss://relay.${process.env.DOMAIN}` : 'wss://bsky.network', description: 'URL to subscribeRepos' },
  tls:         { type: 'string', default: '0', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)'},
}).parseSync();

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls
console.log(opt.host)
main(opt)
