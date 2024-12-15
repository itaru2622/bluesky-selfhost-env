#!/usr/bin/env tsx

/*
**
** workaround to feed label assignments from ozone => bsky(appview) => social-app on self-hosting bsky.
** current published open source lacked above feature on bsky even though official hosting bluesky has.
** so, this tool subscribes labels and update bsky internal DB.
**
** required lib:
**   @atproto/xrpc-server @atproto/bsky yargs
**
** cf:
** - https://github.com/bluesky-social/atproto/blob/main/packages/bsky/src/data-plane/server/subscription/index.ts getSubscription()
** - https://github.com/bluesky-social/atproto/blob/main/packages/ozone/tests/3p-labeler.test.ts    adjustLabels()
** - https://github.com/bluesky-social/feed-generator/blob/main/src/util/subscription.ts
** - https://gist.github.com/devsnek/701047cdcf378bdd3a6c36c0a8085530
**
*/


import { Subscription } from '@atproto/xrpc-server'
import { Database }     from '@atproto/bsky'
import yargs            from 'yargs/yargs';

const dom = process.env.DOMAIN ?? 'mysky.local.com'

// options to support any deployment.
const opt = yargs(process.argv.slice(2)).options({
  endpoint:    { type: 'string', default: 'wss://ozone.' + dom },
  bskyDBUrl:   { type: 'string', default: process.env.BSKY_DB_POSTGRES_URL   || 'postgres://pg:password@localhost/bsky', description: 'appview postgresDB URL'},
  bskyDBSchema:{ type: 'string', default: process.env.BSKY_DB_POSTGRES_SCHEMA || 'bsky',                                     description: 'appview postgresDB Schema'},
  tls:         { type: 'string', default: '0',                                                                               description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)'},
}).parseSync();

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls

// TODO: use official typedef with lexicon base, atproto/packages/api/src/client/types/com/atproto/label/subscribeLabels.ts
interface EvObject {
 labels: Array<{[key: string]: any}> // array of map(string,any)
 [key: string]: any;                 // other entries
}

const sub = new Subscription({
  service: opt.endpoint,
  method:  'com.atproto.label.subscribeLabels',
  getState: () => ({}),
  validate: (val: unknown) => val as object, // TODO: validate with lexicon
});

// DB instance for bsky.
const db = new Database({
  url: opt.bskyDBUrl,
  schema: opt.bskyDBSchema,
  poolSize: 10,
})

// receive events => dispatch them to handler
const run = async function (sub: Subscription, db: Database) {
   for await (const ev of sub) {
      try {
         await handleEvent(ev as EvObject, db)
      } catch (e){
         console.log('###### got error', e)
      }
   }
}

// store events into label table on bsky DB
const handleEvent = async function (ev: EvObject, db: Database) {

    const type_ =  ev['$type']
    //console.log("###### event type:", type_, ev)

    if (type_ == "com.atproto.label.subscribeLabels#labels") {
        const body = ev['labels']

        // pickup fields to needs update, according to label table.
        const entries = body.map((ev) => ({
           'src': ev.src,
           'uri': ev.uri,
           'cid': ev.cid || '',
           'val': ev.val,
           'cts': ev.cts || new Date().toISOString(),
           'neg': ev.neg || false
        }))

        // classify entries by neg field => inserts / deletes
        const inserts = entries.filter( (val) => { return val.neg == false})
        const dels =    entries.filter( (val) => { return val.neg == true})

        if (inserts.length>0) {
           await db.db.insertInto('label').values(inserts).execute() 
           //console.log('### insert ev: ', inserts )
        }

        for (const d of dels) {
           // primary key of label Table: [src, uri, cid, val]
           await db.db.deleteFrom('label')
             .where('src','=',d.src).where('uri','=',d.uri).where('cid','=',d.cid).where('val','=',d.val)
             .execute() 
           //console.log('### del ev: ', d )
        }
    }
}

run(sub, db)

/* sample events:
{
  seq: 23,
  labels: [
    {
      cid: 'bafyreif42i43at3rwjjmawn7ujysyawmwvnquumooprlkexepgkm7p3l6q',
      cts: '2024-06-03T23:45:54.988Z',
      sig: <Buffer b2 3b 50 5f 6d 32 ea 00 c2 49 7a e5 0d 76 48 64 1e af 79 2a 0c 64 85 a3 d2 24 bc d0 12 9f 05 0d 7a 69 86 d8 8e f2 b0 1e 3b 8e 2a 50 a5 78 49 c0 de 22 ... 14 more bytes>,
      src: 'did:plc:g5gqnspblin52gmy4iexeswq',
      uri: 'at://did:plc:2haymntuvxoztui33dcy44wo/app.bsky.feed.post/3ku2hxsznlk2g',
      val: '!hide',
      ver: 1
    }
  ],
  '$type': 'com.atproto.label.subscribeLabels#labels'
},
{
  seq: 24,
  labels: [
    {
      cid: 'bafyreif42i43at3rwjjmawn7ujysyawmwvnquumooprlkexepgkm7p3l6q',
      cts: '2024-06-03T23:46:10.124Z',
      neg: true,
      sig: <Buffer e4 f8 2d 6c 0d dd d1 f4 64 f0 10 3f d4 8d c1 56 64 10 87 85 40 c5 2b b3 d0 e4 1f a6 4a aa 85 44 52 15 7a cb 88 73 8b 88 a3 98 c6 17 97 5a 89 f0 07 32 ... 14 more bytes>,
      src: 'did:plc:g5gqnspblin52gmy4iexeswq',
      uri: 'at://did:plc:2haymntuvxoztui33dcy44wo/app.bsky.feed.post/3ku2hxsznlk2g',
      val: '!hide',
      ver: 1
    }
  ],
  '$type': 'com.atproto.label.subscribeLabels#labels'
}
*/
