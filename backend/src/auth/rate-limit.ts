export class LoginLimiter {private attempts=new Map<string,{count:number;reset:number}>();allow(key:string){const now=Date.now(),e=this.attempts.get(key);if(!e||e.reset<now){this.attempts.set(key,{count:1,reset:now+60000});return true;}if(e.count>=10)return false;e.count++;return true;} clear(key:string){this.attempts.delete(key);}}

