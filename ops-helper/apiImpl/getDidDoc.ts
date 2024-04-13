#!/usr/bin/env ts-node

import * as plc_            from '@did-plc/lib'
import { Secp256k1Keypair } from '@atproto/crypto'
import  yargs               from 'yargs'

// based on atproto/packages/dev-env/util.ts
const getDidDic = async (opts: any): Promise<any> => 
{
  const { plc, did } = opts
  const cli = new plc_.Client(plc)
  const doc = await cli.getDocument(did)

  return doc
}

const main = async (ops: any) => {
   const rtn = await getDidDic(opt)
   console.log(JSON.stringify(rtn))
}

const opt = yargs(process.argv.slice(2)).options({
 plc:           { type: 'string', description: 'PLC URL', default:'https://plc.directory'},
 did:           { type: 'string', description: 'DID in did:plc:... '},
 tls:           { type: 'string', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)', default: '0'}
}).parseSync()

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls
main(opt)
