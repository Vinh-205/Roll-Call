import {swaggerHtml} from './swagger-page.mjs';
// Public API gateway in the owner's Cloudflare account.
// Authentication, OTP and persistent data remain in the existing API service.
const upstreamOrigin = 'https://truong-tuan-vinh-2577-catcheck.dreamy-gem-3550.chatgpt.site';
export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === '/') return Response.redirect(`${url.origin}/swagger`, 302);
    let path = url.pathname.replace(/\/$/, '') || '/';
    const api = path === '/api' || path.startsWith('/api/');
    const docs = path === '/swagger' || path.startsWith('/swagger/');
    if (!api && !docs) return new Response('Not found', {status:404});
    if (docs && !['GET','HEAD'].includes(request.method)) return new Response('Method not allowed', {status:405});
    if (path === '/swagger') return new Response(request.method==='HEAD'?null:swaggerHtml,{headers:{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-cache','X-Content-Type-Options':'nosniff'}});
    const target = new URL((path === '/swagger' ? '/swagger/index.html' : path) + url.search, upstreamOrigin);
    const headers = new Headers(request.headers);
    headers.delete('cookie');
    headers.delete('host');
    try {
      const response = await fetch(new Request(target, {
        method: request.method, headers,
        ...(!['GET','HEAD'].includes(request.method) ? {body:request.body} : {}),
        redirect:'manual',
      }));
      const outputHeaders = new Headers(response.headers);
      outputHeaders.delete('set-cookie');
      outputHeaders.delete('content-length');
      outputHeaders.set('X-Content-Type-Options','nosniff');
      if (api) outputHeaders.set('Cache-Control','no-store');
      const location=outputHeaders.get('location');
      if(location?.startsWith(upstreamOrigin))outputHeaders.set('location',location.replace(upstreamOrigin,url.origin));
      if (path === '/swagger/v1/swagger.json' && response.ok && request.method !== 'HEAD') {
        const spec=await response.json();
        spec.servers=[{url:`${url.origin}/api`,description:'Production · Cloudflare API'}];
        outputHeaders.set('Content-Type','application/json; charset=utf-8');
        return new Response(JSON.stringify(spec),{status:200,headers:outputHeaders});
      }
      return new Response(response.body,{status:response.status,statusText:response.statusText,headers:outputHeaders});
    } catch {
      return Response.json({message:'Không kết nối được dịch vụ API. Vui lòng thử lại.'},{status:502,headers:{'Cache-Control':'no-store','Access-Control-Allow-Origin':'*'}});
    }
  }
};
