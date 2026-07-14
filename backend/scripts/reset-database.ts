import prompts from "prompts";
import { rmSync } from "node:fs";
import { resolve } from "node:path";
import { config } from "../src/config/env.js";

const databasePath=resolve(config.DATABASE_PATH);
const { confirmation }=await prompts({type:"text",name:"confirmation",message:`This deletes all metrics, alerts, and login credentials in ${databasePath}. Type RESET to continue:`});
if(confirmation!=="RESET"){console.log("Database reset cancelled.");process.exit(0);}
for(const suffix of ["","-wal","-shm"]){rmSync(`${databasePath}${suffix}`,{force:true});}
console.log("Database cleared. Run npm run db:migrate and npm run create-admin before restarting the server.");
