import { connect, constants } from "node:http2";
import { readFile } from "node:fs/promises";
import { importPKCS8, SignJWT } from "jose";
import { config } from "../config/env.js";
import { log } from "../shared/log.js";

export type PushMessage={title:string;body:string;alertId?:string;serverId?:string;severity?:string;category?:string};
export type PushResult={success:boolean;status:number;reason?:string;invalidToken:boolean};
export interface PushProvider{readonly status:"ready"|"mock";send(token:string,topic:string,message:PushMessage):Promise<PushResult>}
export class MockPushProvider implements PushProvider{readonly status="mock" as const;async send(_token:string,topic:string,message:PushMessage){log.info({topic,payload:message},"mock push notification");return{success:true,status:200,invalidToken:false};}}

export class APNsPushProvider implements PushProvider{
 readonly status="ready" as const;private key?:Awaited<ReturnType<typeof importPKCS8>>;private jwt?:{value:string;createdAt:number};
 private get authority(){return config.APNS_ENVIRONMENT==="production"?"https://api.push.apple.com":"https://api.sandbox.push.apple.com";}
 private async authToken(){const now=Date.now();if(this.jwt&&now-this.jwt.createdAt<50*60*1000)return this.jwt.value;if(!config.APNS_PRIVATE_KEY_PATH||!config.APNS_KEY_ID||!config.APNS_TEAM_ID)throw new Error("APNs token credentials are incomplete");this.key??=await importPKCS8(await readFile(config.APNS_PRIVATE_KEY_PATH,"utf8"),"ES256");const value=await new SignJWT({}).setProtectedHeader({alg:"ES256",kid:config.APNS_KEY_ID}).setIssuer(config.APNS_TEAM_ID).setIssuedAt().sign(this.key);this.jwt={value,createdAt:now};return value;}
 async send(deviceToken:string,topic:string,message:PushMessage):Promise<PushResult>{const jwt=await this.authToken(),client=connect(this.authority);return new Promise((resolve,reject)=>{client.once("error",reject);const request=client.request({[constants.HTTP2_HEADER_METHOD]:"POST",[constants.HTTP2_HEADER_PATH]:`/3/device/${deviceToken}`,[constants.HTTP2_HEADER_AUTHORIZATION]:`bearer ${jwt}`,"apns-topic":topic,"apns-push-type":"alert","apns-priority":"10"});let status=0,raw="";request.setEncoding("utf8");request.on("response",headers=>status=Number(headers[constants.HTTP2_HEADER_STATUS]??0));request.on("data",chunk=>raw+=chunk);request.on("end",()=>{client.close();let reason:string|undefined;try{reason=(JSON.parse(raw) as{reason?:string}).reason}catch{}resolve({success:status===200,status,reason,invalidToken:status===410||reason==="BadDeviceToken"||reason==="Unregistered"})});request.on("error",error=>{client.close();reject(error)});request.end(JSON.stringify({aps:{alert:{title:message.title,body:message.body},sound:"default",badge:1,category:message.category??"SERVER_ALERT","thread-id":message.serverId},alertId:message.alertId,serverId:message.serverId,severity:message.severity}));});}
}
export function createPushProvider():PushProvider{return config.APNS_ENABLED?new APNsPushProvider():new MockPushProvider();}
