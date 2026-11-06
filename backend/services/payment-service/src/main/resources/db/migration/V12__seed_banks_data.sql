-- V12: Khởi tạo danh mục Ngân hàng Việt Nam (NAPAS 247) phục vụ liên kết tài khoản và VietQR

INSERT INTO banks (id, code, name, short_name, bin, logo_url, is_active, created_at)
VALUES
    ('bank-vcb', 'VCB', 'Ngân hàng TMCP Ngoại thương Việt Nam', 'Vietcombank', '970436', 'https://cdn.senhongbank.vn/banks/vcb.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-ctg', 'CTG', 'Ngân hàng TMCP Công thương Việt Nam', 'VietinBank', '970415', 'https://cdn.senhongbank.vn/banks/ctg.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-bidv', 'BIDV', 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam', 'BIDV', '970418', 'https://cdn.senhongbank.vn/banks/bidv.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-mbb', 'MBB', 'Ngân hàng TMCP Quân đội', 'MBBank', '970422', 'https://cdn.senhongbank.vn/banks/mbb.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-tcb', 'TCB', 'Ngân hàng TMCP Kỹ thương Việt Nam', 'Techcombank', '970407', 'https://cdn.senhongbank.vn/banks/tcb.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-acb', 'ACB', 'Ngân hàng TMCP Á Châu', 'ACB', '970416', 'https://cdn.senhongbank.vn/banks/acb.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-vpb', 'VPB', 'Ngân hàng TMCP Việt Nam Thịnh Vượng', 'VPBank', '970432', 'https://cdn.senhongbank.vn/banks/vpb.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-tpb', 'TPB', 'Ngân hàng TMCP Tiên Phong', 'TPBank', '970423', 'https://cdn.senhongbank.vn/banks/tpb.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-stb', 'STB', 'Ngân hàng TMCP Sài Gòn Thương Tín', 'Sacombank', '970403', 'https://cdn.senhongbank.vn/banks/stb.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-hdb', 'HDB', 'Ngân hàng TMCP Phát triển TP.HCM', 'HDBank', '970437', 'https://cdn.senhongbank.vn/banks/hdb.png', TRUE, CURRENT_TIMESTAMP),
    ('bank-sen', 'SENBANK', 'Ngân hàng Số Sen Hồng Core Banking', 'Sen Hồng Bank', '970499', 'https://cdn.senhongbank.vn/banks/senbank.png', TRUE, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

