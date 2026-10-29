import {swaggerHtml} from '../../lib/swagger-page';
export function GET(){return new Response(swaggerHtml,{headers:{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-cache'}});}
