import type { IncomingMessage,ServerResponse } from "node:http";
export function json(res:ServerResponse,status:number,data:unknown){res.writeHead(status,{"content-type":"application/json","cache-control":"no-store"});res.end(JSON.stringify(data));}
export async function body(req:IncomingMessage){let raw="";for await(const chunk of req){raw+=chunk;if(raw.length>1_000_000)throw new Error("Body too large");}return raw?JSON.parse(raw):{};}
export const ok=(data:unknown)=>({data}); export const failure=(code:string,message:string)=>({error:{code,message}});

