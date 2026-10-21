package com.fintech.identity.service;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:noreply@senhongbank.com.vn}")
    private String senderEmail;

    /**
     * Gửi email OTP bất đồng bộ (chạy trên thread riêng)
     */
    @Async
    public void sendOtpEmail(String recipientEmail, String otpCode, String purpose) {
        if (recipientEmail == null || recipientEmail.isBlank()) {
            log.warn("[EmailService] Bỏ qua gửi email do địa chỉ email trống");
            return;
        }

        try {
            log.info("[EmailService] Đang gửi mã OTP={} tới email={} (purpose={})...", otpCode, recipientEmail, purpose);

            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    mimeMessage,
                    MimeMessageHelper.MULTIPART_MODE_MIXED_RELATED,
                    StandardCharsets.UTF_8.name()
            );

            helper.setFrom(senderEmail, "Sen Hồng Bank");
            helper.setTo(recipientEmail);
            helper.setSubject("[Sen Hồng Bank] Mã xác thực OTP của Quý khách");

            String html = buildOtpHtml(otpCode, purpose);
            helper.setText(html, true);

            mailSender.send(mimeMessage);
            log.info("[EmailService] Gửi email OTP tới {} thành công!", recipientEmail);
        } catch (Exception e) {
            log.error("[EmailService] Lỗi khi gửi email OTP tới {}: {}", recipientEmail, e.getMessage(), e);
        }
    }

    private String buildOtpHtml(String otpCode, String purpose) {
        String purposeDescription = switch (purpose != null ? purpose.toUpperCase() : "") {
            case "RESET_PIN" -> "Cấp lại mã PIN giao dịch";
            case "FORGOT_PASSWORD" -> "Khôi phục mật khẩu tài khoản ví";
            case "REGISTER" -> "Đăng ký mở tài khoản ví Sen Hồng Bank";
            case "TRANSACTION" -> "Xác thực giao dịch chuyển tiền";
            default -> "Xác minh bảo mật tài khoản";
        };

        return """
            <!DOCTYPE html>
            <html lang="vi">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>Mã xác thực OTP - Sen Hồng Bank</title>
              <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f6f9; margin: 0; padding: 20px; color: #333; }
                .container { max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
                .header { background: linear-gradient(135deg, #0088cc 0%, #005580 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
                .header h1 { margin: 0; font-size: 24px; font-weight: 700; letter-spacing: 0.5px; }
                .header p { margin: 6px 0 0 0; font-size: 13px; opacity: 0.9; }
                .content { padding: 32px 28px; }
                .purpose-badge { display: inline-block; background: #e6f4fa; color: #0077aa; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 600; margin-bottom: 20px; }
                .otp-box { background: #f8fafc; border: 2px dashed #0088cc; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0; }
                .otp-label { font-size: 12px; text-transform: uppercase; color: #64748b; letter-spacing: 1px; font-weight: 600; }
                .otp-code { font-size: 38px; font-weight: 800; color: #0088cc; letter-spacing: 10px; margin: 8px 0; font-family: monospace; }
                .otp-expiry { font-size: 12px; color: #ef4444; font-weight: 600; }
                .notice { background: #fffbeb; border-left: 4px solid #f59e0b; padding: 12px 16px; border-radius: 6px; font-size: 13px; color: #92400e; line-height: 1.5; margin-top: 24px; }
                .footer { background: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>SEN HỒNG BANK</h1>
                  <p>Hệ Thống Ngân Hàng Số & Ví Điện Tử Core Banking</p>
                </div>
                <div class="content">
                  <div class="purpose-badge">{{PURPOSE_DESC}}</div>
                  <p>Kính chào Quý khách,</p>
                  <p>Quý khách vừa thực hiện yêu cầu xác thực trên hệ thống <strong>Sen Hồng Bank</strong>. Dưới đây là mã xác thực OTP dùng một lần của Quý khách:</p>
                  
                  <div class="otp-box">
                    <div class="otp-label">MÃ XÁC THỰC OTP (ONE-TIME PASSWORD)</div>
                    <div class="otp-code">{{OTP_CODE}}</div>
                    <div class="otp-expiry">⏳ Mã có hiệu lực trong 3 phút (180 giây)</div>
                  </div>

                  <div class="notice">
                    <strong>⚠️ CẢNH BÁO BẢO MẬT:</strong><br>
                    Nhân viên Sen Hồng Bank <strong>KHÔNG BAO GIỜ</strong> yêu cầu Quý khách cung cấp mã OTP, mật khẩu hay mã PIN dưới bất kỳ hình thức nào. Tuyệt đối không chia sẻ mã này cho người khác.
                  </div>
                </div>
                <div class="footer">
                  <p>Tổng đài CSKH 24/7: <strong>1900 6868</strong> | Email hỗ trợ: support@senhongbank.com.vn</p>
                  <p>© 2026 Sen Hồng Bank - Core Banking Microservices. All rights reserved.</p>
                </div>
              </div>
            </body>
            </html>
            """
            .replace("{{PURPOSE_DESC}}", purposeDescription)
            .replace("{{OTP_CODE}}", otpCode);
    }
}
