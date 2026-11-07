import React, { useState } from 'react';
import { LoanApplication, LoggedInStaff } from '../types';
import { ApiService } from '../api';
import { formatCurrency } from '../utils';
import { CheckCircle2, XCircle, RefreshCw, AlertCircle, FileText, DollarSign, Calendar, ShieldCheck, Download } from 'lucide-react';

interface LoanManagementProps {
  currentStaff: LoggedInStaff;
  loans: LoanApplication[];
  onRefresh: () => void;
  onLoanApproved?: (loanId: string) => void;
}

export function LoanManagement({ currentStaff, loans, onRefresh, onLoanApproved }: LoanManagementProps) {
  const [loadingId, setLoadingId] = useState<string | null>(null);
  const [actionMessage, setActionMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const pendingLoans = loans.filter(l => l.status === 'PENDING_APPROVAL');
  const totalPendingAmount = pendingLoans.reduce((sum, l) => sum + (l.amount || 0), 0);

  const handleApprove = async (loan: LoanApplication) => {
    if (!window.confirm(`Xác nhận phê duyệt hồ sơ vay ${loan.id} và giải ngân ${formatCurrency(loan.amount)} vào ví khách hàng?`)) {
      return;
    }
    setLoadingId(loan.id);
    setActionMessage(null);

    const result = await ApiService.approveLoan(currentStaff, loan.id);
    setLoadingId(null);

    if (result.success) {
      setActionMessage({ type: 'success', text: `✅ Phê duyệt thành công hồ sơ ${loan.id}! Tiền đã giải ngân tức thì.` });
      if (onLoanApproved) onLoanApproved(loan.id);
      onRefresh();
    } else {
      setActionMessage({ type: 'error', text: `❌ ${result.message}` });
    }
  };

  const handleReject = async (loan: LoanApplication) => {
    const reason = window.prompt(
      'Nhập lý do từ chối hồ sơ vay vốn (Tuân thủ chính sách tín dụng Core Banking):',
      'Điểm tín nhiệm CIC chưa đạt chuẩn cấp tín dụng'
    );
    if (!reason) return;

    setLoadingId(loan.id);
    setActionMessage(null);

    const result = await ApiService.rejectLoan(currentStaff, loan.id, reason);
    setLoadingId(null);

    if (result.success) {
      setActionMessage({ type: 'success', text: `ℹ️ Đã từ chối hồ sơ vay ${loan.id}.` });
      onRefresh();
    } else {
      setActionMessage({ type: 'error', text: `❌ ${result.message}` });
    }
  };

  const handleExportLoanReport = () => {
    const now = new Date().toISOString().split('T')[0];
    const headers = '\ufeffMã Hồ Sơ Vay,Mã Khách Hàng,Sản Phẩm Vay,Số Tiền Vay (VND),Kỳ Hạn (Tháng),Trạng Thái,Mục Đích Vay,Thời Gian Đăng Ký\n';
    const rows = loans.map(l =>
      `"${l.id}","${l.userId}","${l.productName || 'Vay Tiêu Dùng'}",${l.amount},${l.termMonths},"${l.status}","${(l.purpose || '').replace(/"/g, '""')}","${l.createdAt || ''}"`
    ).join('\n');

    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `danh-muc-tin-dung-vay-${now}.csv`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  };

  return (
    <div className="card" style={{ padding: '24px' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
        <div>
          <h2 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--primary-navy)', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <FileText size={20} color="var(--primary-blue)" />
            PHÊ DUYỆT HỒ SƠ TÍN DỤNG &amp; VAY TIÊU DÙNG (MAKER-CHECKER)
          </h2>
          <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
            Quy chuẩn kiểm soát cấp tín dụng 2 cấp — Tự động giải ngân số dư ví sau khi duyệt
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <button
            type="button"
            className="btn btn-outline"
            onClick={handleExportLoanReport}
            style={{ padding: '6px 14px', fontSize: '12px', gap: '6px' }}
          >
            <Download size={14} />
            <span>Xuất Danh Mục Vay (CSV)</span>
          </button>
          <button
            type="button"
            className="btn btn-outline"
            onClick={onRefresh}
            style={{ padding: '6px 14px', fontSize: '12px', gap: '6px' }}
          >
            <RefreshCw size={14} />
            <span>Làm mới danh sách</span>
          </button>
        </div>
      </div>

      {/* Summary KPI Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '20px' }}>
        <div style={{ background: 'var(--bg-card-subtle)', padding: '14px 18px', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Hồ sơ chờ phê duyệt</div>
          <div style={{ fontSize: '24px', fontWeight: 800, color: '#f59e0b', marginTop: '4px' }}>
            {pendingLoans.length} <span style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-muted)' }}>hồ sơ</span>
          </div>
        </div>
        <div style={{ background: 'var(--bg-card-subtle)', padding: '14px 18px', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Tổng khối lượng vốn chờ giải ngân</div>
          <div className="mono tabular-nums" style={{ fontSize: '24px', fontWeight: 800, color: 'var(--primary-navy)', marginTop: '4px' }}>
            {formatCurrency(totalPendingAmount)}
          </div>
        </div>
      </div>

      {/* Action Banner */}
      {actionMessage && (
        <div style={{
          padding: '12px 16px',
          borderRadius: '6px',
          marginBottom: '16px',
          fontSize: '13px',
          background: actionMessage.type === 'success' ? '#ecfdf5' : '#fff1f2',
          borderLeft: `4px solid ${actionMessage.type === 'success' ? '#10b981' : '#f43f5e'}`,
          color: actionMessage.type === 'success' ? '#065f46' : '#9f1239',
          display: 'flex',
          alignItems: 'center',
          gap: '8px'
        }}>
          {actionMessage.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
          <span>{actionMessage.text}</span>
        </div>
      )}

      {/* Table */}
      {pendingLoans.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-muted)' }}>
          <ShieldCheck size={36} style={{ margin: '0 auto 12px auto', opacity: 0.4 }} />
          <p style={{ fontWeight: 600 }}>Hiện không có hồ sơ vay nào đang chờ phê duyệt.</p>
          <p style={{ fontSize: '12px', marginTop: '4px' }}>Mọi yêu cầu đăng ký vay vốn mới từ ứng dụng Mobile sẽ hiển thị tại đây.</p>
        </div>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table className="table" style={{ width: '100%', fontSize: '13px' }}>
            <thead>
              <tr style={{ background: 'var(--bg-card-subtle)', textAlign: 'left' }}>
                <th style={{ padding: '10px 12px' }}>Mã hồ sơ</th>
                <th style={{ padding: '10px 12px' }}>Khách hàng</th>
                <th style={{ padding: '10px 12px' }}>Gói vay &amp; Mục đích</th>
                <th style={{ padding: '10px 12px', textAlign: 'right' }}>Số tiền vay</th>
                <th style={{ padding: '10px 12px', textAlign: 'center' }}>Kỳ hạn / Lãi</th>
                <th style={{ padding: '10px 12px', textAlign: 'right' }}>Ước tính kỳ</th>
                <th style={{ padding: '10px 12px', textAlign: 'center' }}>Hành động</th>
              </tr>
            </thead>
            <tbody>
              {pendingLoans.map(loan => (
                <tr key={loan.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                  <td style={{ padding: '12px', fontFamily: 'monospace', fontWeight: 600 }}>
                    {loan.id.length > 14 ? loan.id.substring(0, 14) + '...' : loan.id}
                  </td>
                  <td style={{ padding: '12px' }}>
                    <div style={{ fontWeight: 600 }}>{loan.userId}</div>
                    <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                      {loan.createdAt ? new Date(loan.createdAt).toLocaleString('vi-VN') : 'Vừa gửi'}
                    </div>
                  </td>
                  <td style={{ padding: '12px' }}>
                    <div style={{ fontWeight: 500 }}>{loan.productName || 'Vay tiêu dùng Sen Hồng'}</div>
                    <div style={{ fontSize: '11.5px', color: 'var(--text-muted)' }}>{loan.purpose || 'Chi tiêu cá nhân'}</div>
                  </td>
                  <td style={{ padding: '12px', textAlign: 'right', fontWeight: 700, color: 'var(--primary-blue)' }}>
                    {formatCurrency(loan.amount)}
                  </td>
                  <td style={{ padding: '12px', textAlign: 'center' }}>
                    <span className="badge badge-cyan" style={{ fontSize: '11px' }}>
                      {loan.termMonths} tháng
                    </span>
                    <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>
                      {loan.interestRateYear || 9.5}%/năm
                    </div>
                  </td>
                  <td style={{ padding: '12px', textAlign: 'right', fontWeight: 600 }}>
                    {loan.monthlyEstimate ? formatCurrency(loan.monthlyEstimate) : '—'}
                  </td>
                  <td style={{ padding: '12px', textAlign: 'center' }}>
                    <div style={{ display: 'inline-flex', gap: '8px' }}>
                      <button
                        type="button"
                        className="btn btn-primary"
                        onClick={() => handleApprove(loan)}
                        disabled={loadingId === loan.id}
                        style={{ padding: '5px 12px', fontSize: '12px', background: '#10b981', borderColor: '#10b981' }}
                        title="Phê duyệt khoản vay và giải ngân số dư ví"
                      >
                        <CheckCircle2 size={13} />
                        <span>Duyệt</span>
                      </button>
                      <button
                        type="button"
                        className="btn btn-outline"
                        onClick={() => handleReject(loan)}
                        disabled={loadingId === loan.id}
                        style={{ padding: '5px 10px', fontSize: '12px', color: '#ef4444', borderColor: '#fca5a5' }}
                        title="Từ chối hồ sơ cấp tín dụng"
                      >
                        <XCircle size={13} />
                        <span>Từ chối</span>
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

