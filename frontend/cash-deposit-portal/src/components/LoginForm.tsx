import React, { useState } from 'react';
import { LoggedInStaff } from '../types';
import { STAFF_ACCOUNTS } from '../data';
import { Landmark, Lock, User, KeyRound, ShieldCheck, ArrowRight, LogIn, AlertCircle, CheckCircle2 } from 'lucide-react';

interface LoginFormProps {
  onLoginSuccess: (staff: LoggedInStaff) => void;
}

export function LoginForm({ onLoginSuccess }: LoginFormProps) {
  const [username, setUsername] = useState('teller1');
  const [password, setPassword] = useState('DemoPass#2026!');
  const [errorMsg, setErrorMsg] = useState('');

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');

    const trimmedUser = username.trim().toLowerCase();
    const staff = STAFF_ACCOUNTS.find(
      s => s.username.toLowerCase() === trimmedUser || (trimmedUser.startsWith('09') && s.username === 'teller1')
    );

    if (!staff) {
      setErrorMsg('Tên đăng nhập không tồn tại trên hệ thống Core Banking!');
      return;
    }

    if (password !== 'DemoPass#2026!') {
      setErrorMsg('Mật khẩu không chính xác! (Mật khẩu mặc định: DemoPass#2026!)');
      return;
    }

    onLoginSuccess(staff);
  };

  const handleQuickSelect = (staff: LoggedInStaff) => {
    setUsername(staff.username);
    setPassword('DemoPass#2026!');
    setErrorMsg('');
    onLoginSuccess(staff);
  };

  return (
    <div style={{
      minHeight: '80vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '20px'
    }}>
      <div className="card" style={{
        width: '100%',
        maxWidth: '480px',
        padding: '36px',
        borderTop: '4px solid var(--primary-blue)',
        boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05)'
      }}>
        {/* Header Logo */}
        <div style={{ textAlign: 'center', marginBottom: '26px' }}>
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '54px',
            height: '54px',
            background: 'var(--primary-navy)',
            color: '#ffffff',
            marginBottom: '12px',
            borderLeft: '4px solid var(--primary-blue)'
          }}>
            <Landmark size={28} />
          </div>
          <h2 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--primary-navy)', letterSpacing: '-0.3px' }}>
            ĐĂNG NHẬP HỆ THỐNG GIAO DỊCH QUẦY
          </h2>
          <p style={{ fontSize: '12.5px', color: 'var(--text-muted)', marginTop: '4px' }}>
            Hệ thống Quản lý Nạp tiền &amp; Kiểm soát Phê duyệt Core Banking
          </p>
        </div>

        {/* Lỗi đăng nhập nếu có */}
        {errorMsg && (
          <div style={{
            background: '#fff1f2',
            border: '1px solid #fecdd3',
            borderLeft: '4px solid var(--danger-red)',
            color: '#be123c',
            padding: '10px 14px',
            fontSize: '12.5px',
            marginBottom: '18px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            <AlertCircle size={16} />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* Form Đăng nhập */}
        <form onSubmit={handleLogin}>
          <div className="form-group">
            <label className="form-label">Tên Đăng Nhập / Mã Cán Bộ:</label>
            <div className="input-with-icon">
              <span className="input-icon">
                <User size={16} />
              </span>
              <input
                type="text"
                className="form-input mono"
                value={username}
                onChange={e => setUsername(e.target.value)}
                placeholder="teller1, teller2, manager1..."
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Mật Khẩu Xác Thực:</label>
            <div className="input-with-icon">
              <span className="input-icon">
                <KeyRound size={16} />
              </span>
              <input
                type="password"
                className="form-input"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="Nhập mật khẩu..."
                required
              />
            </div>
            <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>
              Mật khẩu mặc định: <b className="mono">DemoPass#2026!</b> (Tra cứu tại <b className="mono">ACCOUNTS.md</b>)
            </div>
          </div>

          <div style={{ marginTop: '22px' }}>
            <button
              type="submit"
              className="btn btn-primary"
              style={{ width: '100%', padding: '12px', fontSize: '14.5px', gap: '8px' }}
            >
              <LogIn size={16} />
              <span>ĐĂNG NHẬP VÀO PHIÊN LÀM VIỆC</span>
              <ArrowRight size={16} />
            </button>
          </div>
        </form>

        {/* 1-Click Fast Login cho Cán Bộ Ngân Hàng */}
        <div style={{ marginTop: '26px', borderTop: '1px dashed var(--border-color)', paddingTop: '18px' }}>
          <div style={{ fontSize: '11.5px', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: '10px', letterSpacing: '0.5px' }}>
            ⚡ 1-Click Đăng Nhập Nhanh Cán Bộ (Demo):
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {STAFF_ACCOUNTS.map(staff => (
              <button
                key={staff.id}
                type="button"
                onClick={() => handleQuickSelect(staff)}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  padding: '9px 14px',
                  background: 'var(--bg-card-subtle)',
                  border: '1px solid var(--border-color)',
                  borderRadius: 'var(--radius-pill)',
                  cursor: 'pointer',
                  fontSize: '12px',
                  color: 'var(--text-main)',
                  transition: 'all 0.15s ease'
                }}
                className="amount-btn"
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  {staff.role === 'TELLER' ? (
                    <User size={13} color="var(--primary-blue)" />
                  ) : (
                    <ShieldCheck size={13} color="var(--warning-amber)" />
                  )}
                  <b>{staff.fullName}</b>
                  <span className="mono" style={{ color: 'var(--text-muted)' }}>({staff.username})</span>
                </div>
                <span className={`badge ${staff.role === 'TELLER' ? 'badge-cyan' : 'badge-amber'}`} style={{ padding: '2px 8px', fontSize: '10.5px' }}>
                  {staff.branchId}
                </span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
