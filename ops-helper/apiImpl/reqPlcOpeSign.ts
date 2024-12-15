#!/usr/bin/env tsx

import { AtpAgent } from "@atproto/api";
import yargs        from 'yargs/yargs';

const main = async function (opt: any)
{
  const agent = new AtpAgent({ service: opt.pdsURL })
  await agent.login({ identifier: opt.handle, password: opt.password });
  await agent.com.atproto.identity.requestPlcOperationSignature();
}

// ======================================================================

const dom = process.env.DOMAIN ?? 'mysky.local.com'
const opt = yargs(process.argv.slice(2)).options({
 pdsURL:        { type: 'string', description: 'PDS URL', default: `https://pds.${dom}`},
 handle:        { type: 'string', description: 'bluesky handle'},
 password:      { type: 'string', description: 'password'},
 tls:           { type: 'string', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)', default: '0'}
}).parseSync()

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls

main(opt)
console.log("PLC operation signature requested! Check email sent to handle.");
