# CatCheck API — Trương Tuấn Vĩnh 2380602577

Backend TypeScript chạy trên Cloudflare Workers thông qua Sites/Vinext, dùng D1 (SQLite có lưu trữ bền vững). Frontend di động là Flutter ở thư mục cha.

## API

- POST /api/auth/register: username, email, name, studentCode, password; tài khoản mới chỉ được student.
- POST /api/auth/login: username + password → gửi Email OTP, chưa cấp token.
- POST /api/auth/verify: challengeId + code → token phiên 7 ngày. OTP có hạn 10 phút, tối đa 5 lần thử, dùng một lần.
- GET /api/auth/me; POST /api/auth/logout; PUT /api/profile.
- GET/PUT/DELETE /api/users[/id]: chỉ Admin quản trị tài khoản.
- GET/POST /api/courses; PUT/DELETE /api/courses/id; POST /api/courses/join.
- GET/POST/DELETE /api/courses/id/members[/userId].
- GET/POST /api/sessions; PUT/DELETE /api/sessions/id; GET /api/sessions/id/qr và /attendance; POST /checkin.
- GET /api/history: chỉ điểm danh của chính người gọi.
- GET/POST /api/explanations; PUT/DELETE /api/explanations/id, chỉ sinh viên sửa/xóa giải trình của mình đang pending; giảng viên lớp hoặc Admin được duyệt.
- GET /api/audit: Admin; GET /api/health: công khai, không lộ bí mật.

Protected routes cần Authorization: Bearer token. Token ngẫu nhiên, database chỉ lưu hash; logout thu hồi ngay. Mật khẩu PBKDF2-SHA256, salt riêng, 100000 vòng. Không lưu mật khẩu/OTP dạng rõ trong database; mã test chỉ được trả khi LOCAL_TEST_MODE=true và hostname là localhost/127.0.0.1, không bật trên production.

QR ngẫu nhiên được hash trong database, hết hạn sau 90 giây; đổi QR vô hiệu hóa mã trước. Server kiểm tra thành viên lớp, thời gian, trạng thái mở, GPS accuracy <=100m và bán kính nếu giảng viên đặt tọa độ lớp. GPS phía client không phải bằng chứng chống giả mạo tuyệt đối. Không dùng cảm biến chuyển động để suy luận điểm danh.

## Runtime variables

Cấu hình bí mật qua Sites, không commit .env hoặc .dev.vars:

- BOOTSTRAP_SECRET: cấp Admin đầu tiên cho email đã xác thực, qua POST /api/setup/admin.
- MAIL_RELAY_URL và MAIL_RELAY_SECRET: Google Apps Script web app như ../docs/EMAIL_OTP.md.
- Hoặc RESEND_API_KEY và EMAIL_FROM: Resend.

Chưa có cấu hình gửi email thì API trả 503 rõ ràng, không cấp token bỏ qua OTP.

## Kiểm tra và triển khai

npm ci; npm run db:generate nếu thay đổi schema, xem xét migration trước khi deploy. Migrations chỉ thay đổi schema; không seed tài khoản/khóa production. Hạ tầng Sites áp dụng migrations trước khi publish. .openai/hosting.json chứa project_id và binding DB, không chứa secret.

Backend tests: node tests/api-smoke.mjs, chỉ chạy với Worker local ở cổng 5188 có LOCAL_TEST_MODE=true. Bộ kiểm thử tạo dữ liệu giả, không gửi mail thật, không được dùng URL production cho chế độ kiểm thử này. Bootstrap test chỉ thiết lập Admin đầu tiên trong database sandbox; dùng database local trống để chạy lại.

Địa chỉ public: https://truong-tuan-vinh-2577-catcheck.dreamy-gem-3550.chatgpt.site/api/health

Nguồn kỹ thuật: https://resend.com/docs/api-reference/emails/send-email ; https://developers.google.com/apps-script/reference/mail/mail-app
