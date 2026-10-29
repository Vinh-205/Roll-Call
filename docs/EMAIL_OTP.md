# Kích hoạt Email OTP thật

Code đã hỗ trợ hai phương án gửi email. Không có mã OTP cố định, không bỏ qua bước OTP trên API công khai. API chỉ hoạt động phần đăng ký/đăng nhập khi bạn hoàn tất cấu hình này.

## Phương án Gmail miễn phí qua Google Apps Script

Không cần VPS, tên miền hoặc mật khẩu Gmail trong app.

1. Mở https://script.google.com/home/start bằng tài khoản Gmail dùng gửi OTP. Tạo dự án tên CatCheck Mail Relay.
2. Mở file tools/MailRelay.gs trong source code, sao chép toàn bộ vào Code.gs của dự án.
3. Chọn hàm initializeRelay và bấm Run. Xem các quyền mà Google yêu cầu và tự cấp quyền nếu đồng ý. Hàm này chưa gửi email nào.
4. Mở Project Settings → Script Properties. Sao chép giá trị CATCHECK_SECRET, không đưa lên Git hoặc gửi trong chat.
5. Deploy → New deployment → Web app. Execute as: Me. Who has access: Anyone. Deploy. Sao chép URL kết thúc bằng /exec.
6. Sao chép .email-setup.example.json thành .email-setup.json ở thư mục gốc dự án. Điền URL /exec vào url và CATCHECK_SECRET vào secret. File này đã được loại khỏi Git.
7. Báo cho mình “đã lưu .email-setup.json”. Mình sẽ cấu hình bí mật trên backend đã triển khai và kiểm tra trạng thái dịch vụ. Bạn tự nhập OTP nhận được khi dùng ứng dụng.

API public vẫn yêu cầu mật khẩu và Email OTP. Google Apps Script chỉ làm nhiệm vụ gửi mail với shared secret riêng, không lưu tài khoản ứng dụng.

Dịch vụ MailApp có hạn mức hàng ngày tùy loại tài khoản; kiểm tra tại https://developers.google.com/apps-script/guides/services/quotas. Đây là phương án cho bài tập nhóm quy mô nhỏ.

## Phương án thay thế Resend

Nếu có tài khoản Resend và địa chỉ gửi đã được xác minh, cấu hình RESEND_API_KEY và EMAIL_FROM vào runtime của backend. Không đặt khóa này trong Flutter hoặc mã nguồn. Chế độ thử nghiệm của Resend có giới hạn người nhận; cần cấu hình địa chỉ gửi phù hợp để cả nhóm nhận OTP.

## Quản trị viên đầu tiên

Sau khi OTP hoạt động, đăng ký và xác thực email của bạn trong ứng dụng. Công cụ tools/bootstrap-admin.ps1 cấp Admin cho đúng email đã xác thực, dùng BOOTSTRAP_SECRET trong file .private.env (không được đưa lên Git). API chỉ cho thiết lập quản trị viên đầu tiên một lần. Sau đó Admin đổi vai trò giảng viên bằng màn hình Quản trị tài khoản.

Nếu chưa cấu hình gửi mail, đừng trình bày ứng dụng như đã hoàn thành yêu cầu đăng nhập OTP. API /api/health hiển thị emailOtpConfigured=false để kiểm tra rõ ràng.
