import test from 'node:test';
import assert from 'node:assert/strict';
import worker from './worker.mjs';

test('Swagger with and without trailing slash serves HTML directly',async()=>{
 for(const path of ['/swagger','/swagger/']){
  const response=await worker.fetch(new Request('https://rollcall.example'+path));
  assert.equal(response.status,200);
  assert.match(await response.text(),/SwaggerUIBundle/);
  assert.equal(response.headers.get('location'),null);
 }
});
test('Swagger JSON uses the public gateway API rather than the upstream domain',async()=>{
 const old=globalThis.fetch;
 globalThis.fetch=async()=>Response.json({openapi:'3.0.3',servers:[{url:'https://old.example/api'}]});
 try{
  const response=await worker.fetch(new Request('https://rollcall.example/swagger/v1/swagger.json'));
  assert.equal((await response.json()).servers[0].url,'https://rollcall.example/api');
 }finally{globalThis.fetch=old;}
});
test('Bearer authorization and the API status are preserved without caching',async()=>{
 const old=globalThis.fetch;
 globalThis.fetch=async request=>{
  assert.equal(request.headers.get('authorization'),'Bearer test-placeholder');
  assert.equal(request.headers.get('cookie'),null);
  return Response.json({message:'Forbidden'},{status:403});
 };
 try{
  const response=await worker.fetch(new Request('https://rollcall.example/api/users',{headers:{Authorization:'Bearer test-placeholder',Cookie:'unused=1'}}));
  assert.equal(response.status,403);assert.equal(response.headers.get('cache-control'),'no-store');
 }finally{globalThis.fetch=old;}
});
test('Gateway rejects unrelated paths rather than becoming an open proxy',async()=>{
 assert.equal((await worker.fetch(new Request('https://rollcall.example/https://other.example'))).status,404);
});
