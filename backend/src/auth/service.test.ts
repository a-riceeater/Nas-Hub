import{describe,expect,it}from"vitest";import{AuthService}from"./service.js";
describe("password hashing",()=>{it("accepts the password but not another value",async()=>{const auth=new AuthService(),hash=await auth.hashPassword("correct horse battery staple");expect(hash).not.toContain("correct horse");const{verify}=await import("@node-rs/argon2");expect(await verify(hash,"correct horse battery staple")).toBe(true);expect(await verify(hash,"wrong")).toBe(false)})});

