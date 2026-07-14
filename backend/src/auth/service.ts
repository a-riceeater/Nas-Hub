import { hash, verify } from "@node-rs/argon2";
import { SignJWT, jwtVerify } from "jose";
import { createHash, randomBytes, randomUUID, timingSafeEqual } from "node:crypto";
import { and, eq, gt, isNull, or } from "drizzle-orm";
import { db } from "../database/client.js";
import { sessions, users } from "../database/schema.js";
import { config } from "../config/env.js";

const secret = new TextEncoder().encode(config.ACCESS_TOKEN_SECRET);
const digest = (v:string) => createHash("sha256").update(v).digest("hex");
export type Principal = { sub:string; role:string; username:string };
export type Tokens = { accessToken:string; refreshToken:string; expiresIn:number };

export class AuthService {
  async hashPassword(password:string) { return hash(password, {algorithm:2, memoryCost:19456, timeCost:2, parallelism:1}); }
  async createAdmin(username:string,email:string,password:string) {
    const now=Date.now(), id=randomUUID();
    await db.insert(users).values({id,username:username.toLowerCase(),email:email.toLowerCase(),passwordHash:await this.hashPassword(password),role:"admin",createdAt:now,updatedAt:now}); return id;
  }
  async login(identifier:string,password:string,device?:string):Promise<Tokens|null> {
    const normalized=identifier.toLowerCase();
    const user=await db.query.users.findFirst({where: and(or(eq(users.username,normalized),eq(users.email,normalized)),eq(users.disabled,false))});
    if (!user || !await verify(user.passwordHash,password)) return null;
    return this.issue(user.id,user.role,user.username,device);
  }
  private async issue(userId:string,role:string,username:string,device?:string):Promise<Tokens> {
    const sessionId=randomUUID(), raw=randomBytes(32).toString("base64url"), now=Date.now(), expires=now+config.REFRESH_TOKEN_TTL_DAYS*86400000;
    const accessToken=await new SignJWT({role,username,sid:sessionId}).setProtectedHeader({alg:"HS256"}).setSubject(userId).setIssuedAt().setExpirationTime(`${config.ACCESS_TOKEN_TTL_MINUTES}m`).sign(secret);
    const refreshToken=`${sessionId}.${raw}`;
    await db.insert(sessions).values({id:sessionId,userId,refreshTokenHash:digest(raw),deviceDescription:device,createdAt:now,expiresAt:expires,lastUsedAt:now});
    return {accessToken,refreshToken,expiresIn:config.ACCESS_TOKEN_TTL_MINUTES*60};
  }
  async verifyAccess(token:string):Promise<Principal> { const {payload}=await jwtVerify(token,secret); if(!payload.sub||typeof payload.role!=="string"||typeof payload.username!=="string") throw new Error("Invalid token"); return {sub:payload.sub,role:payload.role,username:payload.username}; }
  async refresh(token:string):Promise<Tokens|null> {
    const [id,raw]=token.split("."); if(!id||!raw)return null;
    const session=await db.query.sessions.findFirst({where:and(eq(sessions.id,id),isNull(sessions.revokedAt),gt(sessions.expiresAt,Date.now()))});
    if(!session){return null;} const a=Buffer.from(session.refreshTokenHash,"hex"),b=Buffer.from(digest(raw),"hex"); if(a.length!==b.length||!timingSafeEqual(a,b))return null;
    await db.update(sessions).set({revokedAt:Date.now(),lastUsedAt:Date.now()}).where(eq(sessions.id,id));
    const user=await db.query.users.findFirst({where:eq(users.id,session.userId)}); return user?this.issue(user.id,user.role,user.username,session.deviceDescription??undefined):null;
  }
  async logout(token:string) { const [id]=token.split("."); if(id) await db.update(sessions).set({revokedAt:Date.now()}).where(eq(sessions.id,id)); }
}

