-- Mở rộng độ dài cột code của ledger_accounts từ VARCHAR(20) lên VARCHAR(100)
-- để hỗ trợ mã tài khoản ví đầy đủ dạng 'W:<walletId>' hoặc UUID mà không bị cắt ngắn gây trùng lặp khóa.
ALTER TABLE ledger_accounts ALTER COLUMN code TYPE VARCHAR(100);
