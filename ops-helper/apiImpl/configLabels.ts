#!/usr/bin/env tsx

import { AtpAgent } from "@atproto/api";
import yargs        from 'yargs/yargs';
import * as fs      from 'fs';

const main = async (opt: any) => {

  const agent = new AtpAgent({ service: opt.pdsURL })
  await agent.login({ identifier: opt.handle, password: opt.password });

  const content = fs.readFileSync(opt.labeldef == '-' ? process.stdin.fd : opt.labeldef , 'utf-8')
  const policies = JSON.parse(content)

  const req = {
    repo: agent.session?.did ?? "",    collection: "app.bsky.labeler.service", rkey: "self",
    record: {  createdAt: new Date().toISOString(),    policies: policies,    },
  };
  
  await agent.api.com.atproto.repo.putRecord(req);
  console.log("done");
};

// ==============================================-
const opt = yargs(process.argv.slice(2)).options({
 pdsURL:        { type: 'string', description: 'PDS URL',     default: process.env.DOMAIN ? `https://pds.${process.env.DOMAIN}` : 'https://bsky.social' },
 handle:        { type: 'string', description: 'labeler handle'},
 password:      { type: 'string', description: 'labeler password'},
 labeldef:      { type: 'string', description: 'json file describing labels (policies part) default: stdin', default: '-' },
 tls:           { type: 'string', description: 'ignore TLS verification(NODE_TLS_REJECT_UNAUTHORIZED)', default: '0'}
}).parseSync()

process.env['NODE_TLS_REJECT_UNAUTHORIZED']=opt.tls
main(opt);
