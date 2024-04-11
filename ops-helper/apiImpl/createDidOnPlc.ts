#!/usr/bin/env ts-node

import * as plc_            from '@did-plc/lib'
import { Secp256k1Keypair } from '@atproto/crypto'
import  yargs               from 'yargs'

// based on atproto/packages/dev-env/util.ts
const createDidOnPlc = async (opts: any): Promise<any> => 
{
  const { handle, pds, plc, signingKeyHex } = opts
  const key = await Secp256k1Keypair.import(signingKeyHex)

  const did = await new plc_.Client(plc).createDid({
    signingKey: key.did(),
    rotationKeys: [key.did()],
    handle,
    signer: key,
    pds
  })

  return { handle, did }
}

const main = async (ops: any) => {
   const rtn = await createDidOnPlc(opt)
   console.log(JSON.stringify(rtn))
}

const opt = yargs(process.argv.slice(2)).options({
 plc:           { type: 'string', description: 'PLC URL'},
 handle:        { type: 'string', description: 'handle name'},
 signingKeyHex: { type: 'string', description: 'signing key in hex string'},
 pds:           { type: 'string', description: 'PDS URL', default: 'pds.invalid' },
 tls:           { type: 'string', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)', default: '0'}
}).parseSync()

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls
main(opt)
