#!/usr/bin/env tsx

/*
** find ozone service endpoint via subscribeRepos
*/


import { Subscription }                    from '@atproto/xrpc-server'
import { IdResolver, MemoryCache }         from '@atproto/identity'
import { getServiceEndpoint, DidDocument } from '@atproto/common'
import yargs                               from 'yargs/yargs';

// TODO: use official typedef with lexicon base, atproto/packages/api/src/client/types/com/atproto/...
interface EvObject {
 [key: string]: any;
}

// receive events => dispatch them to handler
const run = async function(sub: Subscription)
{
   for await (const ev of sub) {
      try {
         await handleEvent(ev as EvObject)
      } catch (e){
         console.log('###### got error', e)
      }
   }
}

// find event relatd to ozone service URL endpoint
const handleEvent = async function(ev: EvObject) {

    if ( (ev['$type'] != 'com.atproto.sync.subscribeRepos#commit') || (ev.ops == undefined) ) {
      console.log('# ev != commit||ops ==> ignore')
      return
    }

    // check ev.opts if laberler.service exists...
    const labeler = ( ev.ops.find( (op:any) => op.path=='app.bsky.labeler.service/self' ) != undefined );
    if (labeler == false) {
       console.log('# ev == commit, ! labeler ==> ignore')
      return
    }

    // found event regarding to labeler => get its service endpoint (DID: ev.repo).
    const endpoint = await did2ServiceEndpoint( ev.repo, '#atproto_labeler')
    console.log ("#### Commit event(labeler):", ev.repo, " => ",  endpoint )
}

//get service endpoint from did via didDoc
const did2ServiceEndpoint = async function(did: string, serviceId: string) {

    const doc  = await idResolver.did.resolve(did)
    return getServiceEndpoint(doc as DidDocument, { id: serviceId })
}

// =========================================================================
const dom = process.env.DOMAIN ?? 'mysky.local.com'

// options to support any deployment.
const opt = yargs(process.argv.slice(2)).options({
  bgsURL:    { type: 'string', default: 'wss://bgs.' + dom },
  plcURL:    { type: 'string', default: 'https://plc.' + dom },
  tls:       { type: 'string', default: '0',          description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)'},
}).parseSync();

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls

const sub = new Subscription({
  service: opt.bgsURL,
  method:  'com.atproto.sync.subscribeRepos',
  getState: () => ({}),
  validate: (val: unknown) => val as object, // TODO: validate with lexicon
});

const didCache =   new MemoryCache()
const idResolver = new IdResolver({ plcUrl: opt.plcURL, didCache: didCache })
run(sub)

/* sample events:
 {
  ops: [
    {
      cid: CID(bafyreiesy2ybq4booyf5ztkwjqvijrklc7qyuu3kps7xqqcu26cxxxxo4m),
      path: 'app.bsky.labeler.service/self',
      action: 'create'
    }
  ],
  rev: '3kvb5iscdu22d',
  seq: 7,
  prev: null,
  repo: 'did:plc:6wo5pil66p4dqiqe5bu3pjtg', // DID of account
  time: '2024-06-19T07:08:29.032Z',
  blobs: [],
  since: '3kvb4wcy35s2d',
  blocks: <Buffer 3a a2 65 72 ,...>,
  commit: CID(bafyreihz5nw7s2phvtye3kehwcdj6ta7iogfkf6fefx6oeisgdjqkopfca),
  rebase: false,
  tooBig: false,
  '$type': 'com.atproto.sync.subscribeRepos#commit'
}

{
  ops: [
    {
      cid: CID(bafyreic3svjuk42wccjztvxv3s7lxb5pdjydvermpm5znk2ndiq7v2wxr4),
      path: 'app.bsky.labeler.service/self',
      action: 'update'
    }
  ],
  rev: '3kvb5ljfuzk2d',
  seq: 8,
  prev: null,
  repo: 'did:plc:6wo5pil66p4dqiqe5bu3pjtg',
  time: '2024-06-19T07:10:00.272Z',
  blobs: [],
  since: '3kvb5iscdu22d',
  blocks: <Buffer 3a a2 65 72 6f ,...>,
  commit: CID(bafyreibecowthjjmz3xs4nc4vqvdi4ylnmv2qpypasm5stzhcshdtesbmi),
  rebase: false,
  tooBig: false,
  '$type': 'com.atproto.sync.subscribeRepos#commit'
}

*/
