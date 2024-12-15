#!/usr/bin/env tsx

import { AtpAgent }         from "@atproto/api";
import { Secp256k1Keypair } from "@atproto/crypto";
import yargs                from 'yargs/yargs';

const main = async function (opt:any)
{
  const agent = new AtpAgent({ service: opt.pdsURL })
  await agent.login({ identifier: opt.handle, password: opt.password });

  const gotCreds = await agent.com.atproto.identity.getRecommendedDidCredentials();
  const rkey = gotCreds.data.rotationKeys ?? [];
  if (!rkey) { throw new Error("No rotation key provided"); }
  const skey  = await Secp256k1Keypair.import(opt.signingKeyHex)

  const credentials = 
  {
    ...gotCreds.data,
    verificationMethods: { ...gotCreds.data.verificationMethods,  atproto_label:   skey.did(),  },
    services:            { ...gotCreds.data.services,             atproto_labeler: { type: "AtprotoLabeler", endpoint: opt.labelerURL }, },
    rotationKeys:        [ skey.did(), ...rkey ],
  };

  console.log(credentials)
  const plcOp = await agent.com.atproto.identity.signPlcOperation({ token: opt.plcSignToken, ...credentials });
  await agent.com.atproto.identity.submitPlcOperation({ operation: plcOp.data.operation, });
}

//===================================================

const dom = process.env.DOMAIN ?? 'mysky.local.com'
const opt = yargs(process.argv.slice(2)).options({
 labelerURL:    { type: 'string', description: 'labeler URL', default: `https://ozone.${dom}`},
 pdsURL:        { type: 'string', description: 'PDS URL',     default: `https://pds.${dom}`},
 handle:        { type: 'string', description: 'labeler handle'},
 password:      { type: 'string', description: 'labeler password'},
 signingKeyHex: { type: 'string', description: 'labeler SigningKeyHex'},
 plcSignToken:  { type: 'string', description: 'PLC Token received in Email'},
 tls:           { type: 'string', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)', default: '0'}
}).parseSync()

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls
main(opt)
