class ApiResponse<T> {
  final bool success;
  final String? message;
  final String? errorCode;
  final T? data;

  const ApiResponse({required this.success, this.message, this.errorCode, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? data) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message'] as String?,
      errorCode: json['errorCode'] as String?,
      data: data,
    );
  }
}

Exception apiException(Map<String, dynamic> json) {
  return Exception(json['message'] ?? json['errorCode'] ?? 'Yêu cầu thất bại');
}

String extractErrorMessage(dynamic error) {
  if (error == null) return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
  
  // Xử lý chuỗi thông điệp
  var raw = error.toString().replaceAll('Exception: ', '').trim();
  
  // Xóa các tiền tố lỗi của Dio / HTTP nếu có
  if (raw.startsWith('DioException')) {
    final parts = raw.split('\n');
    for (final p in parts) {
      if (!p.startsWith('DioException') && p.trim().isNotEmpty) {
        raw = p.replaceAll('Error: ', '').trim();
        break;
      }
    }
  }

  // Khóa tài khoản / Quá nhiều lần sai
  if (raw.contains('temporarily locked') || raw.contains('too many failed') || raw.contains('ACCOUNT_LOCKED') || raw.contains('LOCKED')) {
    return 'Tài khoản đã bị tạm khóa 15 phút do nhập sai thông tin xác thực quá 3 lần. Vui lòng thử lại sau hoặc cấp lại mã PIN.';
  }
  
  // Lỗi mã PIN
  if (raw.contains('Invalid PIN') || raw.contains('INVALID_PIN')) {
    return 'Mã PIN giao dịch không chính xác. Vui lòng kiểm tra lại.';
  }
  if (raw.contains('PIN has not been set') || raw.contains('PIN_NOT_SET')) {
    return 'Bạn chưa thiết lập mã PIN giao dịch. Vui lòng cài đặt mã PIN.';
  }

  // Số dư & Hạn mức
  if (raw.contains('INSUFFICIENT_BALANCE') || raw.contains('không đủ số dư') || raw.contains('Số dư không đủ')) {
    return 'Số dư khả dụng trong ví không đủ để thực hiện giao dịch này.';
  }
  if (raw.contains('LIMIT_EXCEEDED') || raw.contains('vượt hạn mức') || raw.contains('exceeded limit')) {
    return 'Giao dịch vượt quá hạn mức tối đa cho phép trong ngày hoặc theo lượt.';
  }

  // Lỗi OTP
  if (raw.contains('INVALID_OTP') || raw.contains('OTP không hợp lệ') || raw.contains('Invalid OTP')) {
    return 'Mã OTP xác thực không chính xác. Vui lòng kiểm tra tin nhắn.';
  }
  if (raw.contains('OTP_EXPIRED') || raw.contains('hết hạn') && raw.contains('OTP')) {
    return 'Mã OTP đã hết thời hạn hiệu lực (5 phút). Vui lòng yêu cầu gửi lại mã mới.';
  }

  // Tài khoản & Đăng nhập
  if (raw.contains('INVALID_CREDENTIALS') || raw.contains('Sai mật khẩu') || raw.contains('Mật khẩu không đúng')) {
    return 'Số điện thoại hoặc mật khẩu đăng nhập không chính xác.';
  }
  if (raw.contains('USER_NOT_FOUND') || raw.contains('không tìm thấy người dùng')) {
    return 'Tài khoản người dùng không tồn tại trên hệ thống.';
  }
  if (raw.contains('WALLET_NOT_FOUND') || raw.contains('Ví không tồn tại')) {
    return 'Không tìm thấy ví thanh toán hoặc tài khoản thụ hưởng.';
  }
  if (raw.contains('PHONE_ALREADY_EXISTS') || raw.contains('Số điện thoại đã tồn tại')) {
    return 'Số điện thoại này đã được đăng ký tài khoản SenBank.';
  }
  if (raw.contains('CANNOT_TRANSFER_TO_SELF') || raw.contains('chính mình')) {
    return 'Không thể thực hiện chuyển tiền cho chính tài khoản của bạn.';
  }
  if (raw.contains('BENEFICIARY_EXISTS')) {
    return 'Người thụ hưởng này đã có trong danh bạ lưu của bạn.';
  }
  if (raw.contains('TRANSACTION_NOT_FOUND')) {
    return 'Không tìm thấy chi tiết giao dịch tương ứng.';
  }

  // Phiên & Quyền truy cập
  if (raw.contains('Phiên đăng nhập đã hết hạn') || raw.contains('jwt expired') || raw.contains('Token expired')) {
    return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để tiếp tục.';
  }
  if (raw.contains('403') || raw.contains('Forbidden')) {
    return 'Từ chối truy cập. Bạn không có quyền thực hiện thao tác này.';
  }
  if (raw.contains('SocketException') || raw.contains('Failed host lookup') || raw.contains('Network is unreachable')) {
    return 'Không có kết nối mạng. Quý khách vui lòng kiểm tra lại wifi/4G.';
  }
  if (raw.contains('500') || raw.contains('INTERNAL_SERVER_ERROR')) {
    return 'Hệ thống ngân hàng đang bận xử lý hoặc tạm thời bảo trì. Vui lòng thử lại sau.';
  }

  // Khóa giải mã cục bộ thiết bị (Android KeyStore / BadPaddingException)
  if (raw.contains('BadPaddingException') ||
      raw.contains('BAD_DECRYPT') ||
      raw.contains('KeyStore') ||
      raw.contains('Cipher functions')) {
    return 'Khóa bảo mật phiên bản trên máy vừa được cập nhật an toàn. Quý khách vui lòng bấm Đăng nhập lại.';
  }

  // Xử lý các lỗi hệ thống native / PlatformException (Sinh trắc học, Quyền Camera...)
  if (raw.contains('PlatformException')) {
    if (raw.contains('NotAvailable') || raw.contains('not available')) {
      return 'Thiết bị chưa cài đặt hoặc không hỗ trợ sinh trắc học.';
    }
    if (raw.contains('LockedOut') || raw.contains('PermanentlyLockedOut')) {
      return 'Xác thực sinh trắc học bị tạm khóa do thử sai nhiều lần. Quý khách vui lòng nhập mã PIN.';
    }
    if (raw.contains('PasscodeNotSet')) {
      return 'Vui lòng cài đặt bảo mật khóa màn hình trên thiết bị trước.';
    }
    if (raw.contains('camera_access_denied') || raw.contains('PERMISSION_NOT_GRANTED')) {
      return 'Vui lòng cấp quyền truy cập máy ảnh trong Cài đặt để quét mã.';
    }
    return 'Lỗi giao tiếp phần cứng trên thiết bị. Quý khách vui lòng thử lại.';
  }
  
  if (raw.startsWith('DioException')) {
    return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng và thử lại.';
  }
  
  return raw;
}