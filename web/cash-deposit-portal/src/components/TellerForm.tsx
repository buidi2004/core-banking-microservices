import React, { useState, useMemo } from 'react';
import { CustomerAccount, SearchMethod } from '../types';
import { AUTO_APPROVE_LIMIT } from '../data';
import { formatCurrency, numberToVietnameseWords } from '../utils';
import { Phone, IdCard, Wallet, Search, ShieldCheck, AlertCircle, Banknote, Zap, ShieldAlert, ArrowRight, Lock } from 'lucide-react';

interface TellerFormProps {
  onSubmit: (data: {
    accountNumber: string;
    customerName: string;
    citizenId: string;
    phoneNumber: string;
    amount: number;
    note: string;
  }) => void;
  accounts: CustomerAccount[];
}

export function TellerForm({ onSubmit, accounts }: TellerFormProps) {
  const [searchMethod, setSearchMethod] = useState<SearchMethod>('PHONE');
  const [query, setQuery] = useState('0901234567');
  const [amount, setAmount] = useState<number>(10_000_000);
  const [note, setNote] = useState('Nộp tiền mặt tại quầy Chi nhánh Quận 1');

  // Tìm kiếm khách hàng theo phương thức
  const matchedCustomer = useMemo<CustomerAccount | undefined>(() => {
    const q = query.trim().toLowerCase();
    if (!q) return undefined;
    return accounts.find(a => {
      if (searchMethod === 'PHONE') return a.phoneNumber.toLowerCase().includes(q);
      if (searchMethod === 'CITIZEN_ID') return a.citizenId.toLowerCase().includes(q);
      return a.accountNumber.toLowerCase().includes(q);
    });
  }, [query, searchMethod, accounts]);

  const isAutoApprove = amount <= AUTO_APPROVE_LIMIT;
  const isBlocked = matchedCustomer?.status === 'BLOCKED';

  const quickAmounts = [
    1_000_000, 2_000_000, 5_000_000, 10_000_000,
    20_000_000, 50_000_000, 100_000_000, 200_000_000
  ];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!matchedCustomer) {
      alert('Không tìm thấy thông tin khách hàng trên hệ thống!');
      return;
    }
    if (isBlocked) {
      alert('LỖI NGHIỆP VỤ: Ví của khách hàng đang ở trạng thái BỊ KHÓA (BLOCKED). Không thể thực hiện giao dịch nạp tiền!');
      return;
    }
    if (amount <= 0) {
      alert('Số tiền nộp phải lớn hơn 0 VND');
      return;
    }

    onSubmit({
      accountNumber: matchedCustomer.accountNumber,
      customerName: matchedCustomer.customerName,
      citizenId: matchedCustomer.citizenId,
      phoneNumber: matchedCustomer.phoneNumber,
      amount,
      note,
    });
  };

  return (
    <div className="card">
      <div className="card-header">
        <div className="card-title-text" style={{ fontSize: '15px', fontWeight: 800, color: 'var(--primary-navy)' }}>
          <Banknote size={19} color="var(--primary-blue)" />
          <span>LẬP LỆNH NỘP TIỀN MẶT VÀO VÍ ĐIỆN TỬ</span>
        </div>
        <span className="status-badge badge-verified">
          <ShieldCheck size={13} />
          <span>Quầy Giao Dịch: BR_Q1</span>
        </span>
      </div>

      <form onSubmit={handleSubmit}>
        {/* Tab Phương thức tra cứu */}
        <label className="form-label">Chọn phương thức tra cứu khách hàng:</label>
        <div className="search-tabs">
          <button
            type="button"
            className={`search-tab-btn ${searchMethod === 'PHONE' ? 'active' : ''}`}
            onClick={() => { setSearchMethod('PHONE'); setQuery('0901234567'); }}
          >
            <Phone size={14} />
            <span>Số Điện Thoại</span>
          </button>
          <button
            type="button"
            className={`search-tab-btn ${searchMethod === 'CITIZEN_ID' ? 'active' : ''}`}
            onClick={() => { setSearchMethod('CITIZEN_ID'); setQuery('079204001234'); }}
          >
            <IdCard size={14} />
            <span>Số Căn Cước (CCCD)</span>
          </button>
          <button
            type="button"
            className={`search-tab-btn ${searchMethod === 'ACCOUNT_NUMBER' ? 'active' : ''}`}
            onClick={() => { setSearchMethod('ACCOUNT_NUMBER'); setQuery('W-ALICE-1001'); }}
          >
            <Wallet size={14} />
            <span>Số Tài Khoản Ví</span>
          </button>
        </div>

        {/* Ô tìm kiếm thông minh */}
        <div className="form-group">
          <label className="form-label">
            {searchMethod === 'PHONE' && 'Nhập Số điện thoại liên kết ví (10 chữ số):'}
            {searchMethod === 'CITIZEN_ID' && 'Nhập Số Căn cước công dân gắn chip (12 chữ số):'}
            {searchMethod === 'ACCOUNT_NUMBER' && 'Nhập Số tài khoản ví khách hàng:'}
          </label>
          <div className="input-with-icon">
            <span className="input-icon">
              <Search size={16} />
            </span>
            <input
              type="text"
              className="form-input mono"
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder={
                searchMethod === 'PHONE' ? 'Ví dụ: 0901234567...' :
                searchMethod === 'CITIZEN_ID' ? 'Ví dụ: 079090123456...' : 'Ví dụ: W-ALICE-1001...'
              }
            />
          </div>
        </div>

        {/* Thẻ Khách Hàng (Customer KYC Card) */}
        {matchedCustomer ? (
          <div className="customer-kyc-card">
            <div className="customer-kyc-header">
              <div className="customer-avatar-info">
                <div className="customer-avatar">
                  {matchedCustomer.customerName.charAt(0)}
                </div>
                <div>
                  <div style={{ fontWeight: 800, fontSize: '15px', color: 'var(--primary-navy)' }}>
                    {matchedCustomer.customerName.toUpperCase()}
                  </div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                    {matchedCustomer.branchName}
                  </div>
                </div>
              </div>
              <div>
                {matchedCustomer.status === 'ACTIVE' ? (
                  <span className="status-badge badge-completed">
                    <ShieldCheck size={12} />
                    <span>ĐANG HOẠT ĐỘNG</span>
                  </span>
                ) : (
                  <span className="status-badge badge-blocked">
                    <Lock size={12} />
                    <span>TÀI KHOẢN BỊ KHÓA</span>
                  </span>
                )}
              </div>
            </div>

            <div className="customer-grid">
              <div className="customer-grid-item">
                <span>Số điện thoại: </span>
                <span className="mono">{matchedCustomer.phoneNumber}</span>
              </div>
              <div className="customer-grid-item">
                <span>Số CCCD (12 số): </span>
                <span className="mono">{matchedCustomer.citizenId}</span>
              </div>
              <div className="customer-grid-item">
                <span>Số tài khoản ví: </span>
                <span className="mono">{matchedCustomer.accountNumber}</span>
              </div>
              <div className="customer-grid-item">
                <span>Số dư khả dụng: </span>
                <span className="mono" style={{ color: 'var(--primary-blue)', fontWeight: 800 }}>
                  {formatCurrency(matchedCustomer.balance)}
                </span>
              </div>
            </div>

            <div style={{ fontSize: '11.5px', display: 'flex', alignItems: 'center', gap: '6px', color: '#047857', fontWeight: 600 }}>
              <ShieldCheck size={14} />
              <span>Định danh điện tử: ĐÃ ĐỐI SOÁT SINH TRẮC HỌC QUA C06 BỘ CÔNG AN</span>
            </div>
          </div>
        ) : (
          <div style={{
            background: '#fff1f2',
            border: '1px solid #fecdd3',
            color: '#be123c',
            padding: '12px 14px',
            fontSize: '13px',
            marginBottom: '16px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            <AlertCircle size={16} />
            <span>Không tìm thấy khách hàng khớp với thông tin tra cứu trên hệ thống Core Banking.</span>
          </div>
        )}

        {/* Số tiền nộp */}
        <div className="form-group">
          <label className="form-label">Số tiền mặt nộp vào ví (VND):</label>
          <div className="input-with-icon">
            <span className="input-icon">
              <Banknote size={18} />
            </span>
            <input
              type="number"
              className="form-input mono"
              style={{ fontSize: '17px', fontWeight: 800, color: 'var(--success-green)' }}
              value={amount}
              onChange={e => setAmount(Number(e.target.value))}
              step={100_000}
              min={100_000}
            />
          </div>

          {/* Đọc tiền thành chữ */}
          <div className="amount-words-box">
            <b>Bằng chữ:</b> {numberToVietnameseWords(amount)}
          </div>

          {/* Mệnh giá nhanh - Bo Viên Thuốc */}
          <div style={{ marginTop: '10px' }}>
            <span style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)' }}>MỆNH GIÁ NHANH:</span>
            <div className="quick-amounts">
              {quickAmounts.map(val => (
                <button
                  key={val}
                  type="button"
                  className={`amount-btn ${amount === val ? 'active' : ''}`}
                  onClick={() => setAmount(val)}
                >
                  {val >= 1_000_000 ? `${val / 1_000_000}M` : `${val / 1_000}K`}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Nội dung giao dịch */}
        <div className="form-group">
          <label className="form-label">Nội dung / Diễn giải nộp tiền:</label>
          <input
            type="text"
            className="form-input"
            style={{ paddingLeft: '14px' }}
            value={note}
            onChange={e => setNote(e.target.value)}
          />
        </div>

        {/* Cảnh báo phân luồng duyệt */}
        <div className={`rule-callout ${isAutoApprove ? 'auto' : 'maker-checker'}`}>
          {isAutoApprove ? <Zap size={20} color="var(--success-green)" /> : <ShieldAlert size={20} color="var(--warning-amber)" />}
          <div>
            {isAutoApprove ? (
              <div>
                <b>HẠN MỨC ≤ 50,000,000 VND: TỰ ĐỘNG DUYỆT TỨC THÌ</b>
                <div style={{ fontSize: '11.5px', opacity: 0.9 }}>
                  Hệ thống kiểm toán tự động cộng tiền ví khách hàng và xuất biên lai ngay lập tức.
                </div>
              </div>
            ) : (
              <div>
                <b>HẠN MỨC &gt; 50,000,000 VND: YÊU CẦU KIỂM SOÁT VIÊN DUYỆT</b>
                <div style={{ fontSize: '11.5px', opacity: 0.9 }}>
                  Giao dịch sẽ được chuyển sang hàng đợi của Kiểm soát viên (Manager) theo quy chuẩn Maker-Checker.
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Submit Button - Bo Viên Thuốc */}
        <div style={{ marginTop: '20px' }}>
          <button
            type="submit"
            className="btn btn-primary"
            style={{ width: '100%', padding: '13px', fontSize: '14.5px' }}
            disabled={!matchedCustomer || isBlocked}
          >
            {isBlocked ? (
              <>
                <Lock size={16} />
                <span>TÀI KHOẢN ĐANG BỊ KHÓA — KHÔNG THỂ NẠP TIỀN</span>
              </>
            ) : isAutoApprove ? (
              <>
                <Zap size={16} />
                <span>XÁC NHẬN NẠP TIỀN &amp; IN BIÊN LAI NGAY</span>
                <ArrowRight size={16} />
              </>
            ) : (
              <>
                <ShieldAlert size={16} />
                <span>GỬI LỆNH SANG KIỂM SOÁT VIÊN PHÊ DUYỆT</span>
                <ArrowRight size={16} />
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}