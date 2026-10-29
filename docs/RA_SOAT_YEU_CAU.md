# Rà soát đề kiểm tra 40 phần trăm

Ngày kiểm tra: 29/10/2026. Chủ dự án: Trương Tuấn Vĩnh, 2380602577. Đề của nhóm 4 con mèo: App điểm danh cho sinh viên.

Kết luận: Chưa đủ cơ sở xác nhận đạt toàn bộ yêu cầu và không thể cam kết điểm. Các phần xác thực, API công khai, CRUD và phân quyền đã có bằng chứng kỹ thuật. Ba chức năng thiết bị chưa được kiểm chứng đầu cuối trên điện thoại thật. Tính năng mới hiện tại có nguy cơ không đáp ứng tiêu chí mới so với ứng dụng hiện có.

## Đối chiếu từng yêu cầu

| Yêu cầu | Kết quả | Bằng chứng và giới hạn |
| --- | --- | --- |
| Đúng đề nhóm 4 con mèo | Phù hợp | Tài khoản Admin/Giảng viên/Sinh viên, lớp học, buổi học, điểm danh, giải trình |
| Tên project chứa tên cá nhân | Đã kiểm tra | pubspec.yaml: truong_tuan_vinh_2380602577_diem_danh; tên thư mục và Android applicationId có thông tin cá nhân |
| Dùng Flutter | Đã kiểm tra | Mã Dart/Flutter và APK Android release; backend TypeScript được đề cho phép |
| API công khai, không localhost | Đã kiểm tra trực tiếp | HTTPS /api/health trả 200, emailOtpConfigured=true. Các API courses/sessions/history/users/audit/explanations trả 401 khi chưa đăng nhập. API URL mặc định trong lib/core/api.dart là HTTPS công khai |
| Đăng ký qua email hoặc OAuth2 | Đã có và người dùng xác nhận | Chọn phương án đăng ký email và xác thực OTP. OAuth2 là phương án thay thế, không bắt buộc làm cả hai |
| Tên đăng nhập + mật khẩu + OTP | Đã có và người dùng xác nhận thực tế | Mật khẩu được kiểm tra trước khi gửi OTP. OTP 6 số, 10 phút, tối đa 5 lần thử, dùng một lần. Backend không cấp token chỉ bằng mật khẩu. Tài khoản quản trị đã đăng ký, nhận OTP và đăng nhập thành công |
| Phân quyền vào trang tương ứng | Đã có; đã kiểm thử sandbox | Server kiểm tra vai trò và lớp giảng viên phụ trách; UI thay tab/hành động theo vai trò. Admin đã cấp trên production. Chưa có xác nhận cả nhóm đã đăng nhập từng vai trò bằng tài khoản thật |
| CRUD 4,5 điểm | Đã triển khai và kiểm thử | Lớp, buổi học, thành viên, giải trình, hồ sơ và quản trị tài khoản. Không suy ra chắc chắn đạt trọn 4,5 điểm vì thầy còn đánh giá cách trình bày và hoạt động thực tế |
| 3 chức năng 3,5 điểm | Có mã triển khai; chưa kiểm chứng thiết bị thật | Đúng ba lựa chọn b/d/e: chia sẻ GPS, đo chuyển động, quét QR. Thư viện geolocator/sensors_plus/mobile_scanner; không phải ba nút giả. Tuy nhiên chưa kiểm tra camera nhận QR ngoài thực tế, GPS trên điện thoại và cảm biến vật lý |
| Tính năng mới 1 điểm | Rủi ro cao | Giải trình/duyệt/có phép không đủ để tự khẳng định là tính năng chưa có. Moodle đã hỗ trợ Excused và ghi chú; Jibble đã có yêu cầu chờ duyệt/chấp nhận/từ chối. Cần xác định điểm khác biệt cụ thể hoặc bổ sung ý tưởng khác và được thầy chấp nhận |
| Giao diện đẹp/dễ dùng 1 điểm | Có giao diện riêng; đánh giá một phần chủ quan | Đã xem trên máy ảo và chạy luồng quản trị. Chưa kiểm thử nhiều kích thước điện thoại; chưa có xác nhận tất cả thành viên chạy được |
| Hai frontend giống nhau | Không thể xác nhận cho cả lớp | Source này được thiết kế riêng cho Vĩnh; không có source của tất cả sinh viên khác để đối chiếu. Các thành viên không được sao chép frontend này để nộp như bài cá nhân |
| Hạn nộp và link nộp | Chưa xác nhận việc nộp | Hạn theo đề: 23:59 ngày 29/10/2026. Người dùng chưa cung cấp link nộp. Có APK và ZIP source, không đồng nghĩa đã nộp bài |

## Kiểm tra chạy lại trong lần rà soát này

- Flutter analyze: không có lỗi/cảnh báo phân tích.
- Flutter test: 3 bài kiểm thử đạt, gồm URL HTTPS public, kiểm tra form và giữ ngưỡng đi muộn khi sửa buổi học.
- API sandbox: chạy lại 48 kiểm tra trên database cục bộ riêng cho lần audit, không thay đổi dữ liệu production và không gửi mail thật.
- Backend TypeScript: tsc --noEmit.
- API production: health và kiểm tra truy cập không đăng nhập như bảng trên.
- Kiểm thử Android tự động trước đó đã đạt luồng mật khẩu/OTP sandbox, khôi phục Admin, tạo lớp/buổi học, QR và đăng xuất. Luồng đó KHÔNG phải kiểm thử camera quét QR + GPS vật lý đầu cuối.
- Email thật: bằng chứng người dùng đã xác nhận nhận OTP và đăng nhập thành công; không dùng kết quả sandbox thay cho bằng chứng gửi mail thật.

## Lỗi đã sửa

Trong lib/screens/classes.dart, SessionEditor trước đây đặt ngưỡng đi muộn mặc định 15 phút cả khi sửa một buổi học đã có cấu hình khác. Đã đổi sang đọc late_minutes từ dữ liệu hiện tại và thêm kiểm thử hồi quy với giá trị 7 phút. Khi chỉ sửa tên/lịch, ngưỡng đi muộn không tự bị ghi đè nữa.

## Việc cần làm trước khi tự tin nộp

1. Mượn ít nhất một điện thoại Android thật. Có thể dùng máy ảo/màn hình laptop hiển thị QR giảng viên và điện thoại thật quét mã. Thử cấp/từ chối quyền camera/GPS, quét trùng, mã mới/cũ, bật cảm biến và lắc/di chuyển điện thoại.
2. Kiểm tra vị trí thực tế. Hàm getLocation() đang từ chối Position.isMocked, nên không dùng GPS giả lập của máy ảo để tuyên bố đã kiểm chứng chức năng thật. Không bỏ kiểm tra này hoặc giả kết quả để lấy bằng chứng đạt.
3. Tạo tài khoản thật cho giảng viên và sinh viên của nhóm; Admin cấp quyền, kiểm tra dữ liệu mỗi vai trò và quyền không xem/sửa lớp người khác.
4. Củng cố tiêu chí tính năng mới. Hướng có thể xem xét là phiếu sự cố QR/GPS có chẩn đoán tự động, dòng thời gian bằng chứng và cơ chế duyệt riêng. Đây mới là đề xuất, CHƯA được triển khai trong bản hiện tại và cũng không bảo đảm chưa tồn tại ở mọi ứng dụng khác.
5. Đối chiếu lại phạm vi ba chức năng với nội dung thuyết trình của lớp và tập kịch bản demo ngắn.
6. Thử APK trên máy của các thành viên, khác mạng Wi-Fi hoặc 4G. Kiểm tra Gmail không đưa OTP vào Spam và chưa hết hạn mức gửi mail.
7. Nộp APK release + ZIP source đã loại khóa riêng vào đúng link của thầy trước hạn. Không chia sẻ .private.env hoặc .email-setup.json.

## Nguồn đối chiếu tính năng đã tồn tại

- Moodle Attendance: trạng thái Present/Absent/Late/Excused và ghi chú: https://docs.moodle.org/500/en/Attendance_quick_guide
- Jibble: yêu cầu có trạng thái Pending/Approved/Cancelled/Rejected và sửa/hủy trước duyệt: https://www.jibble.io/help/requesting-and-managing-time-off-as-a-member

Các nguồn này cho thấy những thành phần của ý tưởng giải trình đã tồn tại; không chứng minh hai sản phẩm hoàn toàn giống CatCheck. Vì vậy đánh giá đúng là tiêu chí mới chưa được chứng minh, không phải kết luận chắc chắn thầy sẽ cho 0 điểm mục này.
