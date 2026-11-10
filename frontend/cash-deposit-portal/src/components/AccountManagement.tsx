import React, { useState, useEffect, useCallback } from 'react';
import { AdminAccount, LoggedInStaff } from '../types';
import { ApiService } from '../api';
import { formatCurrency } from '../utils';
import { 
  Users, Search, Filter, ShieldAlert, ShieldCheck, Lock, Unlock, 
  RefreshCw, DollarSign, CheckCircle2, AlertCircle, Download, Landmark
} from 'lucide-react';

interface AccountManagementProps {
  staff: LoggedInStaff;
}

export function AccountManagement({ staff }: AccountManagementProps) {
  const [accounts, setAccounts] = useState<AdminAccount[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [keyword, setKeyword] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [minBalance, setMinBalance] = useState<string>('');
  const [maxBalance, setMaxBalance] = useState<string>('');
  const [actionMessage, setActionMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const fetchAccounts = useCallback(async () => {
    setLoading(true);
    setActionMessage(null);
    try {
      const min = minBalance ? Number(minBalance) : undefined;
      const max = maxBalance ? Number(maxBalance) : undefined;
      const res = await ApiService.fetchAdminAccounts(staff, {
        keyword: keyword.trim() || undefined,
        status: statusFilter !== 'ALL' ? statusFilter : undefined,
        minBalance: min,
        maxBalance: max,
      });
      setAccounts(res);
    } catch (e: any) {
      console.error(e);
      setActionMessage({ text: 'Lỗi tải danh mục tài khoản: ' + e.message, type: 'error' });
    } finally {
      setLoading(false);
    }
  }, [staff, keyword, statusFilter, minBalance, maxBalance]);

  useEffect(() => {
    fetchAccounts();
  }, [fetchAccounts]);

  const handleToggleStatus = async (account: AdminAccount) => {
    const isCurrentlyActive = account.status === 'ACTIVE';
    const nextStatus = isCurrentlyActive ? 'BLOCKED' : 'ACTIVE';
    const confirmPrompt = isCurrentlyActive
      ? `Bạn có chắc chắn muốn KHÓA tài khoản ví của ${account.customerName} (${account.phoneNumber}) không? Tài khoản sẽ bị chặn mọi giao dịch ghi nợ/ghi có.`
      : `Bạn có muốn MỞ KHÓA tài khoản ví của ${account.customerName} (${account.phoneNumber}) không?`;

    if (!window.confirm(confirmPrompt)) return;

    setLoading(true);
    const result = await ApiService.updateWalletStatus(staff, account.walletId, nextStatus);
    if (result.success) {
      setActionMessage({
        text: `✅ ${result.message || 'Cập nhật trạng thái ví thành công'}`,
        type: 'success'
      });
      fetchAccounts();
    } else {
      setActionMessage({
        text: `❌ ${result.message || 'Cập nhật trạng thái ví thất bại'}`,
        type: 'error'
      });
      setLoading(false);
    }
  };

  const totalBalance = accounts.reduce((sum, acc) => sum + (acc.balance || 0), 0);
  const activeCount = accounts.filter(acc => acc.status === 'ACTIVE').length;
  const blockedCount = accounts.filter(acc => acc.status === 'BLOCKED').length;

  const handleExportAccountsCsv = () => {
    if (accounts.length === 0) {
      alert('Không có dữ liệu tài khoản để xuất CSV');
      return;
    }
    const bom = '\ufeff';
    const header = 'STT,Họ và Tên,Số Điện Thoại,Số Tài Khoản,Mã Ví,Số Dư Thực Tế (VND),Hạn Mức Thấu Chi (VND),Tổng Khả Dụng (VND),Trạng Thái,Cấp Độ eKYC,Thời Gian Mở\n';
    const rows = accounts.map((acc, idx) =>
      `${idx + 1},"${acc.customerName}","${acc.phoneNumber}","${acc.accountNumber}","${acc.walletId}",${acc.balance || 0},${acc.overdraftLimit || 0},${(acc.balance || 0) + (acc.overdraftLimit || 0)},"${acc.status}","${acc.kycTier}","${acc.createdAt || ''}"`
    ).join('\n');
    const blob = new Blob([bom + header + rows], { type: 'text/csv;charset=utf-8;' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `danh_muc_tai_khoan_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  };

  // Tính năng 4.1: Cấp / thu hồi hạn mức thấu chi cho ví khách hàng (0 - 200 triệu VND)
  const handleSetOverdraftLimit = async (account: AdminAccount) => {
    const input = window.prompt(
      `Cấp/điều chỉnh hạn mức tín dụng thấu chi cho ví của ${account.customerName} (${account.phoneNumber}).\n\n` +
      `LƯU Ý: Hạn mức thấu chi là khoản cấp tín dụng cho phép chi tiêu vượt số dư, KHÔNG PHẢI nạp tiền mặt vào ví.\n` +
      `Số dư thực tế hiện tại: ${(account.balance || 0).toLocaleString('vi-VN')} VND\n` +
      `Hạn mức thấu chi hiện tại: ${(account.overdraftLimit || 0).toLocaleString('vi-VN')} VND\n\n` +
      `Nhập hạn mức thấu chi mới (Nhập 0 để thu hồi):`,
      String(account.overdraftLimit || 0)
    );
    if (input === null) return;
    const limit = Number(input);
    if (!Number.isFinite(limit) || limit < 0 || limit > 200000000) {
      alert('Hạn mức thấu chi phải nằm trong khoảng [0 - 200.000.000] VND');
      return;
    }

    setLoading(true);
    const result = await ApiService.setOverdraftLimit(staff, account.walletId, limit);
    if (result.success) {
      setActionMessage({ text: `✅ ${result.message || 'Cập nhật hạn mức thấu chi thành công'}`, type: 'success' });
      fetchAccounts();
    } else {
      setActionMessage({ text: `❌ ${result.message || 'Cập nhật hạn mức thấu chi thất bại'}`, type: 'error' });
      setLoading(false);
    }
  };

  // Tính năng 4.1: Batch tính lãi vay thấu chi theo ngày trên phần dư nợ âm
  const handleAccrueOverdraftInterest = async () => {
    if (!window.confirm('Xác nhận tính lãi vay thấu chi trên phần dư nợ âm (16%/năm, tính theo ngày) của toàn bộ tài khoản ví?')) return;
    setLoading(true);
    try {
      const res = await ApiService.accrueOverdraftInterest(staff, 16.0, 1);
      if (res.success) {
        alert(`✅ ${res.message}\nSố ví bị trừ lãi: ${res.data?.walletsCharged}\nTổng tiền lãi: ${formatCurrency(res.data?.totalInterestCharged || 0)}`);
        fetchAccounts();
      } else {
        alert(`❌ Lỗi: ${res.message}`);
      }
    } catch (e: any) {
      alert(`Lỗi: ${e.message}`);
    } finally {
      setLoading(false);
    }
  };

  const renderKycBadge = (tier?: string) => {
    const t = (tier || '').toUpperCase();
    if (t === 'VERIFIED_BIOMETRIC' || t === 'TIER_2' || t === 'BIOMETRIC') {
      return (
        <span className="badge badge-emerald" style={{ fontSize: '11px', padding: '3px 8px', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
          <CheckCircle2 size={11} />
          <span>NFC / Sinh trắc</span>
        </span>
      );
    }
    if (t === 'VERIFIED') {
      return (
        <span className="badge badge-emerald" style={{ fontSize: '11px', padding: '3px 8px', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
          <CheckCircle2 size={11} />
          <span>Đã xác thực</span>
        </span>
      );
    }
    if (t === 'TIER_1') {
      return (
        <span className="badge badge-cyan" style={{ fontSize: '11px', padding: '3px 8px' }}>
          Cấp 1 (Căn cước)
        </span>
      );
    }
    return (
      <span style={{
        fontSize: '11px',
        padding: '3px 8px',
        borderRadius: '999px',
        fontWeight: 600,
        background: '#fef3c7',
        color: '#92400e',
        border: '1px solid #fcd34d',
        display: 'inline-block'
      }}>
        Chưa định danh
      </span>
    );
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Header & Thống Kê Tổng Quan */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        background: 'var(--bg-card)',
        padding: '18px 24px',
        borderRadius: 'var(--radius-card)',
        border: '1px solid var(--border-color)',
        boxShadow: 'var(--shadow-card)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{
            background: 'rgba(30, 58, 138, 0.1)',
            padding: '12px',
            borderRadius: '12px',
            color: 'var(--primary-navy)'
          }}>
            <Users size={28} />
          </div>
          <div>
            <h2 style={{ margin: 0, fontSize: '18px', fontWeight: 800, color: 'var(--primary-navy)' }}>
              QUẢN TRỊ DANH MỤC &amp; BỘ LỌC TÀI KHOẢN KHÁCH HÀNG
            </h2>
            <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: 'var(--text-muted)' }}>
              Phân hệ Giám đốc / Quản trị viên: Tra cứu theo SĐT, Tên, Số dư và Kiểm soát khóa/mở khóa tài khoản ví (AML)
            </p>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          <button
            type="button"
            onClick={handleAccrueOverdraftInterest}
            disabled={loading}
            className="btn btn-outline"
            style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '8px 16px', color: 'var(--primary-blue)' }}
            title="Tính lãi vay thấu chi trên phần dư nợ âm (16%/năm theo ngày)"
          >
            <Landmark size={14} />
            <span>Lãi Thấu Chi</span>
          </button>
          <button
            type="button"
            onClick={handleExportAccountsCsv}
            disabled={loading || accounts.length === 0}
            className="btn btn-outline"
            style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '8px 16px', color: 'var(--primary-blue)' }}
          >
            <Download size={14} />
            <span>Xuất Danh Mục (CSV)</span>
          </button>
          <button
            type="button"
            onClick={fetchAccounts}
            disabled={loading}
            className="btn btn-outline"
            style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '8px 16px' }}
          >
            <RefreshCw size={14} className={loading ? 'spin' : ''} />
            <span>Làm mới dữ liệu</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px' }}>
        <div className="card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>TỔNG TÀI KHOẢN HIỂN THỊ</div>
          <div className="mono" style={{ fontSize: '24px', fontWeight: 800, marginTop: '8px', color: 'var(--primary-navy)' }}>
            {accounts.length}
          </div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>Tài khoản khách hàng</div>
        </div>

        <div className="card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '12px', color: 'var(--success-green)', fontWeight: 600 }}>HOẠT ĐỘNG (ACTIVE)</div>
          <div className="mono" style={{ fontSize: '24px', fontWeight: 800, marginTop: '8px', color: 'var(--success-green)' }}>
            {activeCount}
          </div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>Sẵn sàng giao dịch</div>
        </div>

        <div className="card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '12px', color: 'var(--danger-red)', fontWeight: 600 }}>ĐANG KHÓA (BLOCKED)</div>
          <div className="mono" style={{ fontSize: '24px', fontWeight: 800, marginTop: '8px', color: 'var(--danger-red)' }}>
            {blockedCount}
          </div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>Chặn giao dịch AML</div>
        </div>

        <div className="card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '12px', color: 'var(--primary-blue)', fontWeight: 600 }}>TỔNG SỐ DƯ TỒN VÍ</div>
          <div className="mono" style={{ fontSize: '20px', fontWeight: 800, marginTop: '8px', color: 'var(--primary-blue)' }}>
            {formatCurrency(totalBalance)}
          </div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>Thanh khoản khách hàng</div>
        </div>
      </div>

      {/* Thông báo kết quả thao tác */}
      {actionMessage && (
        <div style={{
          padding: '12px 16px',
          borderRadius: '8px',
          fontSize: '13px',
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          background: actionMessage.type === 'success' ? '#ecfdf5' : '#fef2f2',
          border: `1px solid ${actionMessage.type === 'success' ? '#a7f3d0' : '#fecaca'}`,
          color: actionMessage.type === 'success' ? '#065f46' : '#991b1b',
        }}>
          {actionMessage.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
          <span>{actionMessage.text}</span>
        </div>
      )}

      {/* Bộ Lọc Đa Tiêu Chí */}
      <div className="card" style={{ padding: '18px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '14px', fontSize: '14px', fontWeight: 700, color: 'var(--primary-navy)' }}>
          <Filter size={16} />
          <span>BỘ LỌC TÀI KHOẢN ĐA TIÊU CHÍ (REAL-TIME FILTER)</span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr 1fr auto', gap: '12px', alignItems: 'end' }}>
          <div>
            <label style={{ display: 'block', fontSize: '11.5px', fontWeight: 600, marginBottom: '6px', color: 'var(--text-muted)' }}>
              Từ khóa tìm kiếm (SĐT, Tên khách hàng, Mã ví)
            </label>
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                placeholder="Ví dụ: 0901234567, Alice Nguyen, ..."
                value={keyword}
                onChange={e => setKeyword(e.target.value)}
                style={{
                  width: '100%',
                  padding: '9px 12px 9px 34px',
                  borderRadius: '6px',
                  border: '1px solid var(--border-color)',
                  fontSize: '13px',
                  background: 'var(--bg-main)'
                }}
              />
              <Search size={15} style={{ position: 'absolute', left: '10px', top: '11px', color: 'var(--text-muted)' }} />
            </div>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '11.5px', fontWeight: 600, marginBottom: '6px', color: 'var(--text-muted)' }}>
              Trạng thái tài khoản
            </label>
            <select
              value={statusFilter}
              onChange={e => setStatusFilter(e.target.value)}
              style={{
                width: '100%',
                padding: '9px 12px',
                borderRadius: '6px',
                border: '1px solid var(--border-color)',
                fontSize: '13px',
                background: 'var(--bg-main)'
              }}
            >
              <option value="ALL">-- Tất cả trạng thái --</option>
              <option value="ACTIVE">Hoạt động (ACTIVE)</option>
              <option value="BLOCKED">Đã khóa (BLOCKED)</option>
            </select>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '11.5px', fontWeight: 600, marginBottom: '6px', color: 'var(--text-muted)' }}>
              Số dư tối thiểu (VND)
            </label>
            <input
              type="number"
              placeholder="Min Balance"
              value={minBalance}
              onChange={e => setMinBalance(e.target.value)}
              style={{
                width: '100%',
                padding: '9px 12px',
                borderRadius: '6px',
                border: '1px solid var(--border-color)',
                fontSize: '13px',
                background: 'var(--bg-main)'
              }}
            />
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '11.5px', fontWeight: 600, marginBottom: '6px', color: 'var(--text-muted)' }}>
              Số dư tối đa (VND)
            </label>
            <input
              type="number"
              placeholder="Max Balance"
              value={maxBalance}
              onChange={e => setMaxBalance(e.target.value)}
              style={{
                width: '100%',
                padding: '9px 12px',
                borderRadius: '6px',
                border: '1px solid var(--border-color)',
                fontSize: '13px',
                background: 'var(--bg-main)'
              }}
            />
          </div>

          <button
            type="button"
            onClick={() => {
              setKeyword('');
              setStatusFilter('ALL');
              setMinBalance('');
              setMaxBalance('');
            }}
            className="btn btn-outline"
            style={{ padding: '9px 16px', fontSize: '13px' }}
          >
            Đặt lại
          </button>
        </div>
      </div>

      {/* Danh Sách Bảng Tài Khoản */}
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="table" style={{ margin: 0, width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: 'var(--bg-card-subtle)', textAlign: 'left', borderBottom: '1px solid var(--border-color)' }}>
              <th style={{ padding: '12px 14px', fontSize: '12px', fontWeight: 700 }}>KHÁCH HÀNG</th>
              <th style={{ padding: '12px 14px', fontSize: '12px', fontWeight: 700 }}>SỐ ĐIỆN THOẠI</th>
              <th style={{ padding: '12px 14px', fontSize: '12px', fontWeight: 700 }}>MÃ VÍ / SỐ TK</th>
              <th style={{ padding: '12px 14px', fontSize: '12px', fontWeight: 700, textAlign: 'right' }}>SỐ DƯ THỰC TẾ (VÍ)</th>
              <th style={{ padding: '12px 14px', fontSize: '12px', fontWeight: 700, textAlign: 'right' }}>HẠN MỨC THẤU CHI</th>
              <th style={{ padding: '12px 14px', fontSize: '12px', fontWeight: 700, textAlign: 'right' }}>TỔNG KHẢ DỤNG</th>
              <th style={{ padding: '12px 14px', fontSize: '12px', fontWeight: 700, textAlign: 'center' }}>TIÊU CHUẨN KYC</th>
              <th style={{ padding: '12px 14px', fontSize: '12px', fontWeight: 700, textAlign: 'center' }}>TRẠNG THÁI</th>
              <th style={{ padding: '12px 14px', fontSize: '12px', fontWeight: 700, textAlign: 'center' }}>THAO TÁC</th>
            </tr>
          </thead>
          <tbody>
            {accounts.length === 0 ? (
              <tr>
                <td colSpan={9} style={{ textAlign: 'center', padding: '36px', color: 'var(--text-muted)', fontSize: '14px' }}>
                  Không tìm thấy tài khoản nào phù hợp với bộ lọc hiện tại.
                </td>
              </tr>
            ) : (
              accounts.map(acc => {
                const isBlocked = acc.status === 'BLOCKED';
                const isOverdrawn = (acc.balance || 0) < 0;
                const availableTotal = (acc.balance || 0) + (acc.overdraftLimit || 0);

                return (
                  <tr key={acc.walletId} style={{ borderBottom: '1px solid var(--border-color)' }}>
                    {/* 1. KHÁCH HÀNG */}
                    <td style={{ padding: '12px 14px' }}>
                      <div style={{ fontWeight: 700, color: 'var(--primary-navy)', fontSize: '13px' }}>
                        {acc.customerName}
                      </div>
                      <div className="mono" style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>
                        Mã: {acc.userId ? (acc.userId.length > 12 ? acc.userId.substring(0, 8) + '...' : acc.userId) : '—'}
                      </div>
                    </td>

                    {/* 2. SỐ ĐIỆN THOẠI */}
                    <td style={{ padding: '12px 14px' }}>
                      <span className="mono" style={{ fontWeight: 600, color: 'var(--text-main)', fontSize: '12.5px' }}>
                        {acc.phoneNumber || '—'}
                      </span>
                    </td>

                    {/* 3. MÃ VÍ / SỐ TK */}
                    <td style={{ padding: '12px 14px' }}>
                      <span className="mono" style={{ fontSize: '11.5px', color: 'var(--text-muted)' }} title={acc.walletId}>
                        {acc.accountNumber && !acc.accountNumber.includes('-')
                          ? acc.accountNumber
                          : `...${acc.walletId.slice(-8)}`}
                      </span>
                    </td>

                    {/* 4. SỐ DƯ THỰC TẾ (VÍ) */}
                    <td style={{ padding: '12px 14px', textAlign: 'right' }}>
                      <span className="mono" style={{
                        fontWeight: 800,
                        fontSize: '13.5px',
                        color: isOverdrawn ? 'var(--danger-red)' : 'var(--primary-navy)'
                      }}>
                        {formatCurrency(acc.balance || 0)}
                      </span>
                      {isOverdrawn && (
                        <div style={{ fontSize: '10px', color: 'var(--danger-red)', fontWeight: 600, marginTop: '2px' }}>
                          Dư nợ âm
                        </div>
                      )}
                    </td>

                    {/* 5. HẠN MỨC THẤU CHI */}
                    <td style={{ padding: '12px 14px', textAlign: 'right' }}>
                      {(acc.overdraftLimit || 0) > 0 ? (
                        <span className="mono badge badge-emerald" style={{ fontSize: '11px', padding: '3px 8px' }}>
                          {formatCurrency(acc.overdraftLimit)}
                        </span>
                      ) : (
                        <span style={{ fontSize: '11.5px', color: 'var(--text-muted)' }}>0 đ</span>
                      )}
                    </td>

                    {/* 6. TỔNG KHẢ DỤNG */}
                    <td style={{ padding: '12px 14px', textAlign: 'right' }}>
                      <span className="mono" style={{
                        fontWeight: 800,
                        fontSize: '13.5px',
                        color: 'var(--success-green)'
                      }}>
                        {formatCurrency(availableTotal)}
                      </span>
                      {(acc.overdraftLimit || 0) > 0 && (
                        <div style={{ fontSize: '10px', color: 'var(--text-muted)', marginTop: '2px' }}>
                          Gốc: {formatCurrency(acc.balance || 0)} + TC
                        </div>
                      )}
                    </td>

                    {/* 7. TIÊU CHUẨN KYC */}
                    <td style={{ padding: '12px 14px', textAlign: 'center' }}>
                      {renderKycBadge(acc.kycTier)}
                    </td>

                    {/* 8. TRẠNG THÁI */}
                    <td style={{ padding: '12px 14px', textAlign: 'center' }}>
                      <span className={`badge ${isBlocked ? 'badge-rose' : 'badge-emerald'}`} style={{ padding: '4px 10px', fontSize: '11px' }}>
                        {isBlocked ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG'}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                      <div style={{ display: 'inline-flex', gap: '6px' }}>
                        <button
                          type="button"
                          onClick={() => handleSetOverdraftLimit(acc)}
                          disabled={loading}
                          className="btn btn-outline"
                          style={{
                            padding: '6px 12px',
                            fontSize: '11.5px',
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '6px',
                            color: 'var(--primary-blue)'
                          }}
                          title={acc.overdraftLimit ? `Cấp/thu hồi hạn mức thấu chi (hiện tại: ${formatCurrency(acc.overdraftLimit)})` : 'Cấp hạn mức thấu chi'}
                        >
                          <Landmark size={13} />
                          <span>Thấu chi</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => handleToggleStatus(acc)}
                          disabled={loading}
                          className={`btn ${isBlocked ? 'btn-emerald' : 'btn-rose'}`}
                          style={{
                            padding: '6px 12px',
                            fontSize: '11.5px',
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '6px'
                          }}
                          title={isBlocked ? 'Mở khóa tài khoản ví' : 'Khóa tài khoản ví do nghi vấn rửa tiền'}
                        >
                          {isBlocked ? <Unlock size={13} /> : <Lock size={13} />}
                          <span>{isBlocked ? 'Mở khóa ví' : 'Khóa tài khoản'}</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

