#!/usr/bin/env ts-node

import * as plc_            from '@did-plc/lib'
import { Secp256k1Keypair } from '@atproto/crypto'
import  yargs               from 'yargs'

// based on atproto/packages/dev-env/src/ozone.ts
const createOzoneDidOnPlc = async (opts: any): Promise<any> => 
{
  const { plc, signingKeyHex, labelerEndpoint } = opts
  const keypair = await Secp256k1Keypair.import(signingKeyHex)

  const cli = await new plc_.Client(plc)
  const plcOp = await plc_.signOperation(
    {
      type: 'plc_operation',
      alsoKnownAs: [],
      rotationKeys: [keypair.did()],
      verificationMethods: {
        atproto_label: keypair.did(),
      },
      services: {
        atproto_labeler: {
          type: 'AtprotoLabeler',
          endpoint: labelerEndpoint,
        },
      },
      prev: null,
    },
    keypair,
  )
  const did = await plc_.didForCreateOp(plcOp)
  await cli.sendOperation(did, plcOp)
  return { did }
}

const main = async (ops: any) => {
   const rtn = await createOzoneDidOnPlc(opt)
   console.log(JSON.stringify(rtn))
}

const opt = yargs(process.argv.slice(2)).options({
 plc:             { type: 'string', description: 'PLC URL'},
 signingKeyHex:   { type: 'string', description: 'signing key in hex string'},
 labelerEndpoint: { type: 'string', description: 'labeler endpoint', default: 'https://ozone.public.url'},
 tls:             { type: 'string', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)', default: '0'}
}).parseSync()

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls
main(opt)
