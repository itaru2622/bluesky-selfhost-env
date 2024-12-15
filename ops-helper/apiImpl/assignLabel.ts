#!/usr/bin/env tsx

import { AtpAgent } from "@atproto/api";
import yargs        from 'yargs/yargs';

const main = async function (opt: any) {

  const agent = new AtpAgent({ service: opt.pdsURL });
  await agent.login({ identifier: opt.handle, password: opt.password });

  const ev =
  {
      // subject of labeling
      subject: { $type: "com.atproto.repo.strongRef", uri: opt.uri, cid: opt.cid, },
      subjectBlobCids: [],

      event: {
        $type: "tools.ozone.moderation.defs#modEventLabel",
        createLabelVals: [opt.label], // add label
        negateLabelVals: [],          // del label
        comment: opt.comment,         // comment
      },
      // other metadata
      createdBy: agent.session!.did,
      createdAt: new Date().toISOString(),
  }
  console.log("#### emitEvent: ", ev)
  const resp = await agent.api.tools.ozone.moderation.emitEvent(ev, { encoding: "application/json", headers: { "atproto-proxy": `${agent.session!.did}#atproto_labeler` } });
  console.log("#### got resp: ", resp)
}

// ==============================================-
const opt = yargs(process.argv.slice(2)).options({
 pdsURL:        { type: 'string', description: 'PDS URL',     default: process.env.DOMAIN ? `https://pds.${process.env.DOMAIN}` : 'https://bsky.social' },
 handle:        { type: 'string', description: 'labeler handle'},
 password:      { type: 'string', description: 'labeler password'},
 label:         { type: 'string', description: 'label to assign'},
 uri  :         { type: 'string', description: 'subject uri'},
 cid  :         { type: 'string', description: 'subject cid'},
//blobCid :     { type: 'string', description: 'subject blobCid'},
 comment :      { type: 'string', description: 'comment on assigning label', default:''},
 tls:           { type: 'string', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)', default: '0'}
}).parseSync()

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls
main(opt)
