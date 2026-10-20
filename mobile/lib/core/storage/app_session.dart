/// Trạng thái phiên làm việc trong RAM (không lưu đĩa).
/// Mỗi lần mở app từ đầu (cold start) `unlocked = false`, buộc người dùng
/// xác thực bằng FaceID / mật khẩu trước khi vào Trang chủ.
class AppSession {
  AppSession._();

  static bool unlocked = false;
}
