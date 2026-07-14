import si from "systeminformation";
import { hostname, platform, arch, loadavg } from "node:os";
import { EventEmitter } from "node:events";
import { eq } from "drizzle-orm";
import { db } from "../database/client.js";
import { metricSamples, servers } from "../database/schema.js";
import { config } from "../config/env.js";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { log } from "../shared/log.js";
import type { Metric } from "./types.js";

export const LOCAL_SERVER_ID="local";
const execFileAsync=promisify(execFile);
export class MetricCollector extends EventEmitter {
  current:Metric|null=null; private timer?:NodeJS.Timeout; private collecting=false; private lastPersist=0;private publicIPv4:string|null=null;private lastIPLookup=0; healthy=false;
  async start(){ const now=Date.now(); await db.insert(servers).values({id:LOCAL_SERVER_ID,name:hostname(),hostname:hostname(),operatingSystem:platform(),architecture:arch(),version:"0.1.0",createdAt:now,lastSeenAt:now}).onConflictDoUpdate({target:servers.id,set:{lastSeenAt:now}}); await this.collect(); this.timer=setInterval(()=>void this.collect(),config.METRIC_COLLECTION_INTERVAL_MS); log.info("metric collector started"); }
  stop(){if(this.timer)clearInterval(this.timer);this.healthy=false;}
  private async refreshPublicIPv4(timestamp:number){if(timestamp-this.lastIPLookup<600000)return;this.lastIPLookup=timestamp;try{const{stdout}=await execFileAsync("curl",["-4","--fail","--silent","--show-error","--max-time","5","https://ifconfig.me/ip"]);const value=stdout.trim();if(/^\d{1,3}(\.\d{1,3}){3}$/.test(value))this.publicIPv4=value;else log.warn({value},"public IPv4 lookup returned an invalid address");}catch(error){log.warn({error},"public IPv4 lookup unavailable");}}
  private async collect(){if(this.collecting)return;this.collecting=true;try{
    const [load,mem,fs,disks,net,time,processes,temp]=await Promise.all([si.currentLoad(),si.mem(),si.fsSize(),si.disksIO().catch(()=>null),si.networkStats(),si.time(),si.processes(),si.cpuTemperature().catch(()=>null)]);
    const disk=fs.filter(x=>!x.fs.startsWith("tmpfs")&&!x.fs.startsWith("devtmpfs")).reduce((a,x)=>({size:a.size+x.size,used:a.used+x.used,available:a.available+x.available}),{size:0,used:0,available:0});
    const loads=loadavg(), timestamp=Date.now();void this.refreshPublicIPv4(timestamp);
    const systemUtilization=load.cpus.length?Math.min((loads[0]??0)/load.cpus.length*100,999):null;
    const m:Metric={timestamp,publicIPv4:this.publicIPv4,cpuPercent:load.currentLoad,systemUtilization,perCore:load.cpus.map(c=>c.load),load1:loads[0]??0,load5:loads[1]??0,load15:loads[2]??0,ramTotal:mem.total,ramUsed:mem.active,ramAvailable:mem.available,ramPercent:mem.total?mem.active/mem.total*100:0,swapTotal:mem.swaptotal,swapUsed:mem.swapused,diskTotal:disk.size,diskUsed:disk.used,diskAvailable:disk.available,diskPercent:disk.size?disk.used/disk.size*100:null,diskReadBps:disks?.rIO_sec??null,diskWriteBps:disks?.wIO_sec??null,networkRxBps:net.reduce((a,n)=>a+(n.rx_sec??0),0),networkTxBps:net.reduce((a,n)=>a+(n.tx_sec??0),0),uptime:time.uptime,processCount:processes.all,temperature:temp?.main??null,bootTime:timestamp-time.uptime*1000};
    this.current=m;this.healthy=true;this.emit("metric",m); await db.update(servers).set({lastSeenAt:m.timestamp}).where(eq(servers.id,LOCAL_SERVER_ID));
    if(m.timestamp-this.lastPersist>=config.METRIC_PERSIST_INTERVAL_MS){this.lastPersist=m.timestamp;await db.insert(metricSamples).values({serverId:LOCAL_SERVER_ID,timestamp:m.timestamp,publicIPv4:m.publicIPv4,cpuPercent:m.cpuPercent,systemUtilization:m.systemUtilization,perCoreJson:JSON.stringify(m.perCore),load1:m.load1,load5:m.load5,load15:m.load15,ramTotal:m.ramTotal,ramUsed:m.ramUsed,ramAvailable:m.ramAvailable,ramPercent:m.ramPercent,swapTotal:m.swapTotal,swapUsed:m.swapUsed,diskTotal:m.diskTotal,diskUsed:m.diskUsed,diskAvailable:m.diskAvailable,diskPercent:m.diskPercent,diskReadBps:m.diskReadBps,diskWriteBps:m.diskWriteBps,networkRxBps:m.networkRxBps,networkTxBps:m.networkTxBps,uptime:m.uptime,processCount:m.processCount,temperature:m.temperature,bootTime:m.bootTime});}
  }catch(error){this.healthy=false;log.error({error},"metric collection failed");}finally{this.collecting=false;}}
}
