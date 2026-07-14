import{expect,it}from"vitest";import{clientMessageSchema}from"./messages.js";it("rejects unknown protocol versions",()=>{expect(clientMessageSchema.safeParse({version:2,type:"ping"}).success).toBe(false);expect(clientMessageSchema.safeParse({version:1,type:"ping"}).success).toBe(true)});

