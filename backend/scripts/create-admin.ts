import prompts from "prompts";
import { z } from "zod";
import { eq, or } from "drizzle-orm";
import { migrate, db } from "../src/database/client.js";
import { users } from "../src/database/schema.js";
import { AuthService } from "../src/auth/service.js";

migrate();
const auth = new AuthService();
const { mode } = await prompts({type:"select",name:"mode",message:"Administrator action",choices:[{title:"Create administrator",value:"create"},{title:"Update administrator",value:"update"}]});
if (mode === "update") {
  const answer = await prompts([
    {type:"text",name:"identifier",message:"Existing username or email:"},
    {type:"text",name:"username",message:"New username:"},
    {type:"text",name:"email",message:"New email:"},
    {type:"password",name:"password",message:"New password (12+ characters):"},
  ]);
  const input=z.object({identifier:z.string().trim().min(1),username:z.string().trim().min(3),email:z.string().trim().email(),password:z.string().trim().min(12)}).parse(answer);
  const existing=await db.query.users.findFirst({where:or(eq(users.username,input.identifier.toLowerCase()),eq(users.email,input.identifier.toLowerCase()))});
  if(!existing)throw new Error("Administrator not found");
  await db.update(users).set({username:input.username.toLowerCase(),email:input.email.toLowerCase(),passwordHash:await auth.hashPassword(input.password),updatedAt:Date.now()}).where(eq(users.id,existing.id));
  console.log("Administrator updated. Existing sessions remain valid until they expire.");
} else {
  const answer=await prompts([{type:"text",name:"username",message:"Username:"},{type:"text",name:"email",message:"Email:"},{type:"password",name:"password",message:"Password:"}]);
  const input=z.object({username:z.string().trim().min(3),email:z.string().trim().email(),password:z.string().trim().min(12)}).parse(answer);
  await auth.createAdmin(input.username,input.email,input.password);
  console.log("Administrator created.");
}
