import prompts from"prompts";import{z}from"zod";import{migrate}from"../src/database/client.js";import{AuthService}from"../src/auth/service.js";
migrate();const answer=await prompts([{type:"text",name:"username",message:"Username:"},{type:"text",name:"email",message:"Email:"},{type:"password",name:"password",message:"Password:"}]);const input=z.object({username:z.string().min(3),email:z.email(),password:z.string().min(12)}).parse(answer);await new AuthService().createAdmin(input.username,input.email,input.password);console.log("Administrator created.");

