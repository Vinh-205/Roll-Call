# Kịch bản demo Roll call

Trương Tuấn Vĩnh — 2380602577 — nhóm 4 con mèo.
Thời lượng đề xuất: 7–9 phút. Bản nộp dùng tên Roll call. API công khai qua cổng Cloudflare cá nhân; nghiệp vụ và dữ liệu backend được giữ nguyên.

## Chuẩn bị trước khi quay

- Mở máy ảo trên máy tính với tài khoản Admin. Điện thoại Redmi đăng nhập tài khoản Sinh viên, kết nối internet.
- Dùng lớp KT-REDMI hoặc tạo lớp DEMO-ROLLCALL. Tạo một buổi mới bắt đầu gần thời điểm quay và kết thúc sau ít nhất 60 phút.
- Nếu muốn kiểm tra bán kính: tạo buổi học bằng điện thoại Admin, bấm Đặt vị trí lớp tại đây, lấy vị trí chính xác, lưu. Sau đó giữ Admin trên máy ảo và dùng Sinh viên trên điện thoại.
- Dùng một buổi mới CHƯA điểm danh cho cảnh quét thành công. Buổi đã có bản ghi sẽ bị từ chối quét trùng.
- Chuẩn bị Gmail nhận OTP. Khi dựng video, che mật khẩu, mã OTP, thông báo riêng và tọa độ chi tiết; không quay file .private.env hoặc .email-setup.json.
- QR có thời hạn và tự làm mới: quay mã đang hiển thị trực tiếp trên máy ảo, không dùng ảnh QR cũ.
- Các vai trò thật được hỗ trợ: Admin, Giảng viên, Sinh viên. Nếu cần quay Giảng viên, đăng ký tài khoản email thật rồi Admin cấp vai trò trước.

## Các bước quay và lời nói tương ứng

| Thời gian | Thao tác trên màn hình | Nội dung cần chứng minh |
| --- | --- | --- |
| 00:00–00:25 | Logo Roll call, màn hình đăng nhập, tên cá nhân | Đúng tên cá nhân, Flutter, đúng đề điểm danh sinh viên |
| 00:25–01:20 | Đăng ký email hoặc dùng tài khoản đã tạo; đăng nhập bằng mật khẩu và OTP Gmail | Backend kiểm tra mật khẩu trước, OTP thật, không mã cố định |
| 01:20–02:00 | Lần lượt cho thấy Admin, Giảng viên, Sinh viên; có thể dựng cắt giữa các phiên đăng nhập | Phân quyền giao diện và phạm vi dữ liệu; Sinh viên không có quyền quản trị |
| 02:00–03:00 | Admin/Giảng viên tạo lớp, sửa tên/phòng; thêm sinh viên; tạo/sửa buổi học; xóa một buổi thử trống | CRUD thật, tải lại vẫn còn dữ liệu; không xóa buổi đang dùng quay |
| 03:00–04:30 | Admin mở QR, điện thoại Sinh viên quét, đồng ý chia sẻ vị trí, hiển thị thành công; máy ảo tải danh sách | Camera thật, GPS thật, bản ghi đồng bộ lên API công khai |
| 04:30–05:00 | Quét lại cùng buổi hoặc mở QR hết hạn | Máy chủ chặn điểm danh trùng/mã không hợp lệ; không bịa cảnh đã thử ngoài bán kính nếu chưa quay được |
| 05:00–05:50 | Sinh viên gửi giải trình ở buổi thử; sửa trước duyệt; Admin/Giảng viên ghi phản hồi và duyệt; Sinh viên xem lại | Giải trình có trạng thái, phản hồi và thời gian; đây là ý tưởng bổ sung, chưa chứng minh duy nhất trên thị trường |
| 05:50–06:35 | Nhịp học: bật cảm biến, nghiêng/di chuyển Redmi nhẹ; quay số và đồ thị thay đổi, bắt đầu/tạm dừng bộ đếm | Chức năng đo chuyển động dùng cảm biến vật lý; không suy diễn chuyển động là có mặt |
| 06:35–07:00 | Đổi sáng/tối, đổi tab để thấy chuyển động, mở lại Roll call | Chỉ quay các hiệu ứng đã có trong APK mới, không đọc lời khẳng định khi chưa cập nhật APK |
| 07:00–07:30 | Mở Swagger, thử GET /health và GET /auth/me sau Authorize; mở README GitHub, APK và QR tải | API public, tài liệu cài đặt, khả năng cài chung; không cần giữ localhost chạy |

## Cảnh dự phòng ngắn

- Sai mật khẩu hoặc sai OTP: quay thông báo lỗi, không lộ mã đúng.
- Từ chối vị trí/camera: quay thông báo hướng dẫn rồi cấp quyền bằng tay để tiếp tục.
- Sinh viên không thuộc lớp: dùng tài khoản thử riêng, quay lỗi truy cập.
- Ngưỡng đi muộn: đặt buổi thử đủ cũ hoặc ngưỡng nhỏ một cách công khai, giải thích cấu hình, không sửa đồng hồ điện thoại.

## Lưu ý khi trình bày trước thầy

Nói rõ ba chức năng đã chọn là b: chia sẻ vị trí; d: đo chuyển động; e: QR. Không cần nhận là đã làm cả sáu chức năng. Đăng ký email là lựa chọn đáp ứng đề; không nhận là có OAuth khi chưa làm. Không nói ứng dụng chống gian lận tuyệt đối. Điểm dự kiến là tự đánh giá; quyết định thuộc giảng viên.
