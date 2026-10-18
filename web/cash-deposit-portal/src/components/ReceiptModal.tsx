import React from 'react';
import { CashDeposit } from '../types';
import { formatCurrency, formatDateVi, numberToVietnameseWords } from '../utils';
import { Printer, X, FileText, CheckCircle2 } from 'lucide-react';

interface ReceiptModalProps {
  deposit: CashDeposit;
  tellerName: string;
  onClose: () => void;
  onPrint: () => void;
}

export function ReceiptModal({ deposit, tellerName, onClose, onPrint }: ReceiptModalProps) {
  const hashDisplay = deposit.hash || 'SHA256: 4a8f9c1b3e2d5a7f8e0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f';

  return (
    <div className="modal-overlay">
      <div className="modal-content printable-receipt">
        {/* Header Ngân Hàng */}
        <div style={{ textAlign: 'center', borderBottom: '2px solid #0c2340', paddingBottom: '14px', marginBottom: '18px' }}>
          <div style={{ fontSize: '12px', fontWeight: 800, letterSpacing: '1.5px', color: '#0369a1' }}>
            HỆ THỐNG NGÂN HÀNG SỐ VIỆT NAM — CORE BANKING
          </div>
          <div style={{ fontSize: '20px', fontWeight: 900, color: '#0c2340', margin: '4px 0' }}>
            GIẤY NỘP TIỀN MẶT VÀO VÍ ĐIỆN TỬ
          </div>
          <div style={{ fontSize: '12px', color: '#64748b' }}>
            Mã giao dịch: <b style={{ fontFamily: 'monospace', color: '#0c2340' }}>{deposit.code}</b> | Chi nhánh: <b>Quận 1, TP.HCM (BR_Q1)</b>
          </div>
        </div>

        {/* Nội dung giao dịch chi tiết */}
        <div style={{ fontSize: '13px', lineHeight: 1.85, marginBottom: '18px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: '#64748b' }}>Thời gian thực hiện:</span>
            <span style={{ fontWeight: 600 }}>{formatDateVi(deposit.timestamp)}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: '#64748b' }}>Họ tên khách hàng:</span>
            <span style={{ fontWeight: 800, color: '#0c2340', fontSize: '14px' }}>{deposit.customerName.toUpperCase()}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: '#64748b' }}>Số CCCD / CMND (12 số):</span>
            <span style={{ fontWeight: 700, fontFamily: 'monospace', color: '#0284c7' }}>{deposit.citizenId || '079090123456'}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: '#64748b' }}>Số ĐT liên kết ví:</span>
            <span style={{ fontWeight: 700, fontFamily: 'monospace', color: '#0284c7' }}>{deposit.phoneNumber || deposit.accountNumber}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: '#64748b' }}>Số tài khoản ví:</span>
            <span style={{ fontWeight: 600, fontFamily: 'monospace' }}>{deposit.accountNumber}</span>
          </div>
          
          <div style={{ display: 'flex', justifyContent: 'space-between', borderTop: '1px dashed #cbd5e1', paddingTop: '8px', marginTop: '8px' }}>
            <span style={{ color: '#64748b', fontSize: '14px', fontWeight: 600 }}>Số tiền mặt nộp:</span>
            <span style={{ fontWeight: 900, fontSize: '19px', color: '#16a34a' }}>{formatCurrency(deposit.amount)}</span>
          </div>
          <div>
            <span style={{ color: '#64748b' }}>Bằng chữ: </span>
            <i style={{ fontWeight: 700, color: '#0c2340' }}>{numberToVietnameseWords(deposit.amount)}</i>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '4px' }}>
            <span style={{ color: '#64748b' }}>Nội dung nộp:</span>
            <span style={{ fontWeight: 500 }}>{deposit.note || 'Nộp tiền mặt tại quầy'}</span>
          </div>
        </div>

        {/* Hạch toán kế toán kép */}
        <div style={{ backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '0px', padding: '10px 14px', fontSize: '12px', marginBottom: '20px' }}>
          <div style={{ fontWeight: 800, color: '#1e293b', marginBottom: '4px' }}>HẠCH TOÁN SỔ CÁI KÉP (DOUBLE-ENTRY POSTING):</div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: 'monospace', color: '#334155' }}>
            <span>• NỢ TK 1011 (Quỹ tiền mặt quầy BR_Q1):</span>
            <b style={{ color: '#16a34a' }}>+{formatCurrency(deposit.amount)}</b>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: 'monospace', color: '#334155' }}>
            <span>• CÓ TK 4211 (Ví điện tử KH {deposit.customerName}):</span>
            <b style={{ color: '#0284c7' }}>+{formatCurrency(deposit.amount)}</b>
          </div>
        </div>

        {/* Chữ ký cán bộ & Dấu mộc */}
        <div style={{ display: 'flex', justifyContent: 'space-between', position: 'relative', marginTop: '16px', minHeight: '110px' }}>
          <div style={{ textAlign: 'center', width: '45%' }}>
            <div style={{ fontSize: '11.5px', fontWeight: 800, color: '#0c2340' }}>GIAO DỊCH VIÊN (MAKER)</div>
            <div style={{ fontSize: '10.5px', color: '#64748b' }}>(Ký, đóng dấu, ghi rõ họ tên)</div>
            <div style={{ marginTop: '50px', fontWeight: 700, color: '#0c2340', borderTop: '1px solid #cbd5e1', paddingTop: '4px' }}>
              {tellerName}
            </div>
          </div>

          <div style={{ textAlign: 'center', width: '45%' }}>
            <div style={{ fontSize: '11.5px', fontWeight: 800, color: '#0c2340' }}>KIỂM SOÁT VIÊN (CHECKER)</div>
            <div style={{ fontSize: '10.5px', color: '#64748b' }}>(Ký duyệt điện tử)</div>
            <div style={{ marginTop: '50px', fontWeight: 700, color: '#0c2340', borderTop: '1px solid #cbd5e1', paddingTop: '4px' }}>
              {deposit.checkerName || 'Hệ thống tự động duyệt'}
            </div>
          </div>

          {/* Dấu mộc đỏ điện tử vector SVG */}
          <div style={{
            position: 'absolute',
            top: '5px',
            left: '50%',
            transform: 'translateX(-50%) rotate(-10deg)',
            pointerEvents: 'none',
            opacity: 0.95
          }}>
            <svg width="135" height="135" viewBox="0 0 140 140">
              <circle cx="70" cy="70" r="64" fill="none" stroke="#dc2626" strokeWidth="3" strokeDasharray="6 2" />
              <circle cx="70" cy="70" r="58" fill="none" stroke="#dc2626" strokeWidth="1.5" />
              <path id="curveTopReceipt" d="M 22 70 A 48 48 0 0 1 118 70" fill="none" />
              <text fontSize="9.5" fontWeight="900" fill="#dc2626" letterSpacing="1">
                <textPath href="#curveTopReceipt" startOffset="50%" textAnchor="middle">
                  CORE BANKING CHI NHÁNH QUẬN 1
                </textPath>
              </text>
              <text x="70" y="68" fontSize="14" fontWeight="900" fill="#dc2626" textAnchor="middle" letterSpacing="1.5">
                ĐÃ THU TIỀN
              </text>
              <text x="70" y="83" fontSize="9.5" fontWeight="bold" fill="#dc2626" textAnchor="middle">
                PAID & VERIFIED
              </text>
              <path id="curveBottomReceipt" d="M 118 70 A 48 48 0 0 1 22 70" fill="none" />
              <text fontSize="8.5" fontWeight="bold" fill="#dc2626">
                <textPath href="#curveBottomReceipt" startOffset="50%" textAnchor="middle">
                  ★ HỆ THỐNG GIAO DỊCH QUẦY ★
                </textPath>
              </text>
            </svg>
          </div>
        </div>

        {/* Mã băm toàn vẹn */}
        <div style={{ marginTop: '16px', borderTop: '1px solid #e2e8f0', paddingTop: '10px', fontSize: '10px', color: '#64748b' }}>
          <div>Mã xác thực chữ ký số (Integrity Hash SHA-256):</div>
          <div style={{ fontFamily: 'monospace', wordBreak: 'break-all', color: '#0369a1', marginTop: '2px', fontWeight: 600 }}>
            {hashDisplay}
          </div>
        </div>

        {/* Nút hành động - BO VIÊN THUỐC */}
        <div className="no-print" style={{ display: 'flex', gap: '10px', marginTop: '20px', justifyContent: 'flex-end' }}>
          <button
            type="button"
            onClick={onClose}
            className="btn btn-outline"
            style={{ padding: '8px 18px', fontSize: '13px' }}
          >
            <X size={14} />
            <span>Đóng</span>
          </button>
          <button
            type="button"
            onClick={onPrint}
            className="btn btn-primary"
            style={{ padding: '8px 22px', fontSize: '13px' }}
          >
            <Printer size={14} />
            <span>In Giấy Nộp Tiền (A5/A4)</span>
          </button>
        </div>
      </div>
    </div>
  );
}
