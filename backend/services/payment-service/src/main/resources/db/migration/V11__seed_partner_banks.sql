-- Seed top partner banks and SenHong Bank for bank-account linking and VietQR
INSERT INTO banks (id, code, name, short_name, bin, logo_url, is_active)
VALUES 
  ('bank-vcb', 'VCB', 'Ngân hàng TMCP Ngoại Thương Việt Nam', 'Vietcombank', '970436', 'https://cdn.vietqr.io/img/VCB.png', true),
  ('bank-mbb', 'MBB', 'Ngân hàng TMCP Quân Đội', 'MBBank', '970422', 'https://cdn.vietqr.io/img/MB.png', true),
  ('bank-tcb', 'TCB', 'Ngân hàng TMCP Kỹ Thương Việt Nam', 'Techcombank', '970407', 'https://cdn.vietqr.io/img/TCB.png', true),
  ('bank-vpb', 'VPB', 'Ngân hàng TMCP Việt Nam Thịnh Vượng', 'VPBank', '970432', 'https://cdn.vietqr.io/img/VPB.png', true),
  ('bank-icb', 'CTG', 'Ngân hàng TMCP Công Thương Việt Nam', 'VietinBank', '970415', 'https://cdn.vietqr.io/img/ICB.png', true),
  ('bank-bidv', 'BIDV', 'Ngân hàng TMCP Đầu Tư và Phát Triển Việt Nam', 'BIDV', '970418', 'https://cdn.vietqr.io/img/BIDV.png', true),
  ('bank-acb', 'ACB', 'Ngân hàng TMCP Á Châu', 'ACB', '970416', 'https://cdn.vietqr.io/img/ACB.png', true),
  ('bank-senhong', 'SENHONG', 'Ngân hàng Số Sen Hồng', 'SenHong Bank', '970499', 'https://cdn.vietqr.io/img/SENHONG.png', true)
ON CONFLICT (code) DO NOTHING;

