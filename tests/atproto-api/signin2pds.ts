#!/usr/bin/env tsx

import { AtpAgent } from '@atproto/api';
import yargs         from 'yargs'

const main = async (ops: any) => {

   const agent = new AtpAgent({ service: opt.pdsURL });
   await agent.login ({identifier: opt.handle, password : opt.pass})
   console.log("login succeeded")

   const r = await agent.app.bsky.actor.getPreferences()
   console.log("pref: ", r)
}

const dom = process.env.DOMAIN ?? 'mysky.local.com'
const opt = yargs(process.argv.slice(2)).options({
 pdsURL:        { type: 'string', description: 'PDS URL', default: `https://pds.${dom}`},
 handle:        { type: 'string', description: 'Handle for bluesky ', default: ''},
 pass:          { type: 'string', description: 'password for login', default: ''},
 tls:           { type: 'string', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)', default: '0'}
}).parseSync()

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls
main(opt)
