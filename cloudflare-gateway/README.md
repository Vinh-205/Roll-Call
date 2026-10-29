# Roll call · Cloudflare API gateway

Cổng API HTTPS trên tài khoản Cloudflare của Trương Tuấn Vĩnh. Worker chuyển tiếp yêu cầu đến backend hiện có để giữ nguyên dữ liệu, phiên đăng nhập và Email OTP. Đây là reverse proxy, không phải bản di chuyển cơ sở dữ liệu sang tài khoản mới.

`/swagger` cung cấp Swagger UI; OpenAPI sử dụng địa chỉ `/api` trên cùng tên miền gateway. API giữ xác thực Bearer và phân quyền của backend gốc; không có khóa truy cập được nhúng trong Worker.

Triển khai: đăng nhập Wrangler bằng tài khoản sở hữu, rồi chạy `wrangler deploy` trong thư mục này. Không lưu token Cloudflare vào Git.
