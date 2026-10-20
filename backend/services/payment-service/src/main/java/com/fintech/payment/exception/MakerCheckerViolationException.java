package com.fintech.payment.exception;

/**
 * Ngoại lệ ném ra khi vi phạm nguyên tắc 4 mắt (Four-Eyes Principle / Maker-Checker Rule).
 * Cán bộ lập lệnh (Maker) không được phép tự phê duyệt hoặc kiểm soát lệnh của chính mình.
 */
public class MakerCheckerViolationException extends IllegalStateException {

    private final String makerId;
    private final String checkerId;

    public MakerCheckerViolationException(String message) {
        super(message);
        this.makerId = null;
        this.checkerId = null;
    }

    public MakerCheckerViolationException(String makerId, String checkerId) {
        super(String.format("Vi phạm nguyên tắc Maker-Checker: Cán bộ lập lệnh (Maker: %s) không thể tự làm Kiểm soát viên (Checker: %s) để phê duyệt!", makerId, checkerId));
        this.makerId = makerId;
        this.checkerId = checkerId;
    }

    public String getMakerId() {
        return makerId;
    }

    public String getCheckerId() {
        return checkerId;
    }
}
