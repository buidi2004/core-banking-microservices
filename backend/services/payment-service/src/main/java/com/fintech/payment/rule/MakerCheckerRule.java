package com.fintech.payment.rule;

import com.fintech.payment.domain.entity.CashDeposit;
import com.fintech.payment.exception.MakerCheckerViolationException;
import org.springframework.stereotype.Component;

/**
 * Quy chuẩn nghiệp vụ cốt lõi Maker-Checker (Four-Eyes Principle / Nguyên tắc 4 mắt)
 * theo chuẩn Core Banking & FinTech Compliance.
 *
 * Quy tắc:
 * 1. Cán bộ lập lệnh (Maker / Giao dịch viên) KHÔNG ĐƯỢC PHÉP tự phê duyệt lệnh của chính mình.
 * 2. Chỉ Kiểm soát viên (Checker / Manager) có ID độc lập khác với Maker mới được quyền phê duyệt hoặc từ chối lệnh.
 * 3. Hạn mức giao dịch thông thường (<= 50,000,000 VND) có thể được tự động duyệt theo cấu hình.
 *    Giao dịch vượt hạn mức (> 50,000,000 VND) bắt buộc phải qua quy trình kiểm soát 2 bước Maker-Checker.
 */
@Component
public class MakerCheckerRule {

    public static final long DEFAULT_AUTO_APPROVE_LIMIT = 50_000_000L; // 50,000,000 VND

    private final long autoApproveLimit;

    public MakerCheckerRule() {
        this(DEFAULT_AUTO_APPROVE_LIMIT);
    }

    public MakerCheckerRule(long autoApproveLimit) {
        this.autoApproveLimit = autoApproveLimit;
    }

    /**
     * Xác thực tính độc lập giữa Maker và Checker theo nguyên tắc 4 mắt.
     *
     * @param makerId ID của cán bộ lập lệnh
     * @param checkerId ID của cán bộ kiểm soát/phê duyệt
     * @throws IllegalArgumentException nếu makerId hoặc checkerId bị rỗng/null
     * @throws MakerCheckerViolationException nếu makerId trùng với checkerId
     */
    public void validateDifferentActors(String makerId, String checkerId) {
        if (makerId == null || makerId.isBlank()) {
            throw new IllegalArgumentException("Maker ID không được để trống");
        }
        if (checkerId == null || checkerId.isBlank()) {
            throw new IllegalArgumentException("Checker ID không được để trống");
        }
        if (makerId.trim().equalsIgnoreCase(checkerId.trim())) {
            throw new MakerCheckerViolationException(makerId.trim(), checkerId.trim());
        }
    }

    /**
     * Kiểm tra xem cặp actor (makerId, checkerId) có vi phạm quy chuẩn Maker-Checker hay không.
     *
     * @return true nếu cùng một người (vi phạm), false nếu là 2 người khác nhau hợp lệ.
     */
    public boolean isViolation(String makerId, String checkerId) {
        if (makerId == null || checkerId == null || makerId.isBlank() || checkerId.isBlank()) {
            return false;
        }
        return makerId.trim().equalsIgnoreCase(checkerId.trim());
    }

    /**
     * Kiểm tra xem số tiền nạp có yêu cầu phê duyệt Maker-Checker của cấp quản lý hay không.
     *
     * @param amount Số tiền nạp (VND)
     * @return true nếu vượt hạn mức tự duyệt (> 50M VND), false nếu trong hạn mức.
     */
    public boolean requiresCheckerApproval(long amount) {
        return amount > autoApproveLimit;
    }

    /**
     * Phê duyệt lệnh nạp tiền tại quầy, đảm bảo tuân thủ nghiêm ngặt nguyên tắc Maker != Checker.
     *
     * @param deposit Bản ghi lệnh nạp tiền
     * @param checkerId ID của Kiểm soát viên thực hiện duyệt
     */
    public void approveDeposit(CashDeposit deposit, String checkerId) {
        if (deposit == null) {
            throw new IllegalArgumentException("Lệnh nạp tiền không tồn tại");
        }
        validateDifferentActors(deposit.getMakerId(), checkerId);
        deposit.approve(checkerId);
    }

    /**
     * Từ chối lệnh nạp tiền tại quầy, cũng bắt buộc Kiểm soát viên phải khác Maker.
     *
     * @param deposit Bản ghi lệnh nạp tiền
     * @param checkerId ID của Kiểm soát viên thực hiện từ chối
     * @param reason Lý do từ chối
     */
    public void rejectDeposit(CashDeposit deposit, String checkerId, String reason) {
        if (deposit == null) {
            throw new IllegalArgumentException("Lệnh nạp tiền không tồn tại");
        }
        validateDifferentActors(deposit.getMakerId(), checkerId);
        deposit.reject(checkerId, reason);
    }

    public long getAutoApproveLimit() {
        return autoApproveLimit;
    }
}
