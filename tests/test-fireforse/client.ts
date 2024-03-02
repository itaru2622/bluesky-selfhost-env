#!/usr/bin/env ts-node

/*
**  requires atproto-firehose https://github.com/kcchu/atproto-firehose/tree/main
**

#############  ops to use: >>>>>>

yarn add atproto-firehose
npm install ts-node -g
export ATP_FIREHOSE_HOST=bgs.${DOMAIN}

./clients.ts
############# ops to use: <<<<<<

**
*/

import { subscribeRepos, SubscribeReposMessage, ComAtprotoSyncSubscribeRepos, } from 'atproto-firehose'

let FIREHOSE_HOST  = process.env['ATP_FIREHOSE_HOST'] || "bsky.network";

async function main()
{
    if ( FIREHOSE_HOST.includes('://')==false ) {
         FIREHOSE_HOST="wss://" + FIREHOSE_HOST
         console.log(FIREHOSE_HOST)
    }
    const client = subscribeRepos(FIREHOSE_HOST, { decodeRepoOps: true })
    client.on('message', (tmp: SubscribeReposMessage) => {
      if (ComAtprotoSyncSubscribeRepos.isCommit(tmp)) {
        tmp.ops.forEach((m) => { console.log(m.payload) })
      }
    })
}

console.log(FIREHOSE_HOST)
main()
