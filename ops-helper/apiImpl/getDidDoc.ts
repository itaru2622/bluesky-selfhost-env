#!/usr/bin/env tsx

import * as plc             from '@did-plc/lib'
import yargs                from 'yargs'

const main = async (ops: any) => {
   const cli = new plc.Client(opt.plcURL)
   const doc = await cli.getDocument(opt.did)
   console.log(JSON.stringify(doc))
}

const dom = process.env.DOMAIN ?? 'mysky.local.com'
const opt = yargs(process.argv.slice(2)).options({
 plcURL:        { type: 'string', description: 'PLC URL', default: `https://plc.${dom}`},
 did:           { type: 'string', description: 'DID in did:plc:... ', default: ''},
 tls:           { type: 'string', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)', default: '0'}
}).parseSync()

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls
main(opt)
