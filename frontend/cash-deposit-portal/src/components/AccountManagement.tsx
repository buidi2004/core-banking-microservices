import React, { useState, useEffect, useCallback } from 'react';
import { AdminAccount, LoggedInStaff } from '../types';
import { ApiService } from '../api';
import { formatCurrency } from '../utils';
import { 
  Users, Search, Filter, ShieldAlert, ShieldCheck, Lock, Unlock, 
  RefreshCw, DollarSign, CheckCircle2, AlertCircle
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
              <th style={{ padding: '12px 16px', fontSize: '12px', fontWeight: 700 }}>KHÁCH HÀNG</th>
              <th style={{ padding: '12px 16px', fontSize: '12px', fontWeight: 700 }}>SỐ ĐIỆN THOẠI</th>
              <th style={{ padding: '12px 16px', fontSize: '12px', fontWeight: 700 }}>MÃ TÀI KHOẢN VÍ</th>
              <th style={{ padding: '12px 16px', fontSize: '12px', fontWeight: 700, textAlign: 'right' }}>SỐ DƯ KHẢ DỤNG</th>
              <th style={{ padding: '12px 16px', fontSize: '12px', fontWeight: 700, textAlign: 'center' }}>TIÊU CHUẨN KYC</th>
              <th style={{ padding: '12px 16px', fontSize: '12px', fontWeight: 700, textAlign: 'center' }}>TRẠNG THÁI</th>
              <th style={{ padding: '12px 16px', fontSize: '12px', fontWeight: 700, textAlign: 'center' }}>THAO TÁC</th>
            </tr>
          </thead>
          <tbody>
            {accounts.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: '36px', color: 'var(--text-muted)', fontSize: '14px' }}>
                  Không tìm thấy tài khoản nào phù hợp với bộ lọc hiện tại.
                </td>
              </tr>
            ) : (
              accounts.map(acc => {
                const isBlocked = acc.status === 'BLOCKED';
                return (
                  <tr key={acc.walletId} style={{ borderBottom: '1px solid var(--border-color)' }}>
                    <td style={{ padding: '12px 16px' }}>
                      <div style={{ fontWeight: 700, color: 'var(--primary-navy)' }}>{acc.customerName}</div>
                      <div className="mono" style={{ fontSize: '11px', color: 'var(--text-muted)' }}>UID: {acc.userId}</div>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <span className="mono" style={{ fontWeight: 600 }}>{acc.phoneNumber}</span>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <span className="mono" style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                        {acc.accountNumber || acc.walletId}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', textAlign: 'right' }}>
                      <span className="mono" style={{ fontWeight: 800, fontSize: '14px', color: 'var(--primary-navy)' }}>
                        {formatCurrency(acc.balance)}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                      <span className="badge badge-emerald" style={{ fontSize: '11px', padding: '3px 8px' }}>
                        {acc.kycTier || 'VERIFIED'}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                      <span className={`badge ${isBlocked ? 'badge-rose' : 'badge-emerald'}`} style={{ padding: '4px 10px', fontSize: '11px' }}>
                        {isBlocked ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG'}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', textAlign: 'center' }}>
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

