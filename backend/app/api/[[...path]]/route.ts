import { env } from 'cloudflare:workers';
import { handle } from '../../../lib/api';
export const dynamic = 'force-dynamic';
const run = (request:Request) => handle(request, env as any);
export const GET=run; export const POST=run; export const PUT=run; export const DELETE=run; export const OPTIONS=run;
