export type Env={DB:D1Database;RESEND_API_KEY?:string;EMAIL_FROM?:string;BOOTSTRAP_SECRET?:string;LOCAL_TEST_MODE?:string;MAIL_RELAY_URL?:string;MAIL_RELAY_SECRET?:string};
class HttpError extends Error { constructor(public status:number,message:string){super(message)} }
const fail=(status:number,message:string):never=>{throw new HttpError(status,message)};
const id=()=>crypto.randomUUID(); const now=()=>Date.now();
const enc=new TextEncoder();
const hex=(b:ArrayBuffer)=>Array.from(new Uint8Array(b),v=>v.toString(16).padStart(2,'0')).join('');
export const sha=async(s:string)=>hex(await crypto.subtle.digest('SHA-256',enc.encode(s)));
async function passwordHash(password:string,salt:string){const key=await crypto.subtle.importKey('raw',enc.encode(password),'PBKDF2',false,['deriveBits']);return hex(await crypto.subtle.deriveBits({name:'PBKDF2',salt:enc.encode(salt),iterations:100000,hash:'SHA-256'},key,256));}
function safeEqual(a:string,b:string){let diff=a.length^b.length;for(let i=0;i<Math.max(a.length,b.length);i++)diff|=(a.charCodeAt(i)||0)^(b.charCodeAt(i)||0);return diff===0;}
export function distanceM(a:number,b:number,c:number,d:number){const rad=(n:number)=>n*Math.PI/180;const x=Math.sin(rad(c-a)/2)**2+Math.cos(rad(a))*Math.cos(rad(c))*Math.sin(rad(d-b)/2)**2;return 6371000*2*Math.atan2(Math.sqrt(x),Math.sqrt(Math.max(0,1-x)));}
const token=()=>hex(crypto.getRandomValues(new Uint8Array(32)).buffer);
const text=(v:any,max=200)=>{if(typeof v!=='string'||!v.trim()||v.trim().length>max)fail(400,'Dữ liệu trống hoặc vượt độ dài cho phép.');return v.trim();};
const num=(v:any,min:number,max:number)=>{if(typeof v!=='number'||!Number.isFinite(v)||v<min||v>max)fail(400,'Giá trị số không hợp lệ.');return v;};
const cleanUser=(u:any)=>({id:u.id,username:u.username,email:u.email,name:u.name,studentCode:u.student_code,role:u.role,verified:!!u.verified});
async function record(db:D1Database,userId:string,action:string,target:string){await db.prepare('INSERT INTO audit(id,user_id,action,target,created) VALUES(?,?,?,?,?)').bind(id(),userId,action,target,now()).run();}
async function authenticated(req:Request,e:Env){const auth=req.headers.get('Authorization')||'';if(!auth.startsWith('Bearer '))fail(401,'Vui lòng đăng nhập.');const u=await e.DB.prepare('SELECT u.* FROM tokens t JOIN users u ON u.id=t.user_id WHERE t.hash=? AND t.expires>? AND u.verified=1').bind(await sha(auth.slice(7)),now()).first<any>();if(!u)fail(401,'Phiên đăng nhập đã hết hạn.');return u;}
async function courseAccess(db:D1Database,u:any,courseId:string,write=false){const c=await db.prepare('SELECT c.*,u.name teacher_name FROM courses c JOIN users u ON c.teacher_id=u.id WHERE c.id=?').bind(courseId).first<any>();if(!c)fail(404,'Lớp học không tồn tại.');if(u.role==='admin'||u.role==='teacher'&&c.teacher_id===u.id)return c;if(!write&&u.role==='student'&&await db.prepare('SELECT id FROM members WHERE course_id=? AND user_id=?').bind(courseId,u.id).first())return c;fail(403,'Bạn không có quyền với lớp học này.');}
async function getSession(db:D1Database,u:any,sid:string,write=false){const s=await db.prepare('SELECT * FROM sessions WHERE id=?').bind(sid).first<any>();if(!s)fail(404,'Buổi học không tồn tại.');await courseAccess(db,u,s.course_id,write);return s;}
function admin(u:any){if(u.role!=='admin')fail(403,'Chỉ quản trị viên được thực hiện.');}
async function challenge(req:Request,e:Env,u:any,purpose:string){
 if(!(e.RESEND_API_KEY&&e.EMAIL_FROM)&&!(e.MAIL_RELAY_URL&&e.MAIL_RELAY_SECRET)){if(!(e.LOCAL_TEST_MODE==='true'&&['localhost','127.0.0.1'].includes(new URL(req.url).hostname)))fail(503,'Dịch vụ Email OTP chưa được cấu hình. Liên hệ quản trị viên.');}
 const recent=await e.DB.prepare('SELECT created FROM challenges WHERE user_id=? ORDER BY created DESC LIMIT 1').bind(u.id).first<any>();if(recent&&now()-recent.created<60000)fail(429,'Vui lòng chờ 60 giây trước khi gửi lại mã.');
 const challengeId=id(),code=String(crypto.getRandomValues(new Uint32Array(1))[0]%1000000).padStart(6,'0');
 await e.DB.prepare('INSERT INTO challenges(id,user_id,purpose,hash,expires,created) VALUES(?,?,?,?,?,?)').bind(challengeId,u.id,purpose,await sha(challengeId+code),now()+600000,now()).run();
 const local=e.LOCAL_TEST_MODE==='true'&&['localhost','127.0.0.1'].includes(new URL(req.url).hostname);
 if(!local){const payload={to:u.email,subject:'CatCheck · Mã xác thực của bạn',text:`Mã xác thực CatCheck của bạn là ${code}. Mã có hiệu lực 10 phút, chỉ dùng một lần. Không chia sẻ mã này.`}; let delivered=false;if(e.MAIL_RELAY_URL&&e.MAIL_RELAY_SECRET){const relay=await fetch(e.MAIL_RELAY_URL,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({...payload,secret:e.MAIL_RELAY_SECRET})});const data=await relay.json().catch(()=>({ok:false})) as any;delivered=relay.ok&&data.ok===true;}else{const response=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${e.RESEND_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify({from:e.EMAIL_FROM,to:[u.email],subject:'CatCheck · Mã xác thực của bạn',text:`Mã xác thực CatCheck của bạn là ${code}. Mã có hiệu lực 10 phút, chỉ dùng một lần. Không chia sẻ mã này với người khác.`})});delivered=response.ok;}if(!delivered){await e.DB.prepare('DELETE FROM challenges WHERE id=?').bind(challengeId).run();fail(502,'Không gửi được Email OTP. Kiểm tra cấu hình dịch vụ gửi mail.');}}
 return {challengeId,emailHint:u.email.replace(/(.{2}).*(@.*)/,'$1***$2'),purpose,expiresIn:600,...(local?{testOnlyCode:code}:{})};
}
export async function handle(req:Request,e:Env):Promise<Response>{
 const headers={'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'Authorization,Content-Type,X-Bootstrap-Secret','Access-Control-Allow-Methods':'GET,POST,PUT,DELETE,OPTIONS'};
 const reply=(data:any,status=200)=>new Response(JSON.stringify(data),{status,headers});
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 try{
 const path=new URL(req.url).pathname.replace(/^\/api\/?/,'').replace(/\/$/,''),parts=path.split('/'),method=req.method;
 if(path==='health')return reply({service:'CatCheck API',version:'1.0',publicApi:true,emailOtpConfigured:!!((e.RESEND_API_KEY&&e.EMAIL_FROM)||(e.MAIL_RELAY_URL&&e.MAIL_RELAY_SECRET)),storage:'Cloudflare D1'});
 const body=['POST','PUT'].includes(method)?await req.json().catch(()=>fail(400,'JSON không hợp lệ.')) as any:{};
 if(path==='auth/register'&&method==='POST'){
   const email=text(body.email).toLowerCase(),username=text(body.username,40).toLowerCase(),name=text(body.name,100),password=text(body.password,128);
   if(!/^[a-z0-9_.]{3,40}$/.test(username)||!/^\S+@\S+\.\S+$/.test(email)||password.length<8||!/[A-Za-z]/.test(password)||!/[0-9]/.test(password))fail(400,'Tên đăng nhập 3–40 ký tự không dấu. Email hợp lệ. Mật khẩu ít nhất 8 ký tự, có chữ và số.');
   if(body.role&&body.role!=='student')fail(403,'Tài khoản mới chỉ có vai trò sinh viên.');
   let u=await e.DB.prepare('SELECT * FROM users WHERE email=? OR username=?').bind(email,username).first<any>();
   if(u){if(u.verified||u.email!==email||u.username!==username||!safeEqual(u.password,await passwordHash(password,u.salt)))fail(409,'Email hoặc tên đăng nhập đã được sử dụng.');}
   else{const salt=token();u={id:id(),username,email,name,salt,password:await passwordHash(password,salt)};await e.DB.prepare('INSERT INTO users(id,username,email,name,student_code,password,salt,created) VALUES(?,?,?,?,?,?,?,?)').bind(u.id,username,email,name,(body.studentCode||'').slice(0,30),u.password,salt,now()).run();}
   return reply(await challenge(req,e,u,'register'),201);
 }
 if(path==='auth/login'&&method==='POST'){
   const username=text(body.username).toLowerCase(),password=text(body.password,128);
   const u=await e.DB.prepare('SELECT * FROM users WHERE username=? OR email=?').bind(username,username).first<any>();
   // Limit password guessing per account, persisted across requests and Worker restarts.
   if(u){const recent=await e.DB.prepare("SELECT COUNT(*) n FROM audit WHERE user_id=? AND action='login_failed' AND created>?").bind(u.id,now()-900000).first<any>();if(recent.n>=8)fail(429,'Quá nhiều lần đăng nhập sai. Thử lại sau 15 phút.');}
   if(!u||!safeEqual(u.password,await passwordHash(password,u.salt))){if(u)await record(e.DB,u.id,'login_failed',u.id);fail(401,'Tên đăng nhập hoặc mật khẩu không đúng.');}
   return reply(await challenge(req,e,u,u.verified?'login':'register'));
 }
 if(path==='auth/verify'&&method==='POST'){
   const cid=text(body.challengeId),code=text(body.code,6);if(!/^\d{6}$/.test(code))fail(400,'Mã OTP gồm 6 chữ số.');
   const c=await e.DB.prepare('UPDATE challenges SET attempts=attempts+1 WHERE id=? AND expires>? AND used=0 AND attempts<5 RETURNING *').bind(cid,now()).first<any>();
   if(!c||!safeEqual(c.hash,await sha(cid+code)))fail(401,'OTP không đúng, đã dùng hoặc hết hạn.');
   if(!await e.DB.prepare('UPDATE challenges SET used=1 WHERE id=? AND used=0 RETURNING id').bind(cid).first())fail(401,'OTP đã được sử dụng.');
   if(c.purpose==='register')await e.DB.prepare('UPDATE users SET verified=1 WHERE id=?').bind(c.user_id).run();
   const u=await e.DB.prepare('SELECT * FROM users WHERE id=?').bind(c.user_id).first<any>();
   const value=token(),expiry=now()+7*86400000;await e.DB.prepare('INSERT INTO tokens(hash,user_id,expires) VALUES(?,?,?)').bind(await sha(value),u.id,expiry).run();
   await record(e.DB,u.id,'login_success',u.id);return reply({token:value,expiresAt:expiry,user:cleanUser(u)});
 }
 if(path==='setup/admin'&&method==='POST'){
   if(!e.BOOTSTRAP_SECRET||!safeEqual(req.headers.get('X-Bootstrap-Secret')||'',e.BOOTSTRAP_SECRET))fail(403,'Không có quyền thiết lập.');
   const u=await e.DB.prepare('SELECT * FROM users WHERE email=? AND verified=1').bind(text(body.email).toLowerCase()).first<any>();if(!u)fail(400,'Đăng ký và xác thực email trước.');
   if(await e.DB.prepare("SELECT id FROM users WHERE role='admin'").first())fail(409,'Quản trị viên đã được thiết lập.');
   await e.DB.prepare("UPDATE users SET role='admin' WHERE id=?").bind(u.id).run();await record(e.DB,u.id,'bootstrap_admin',u.id);return reply({message:'Đã cấp vai trò quản trị viên.'});
 }
 const u=await authenticated(req,e),db=e.DB;
 if(path==='auth/me'&&method==='GET')return reply(cleanUser(u));
 if(path==='auth/logout'&&method==='POST'){await db.prepare('DELETE FROM tokens WHERE hash=?').bind(await sha((req.headers.get('Authorization')||'').slice(7))).run();return reply({ok:true});}
 if(path==='profile'&&method==='PUT'){await db.prepare('UPDATE users SET name=?,student_code=? WHERE id=?').bind(text(body.name,100),String(body.studentCode||'').slice(0,30),u.id).run();return reply({ok:true});}
 if(parts[0]==='users'){
   admin(u);
   if(method==='GET')return reply((await db.prepare('SELECT id,username,email,name,student_code,role,verified FROM users ORDER BY created DESC LIMIT 300').all()).results);
   if(method==='PUT'&&parts[1]){if(!['admin','teacher','student'].includes(body.role))fail(400,'Vai trò không hợp lệ.');if(parts[1]===u.id)fail(400,'Không tự đổi vai trò của chính mình.');await db.prepare('UPDATE users SET role=? WHERE id=?').bind(body.role,parts[1]).run();await record(db,u.id,'change_role',parts[1]);return reply({ok:true});}
   if(method==='DELETE'&&parts[1]){if(parts[1]===u.id)fail(400,'Không tự xóa tài khoản quản trị.');if(await db.prepare('SELECT id FROM courses WHERE teacher_id=?').bind(parts[1]).first())fail(409,'Hãy chuyển lớp của giảng viên trước khi xóa.');await db.prepare('DELETE FROM users WHERE id=?').bind(parts[1]).run();await record(db,u.id,'delete_user',parts[1]);return reply({ok:true});}
 }
 if(path==='courses/join'&&method==='POST'){
   if(u.role!=='student')fail(403,'Chỉ sinh viên tham gia lớp.');const c=await db.prepare('SELECT id FROM courses WHERE code=?').bind(text(body.code,30).toUpperCase()).first<any>();if(!c)fail(404,'Mã lớp không tồn tại.');await db.prepare('INSERT OR IGNORE INTO members(id,course_id,user_id) VALUES(?,?,?)').bind(id(),c.id,u.id).run();return reply({ok:true});
 }
 if(parts[0]==='courses'){
   const cid=parts[1];
   if(!cid&&method==='GET'){
     const query=u.role==='admin'?'SELECT c.*,u.name teacher_name FROM courses c JOIN users u ON u.id=c.teacher_id ORDER BY c.created DESC':u.role==='teacher'?'SELECT c.*,u.name teacher_name FROM courses c JOIN users u ON u.id=c.teacher_id WHERE c.teacher_id=? ORDER BY c.created DESC':'SELECT c.*,u.name teacher_name FROM courses c JOIN users u ON u.id=c.teacher_id JOIN members m ON m.course_id=c.id WHERE m.user_id=? ORDER BY c.created DESC';return reply((await (u.role==='admin'?db.prepare(query):db.prepare(query).bind(u.id)).all()).results);
   }
   if(!cid&&method==='POST'){
     if(!['admin','teacher'].includes(u.role))fail(403,'Không có quyền tạo lớp.');
     const teacher=u.role==='teacher'?u.id:(body.teacherId||u.id);const t=await db.prepare("SELECT id FROM users WHERE id=? AND role IN ('admin','teacher') AND verified=1").bind(teacher).first();if(!t)fail(400,'Giảng viên không hợp lệ.');
     const value={id:id(),code:text(body.code,30).toUpperCase(),name:text(body.name,120),room:text(body.room,60)};if(!/^[A-Z0-9_-]{3,30}$/.test(value.code))fail(400,'Mã lớp 3–30 ký tự A–Z, số, gạch nối.');await db.prepare('INSERT INTO courses(id,code,name,room,teacher_id,created) VALUES(?,?,?,?,?,?)').bind(value.id,value.code,value.name,value.room,teacher,now()).run();return reply(value,201);
   }
   if(cid){await courseAccess(db,u,cid,method!=='GET');
     if(parts[2]==='members'){
       if(u.role==='student')fail(403,'Không được xem danh sách cá nhân của lớp.');
       if(method==='GET')return reply((await db.prepare('SELECT u.id,u.name,u.username,u.student_code,u.email FROM members m JOIN users u ON u.id=m.user_id WHERE m.course_id=? ORDER BY u.name').bind(cid).all()).results);
       if(method==='POST'){const s=await db.prepare("SELECT id FROM users WHERE (username=? OR email=?) AND role='student' AND verified=1").bind(text(body.username).toLowerCase(),text(body.username).toLowerCase()).first<any>();if(!s)fail(404,'Không tìm thấy sinh viên đã xác thực.');await db.prepare('INSERT OR IGNORE INTO members(id,course_id,user_id) VALUES(?,?,?)').bind(id(),cid,s.id).run();return reply({ok:true});}
       if(method==='DELETE'&&parts[3]){await db.prepare('DELETE FROM members WHERE course_id=? AND user_id=?').bind(cid,parts[3]).run();return reply({ok:true});}
     }
     if(parts.length===2){
       if(method==='PUT'){await db.prepare('UPDATE courses SET name=?,room=? WHERE id=?').bind(text(body.name,120),text(body.room,60),cid).run();return reply({ok:true});}
       if(method==='DELETE'){await db.prepare('DELETE FROM courses WHERE id=?').bind(cid).run();await record(db,u.id,'delete_course',cid);return reply({ok:true});}
     }
   }
 }
 if(parts[0]==='sessions'){
   const sid=parts[1];
   if(!sid&&method==='GET'){
     const q=u.role==='admin'?'SELECT s.*,c.name course_name,c.code,c.room FROM sessions s JOIN courses c ON c.id=s.course_id':u.role==='teacher'?'SELECT s.*,c.name course_name,c.code,c.room FROM sessions s JOIN courses c ON c.id=s.course_id WHERE c.teacher_id=?':'SELECT s.*,c.name course_name,c.code,c.room,a.status attendance_status FROM sessions s JOIN courses c ON c.id=s.course_id JOIN members m ON m.course_id=c.id LEFT JOIN attendance a ON a.session_id=s.id AND a.user_id=m.user_id WHERE m.user_id=?';
     return reply((await (u.role==='admin'?db.prepare(q+' ORDER BY s.starts DESC LIMIT 200'):db.prepare(q+' ORDER BY s.starts DESC LIMIT 200').bind(u.id)).all()).results);
   }
   if(!sid&&method==='POST'){
     await courseAccess(db,u,text(body.courseId),true);const starts=num(body.starts,0,4102444800000),ends=num(body.ends,starts+60000,starts+86400000);
     const lat=body.lat==null?null:num(body.lat,-90,90),lng=body.lng==null?null:num(body.lng,-180,180);if((lat===null)!==(lng===null))fail(400,'Cần cả vĩ độ và kinh độ.');
     const value=id();await db.prepare('INSERT INTO sessions(id,course_id,title,starts,ends,late_minutes,lat,lng,radius) VALUES(?,?,?,?,?,?,?,?,?)').bind(value,body.courseId,text(body.title,120),starts,ends,num(body.lateMinutes??15,0,180),lat,lng,num(body.radius??150,30,2000)).run();return reply({id:value},201);
   }
   if(sid){const s=await getSession(db,u,sid,method!=='GET'&&parts[2]!=='checkin');
     if(parts[2]==='qr'&&method==='GET'){await courseAccess(db,u,s.course_id,true);const value=token(),expires=now()+90000;await db.prepare('UPDATE sessions SET qr_hash=?,qr_expires=? WHERE id=?').bind(await sha(value),expires,sid).run();return reply({qr:`catcheck:${sid}:${value}`,expiresAt:expires});}
     if(parts[2]==='attendance'&&method==='GET'){
       await courseAccess(db,u,s.course_id,true);return reply((await db.prepare("SELECT u.id user_id,u.name,u.student_code,a.status,a.checked,a.lat,a.lng,a.accuracy,a.distance FROM members m JOIN users u ON u.id=m.user_id LEFT JOIN attendance a ON a.user_id=u.id AND a.session_id=? WHERE m.course_id=? ORDER BY u.name").bind(sid,s.course_id).all()).results);
     }
     if(parts[2]==='checkin'&&method==='POST'){
       if(u.role!=='student')fail(403,'Chỉ sinh viên được điểm danh.');if(s.closed||now()<s.starts||now()>s.ends)fail(400,'Buổi học chưa mở hoặc đã kết thúc.');
       if(s.qr_expires<now()||!safeEqual(s.qr_hash||'',await sha(text(body.qrToken))))fail(400,'Mã QR đã hết hạn. Hãy quét mã mới từ giảng viên.');
       const lat=num(body.lat,-90,90),lng=num(body.lng,-180,180),accuracy=num(body.accuracy,0,100);const distance=s.lat==null?null:distanceM(lat,lng,s.lat,s.lng);if(distance!=null&&distance>s.radius)fail(400,`Bạn đang ngoài phạm vi lớp (${Math.round(distance)} m). Có thể gửi giải trình.`);
       const status=now()>s.starts+s.late_minutes*60000?'late':'present';
       await db.prepare('INSERT INTO attendance(id,session_id,user_id,status,checked,lat,lng,accuracy,distance) VALUES(?,?,?,?,?,?,?,?,?)').bind(id(),sid,u.id,status,now(),lat,lng,accuracy,distance).run();await record(db,u.id,'checkin',sid);return reply({status,distance,message:'Điểm danh thành công.'},201);
     }
     if(parts.length===2){
       if(method==='PUT'){if(body.closed!==undefined){await db.prepare('UPDATE sessions SET closed=? WHERE id=?').bind(body.closed?1:0,sid).run();}else{const starts=num(body.starts,0,4102444800000),ends=num(body.ends,starts+60000,starts+86400000);await db.prepare('UPDATE sessions SET title=?,starts=?,ends=?,late_minutes=?,qr_hash=NULL,qr_expires=NULL WHERE id=?').bind(text(body.title,120),starts,ends,num(body.lateMinutes??15,0,180),sid).run();}return reply({ok:true});}
       if(method==='DELETE'){await db.prepare('DELETE FROM sessions WHERE id=?').bind(sid).run();await record(db,u.id,'delete_session',sid);return reply({ok:true});}
     }
   }
 }
 if(path==='history'&&method==='GET')return reply((await db.prepare('SELECT a.*,s.title,c.name course_name FROM attendance a JOIN sessions s ON s.id=a.session_id JOIN courses c ON c.id=s.course_id WHERE a.user_id=? ORDER BY a.checked DESC LIMIT 300').bind(u.id).all()).results);
 if(parts[0]==='explanations'){
   const eid=parts[1];
   if(!eid&&method==='GET'){
     const q="SELECT x.*,u.name student_name,u.student_code,s.title,c.name course_name FROM explanations x JOIN users u ON u.id=x.user_id JOIN sessions s ON s.id=x.session_id JOIN courses c ON c.id=s.course_id";
     return reply((await (u.role==='admin'?db.prepare(q+' ORDER BY x.created DESC LIMIT 300'):db.prepare(q+(u.role==='teacher'?' WHERE c.teacher_id=?':' WHERE x.user_id=?')+' ORDER BY x.created DESC LIMIT 300').bind(u.id)).all()).results);
   }
   if(!eid&&method==='POST'){
     if(u.role!=='student')fail(403,'Chỉ sinh viên gửi giải trình.');await getSession(db,u,text(body.sessionId));
     if(await db.prepare("SELECT id FROM explanations WHERE session_id=? AND user_id=? AND status='pending'").bind(body.sessionId,u.id).first())fail(409,'Đã có giải trình đang chờ duyệt.');
     const value=id();await db.prepare('INSERT INTO explanations(id,session_id,user_id,message,created) VALUES(?,?,?,?,?)').bind(value,body.sessionId,u.id,text(body.message,2000),now()).run();return reply({id:value},201);
   }
   if(eid){const x=await db.prepare('SELECT * FROM explanations WHERE id=?').bind(eid).first<any>();if(!x)fail(404,'Không tìm thấy giải trình.');
     if(method==='PUT'&&u.role==='student'){if(x.user_id!==u.id||x.status!=='pending')fail(403,'Chỉ sửa giải trình của mình đang chờ duyệt.');await db.prepare('UPDATE explanations SET message=? WHERE id=?').bind(text(body.message,2000),eid).run();return reply({ok:true});}
     if(method==='DELETE'){if(u.role!=='student'||x.user_id!==u.id||x.status!=='pending')fail(403,'Chỉ xóa giải trình của mình đang chờ duyệt.');await db.prepare('DELETE FROM explanations WHERE id=?').bind(eid).run();return reply({ok:true});}
     if(method==='PUT'){await getSession(db,u,x.session_id,true);if(!['approved','rejected'].includes(body.status))fail(400,'Kết quả duyệt không hợp lệ.');
       const statements=[db.prepare("UPDATE explanations SET status=?,review_note=?,reviewer_id=?,reviewed=? WHERE id=? AND status='pending'").bind(body.status,text(body.note,500),u.id,now(),eid)];
       if(x.status!=='pending')fail(409,'Giải trình đã được xử lý.');
       if(body.status==='approved')statements.push(db.prepare("INSERT OR IGNORE INTO attendance(id,session_id,user_id,status,checked) VALUES(?,?,?,'excused',?)").bind(id(),x.session_id,x.user_id,now()));
       await db.batch(statements);await record(db,u.id,'review_'+body.status,eid);return reply({ok:true});
     }
   }
 }
 if(path==='audit'&&method==='GET'){admin(u);return reply((await db.prepare('SELECT a.*,u.name actor_name FROM audit a LEFT JOIN users u ON u.id=a.user_id ORDER BY a.created DESC LIMIT 100').all()).results);}
 return fail(404,'Không có API này.');
 }catch(error:any){if(error instanceof HttpError)return reply({message:error.message},error.status);if(String(error?.message).includes('UNIQUE constraint'))return reply({message:'Dữ liệu đã tồn tại hoặc đã điểm danh.'},409);console.error('API error',error?.name);return reply({message:'Máy chủ gặp lỗi. Vui lòng thử lại.'},500);}
}


