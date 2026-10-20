import React, { useState, useMemo } from 'react';
import { Role, CashDeposit, VaultSummary, LedgerBalance, CustomerAccount, LoggedInStaff } from './types';
import { INITIAL_DEPOSITS, CUSTOMER_ACCOUNTS, STAFF_ACCOUNTS, OPENING_VAULT_BALANCE, MAX_VAULT_LIMIT } from './data';
import { generateReceiptHash } from './utils';
import { RoleSwitcher } from './components/RoleSwitcher';
import { TellerForm } from './components/TellerForm';
import { ManagerQueue } from './components/ManagerQueue';
import { VaultSummaryWidget } from './components/VaultSummaryWidget';
import { TransactionHistory } from './components/TransactionHistory';
import { DoubleEntryLedger } from './components/DoubleEntryLedger';
import { ReceiptModal } from './components/ReceiptModal';
import { LoginForm } from './components/LoginForm';
import { Landmark, Sun, Moon, ShieldCheck, UserCheck, LogOut } from 'lucide-react';
import './styles.css';

export default function App() {
  // Trạng thái đăng nhập cán bộ (Mặc định tự động đăng nhập Teller 1)
  const [currentStaff, setCurrentStaff] = useState<LoggedInStaff | null>(STAFF_ACCOUNTS[0]);
  const [isDarkMode, setIsDarkMode] = useState<boolean>(false);
  const [accounts, setAccounts] = useState<CustomerAccount[]>(CUSTOMER_ACCOUNTS);
  const [deposits, setDeposits] = useState<CashDeposit[]>(INITIAL_DEPOSITS);
  const [receiptDeposit, setReceiptDeposit] = useState<CashDeposit | null>(null);

  const role: Role = currentStaff?.role || 'TELLER';

  const vaultSummary = useMemo<VaultSummary>(() => {
    const completed = deposits.filter(d => d.status === 'COMPLETED');
    const pending = deposits.filter(d => d.status === 'PENDING_APPROVAL');
    const totalCashIn = completed.reduce((sum, d) => sum + d.amount, 0);
    return {
      openingBalance: OPENING_VAULT_BALANCE,
      totalCashIn,
      currentBalance: OPENING_VAULT_BALANCE + totalCashIn,
      maxLimit: MAX_VAULT_LIMIT,
      successCount: completed.length,
      pendingCount: pending.length,
    };
  }, [deposits]);

  const ledgerBalance = useMemo<LedgerBalance>(() => {
    const total = vaultSummary.totalCashIn;
    return { debit1011: total, credit4211: total, delta: 0 };
  }, [vaultSummary.totalCashIn]);

  const handleRoleSwitch = (newRole: Role) => {
    const targetStaff = STAFF_ACCOUNTS.find(s => s.role === newRole);
    if (targetStaff) {
      setCurrentStaff(targetStaff);
    }
  };

  const handleCreateDeposit = (data: {
    accountNumber: string;
    customerName: string;
    citizenId: string;
    phoneNumber: string;
    amount: number;
    note: string;
  }) => {
    if (!currentStaff) return;
    const isAutoApprove = data.amount <= 50_000_000;
    const code = 'DEP-' + Math.floor(Math.random() * 899999 + 100000);
    
    const newDeposit: CashDeposit = {
      id: Date.now().toString(),
      code,
      customerName: data.customerName,
      accountNumber: data.accountNumber,
      citizenId: data.citizenId,
      phoneNumber: data.phoneNumber,
      amount: data.amount,
      makerName: currentStaff.fullName,
      makerId: currentStaff.id,
      checkerName: isAutoApprove ? 'Hệ thống tự động duyệt (≤50M)' : null,
      status: isAutoApprove ? 'COMPLETED' : 'PENDING_APPROVAL',
      timestamp: new Date().toISOString(),
      note: data.note,
      hash: isAutoApprove ? generateReceiptHash(code, data.amount, data.accountNumber) : undefined,
    };

    setDeposits(prev => [newDeposit, ...prev]);

    // Nếu tự động duyệt -> cộng tiền ví ngay lập tức
    if (isAutoApprove) {
      setAccounts(prev => prev.map(a => 
        a.accountNumber === data.accountNumber 
          ? { ...a, balance: a.balance + data.amount }
          : a
      ));
      setReceiptDeposit(newDeposit);
    }
  };

  const handleApprove = (id: string) => {
    if (!currentStaff) return;
    const dep = deposits.find(d => d.id === id);
    if (!dep) return;
    
    // Kiểm tra quy chuẩn Maker-Checker
    if (dep.makerId === currentStaff.id) {
      alert('⛔ LỖI 403 FORBIDDEN: Quy chuẩn Maker-Checker! Bạn là người lập lệnh (Maker) nên KHÔNG ĐƯỢC PHÉP tự phê duyệt lệnh của chính mình.');
      return;
    }

    const hash = generateReceiptHash(dep.code, dep.amount, dep.accountNumber);

    setDeposits(prev => prev.map(d => d.id === id ? {
      ...d,
      status: 'COMPLETED',
      checkerName: currentStaff.fullName,
      hash,
    } : d));

    // Cộng tiền ví khách hàng
    setAccounts(prev => prev.map(a => 
      a.accountNumber === dep.accountNumber 
        ? { ...a, balance: a.balance + dep.amount }
        : a
    ));

    const updated = {
      ...dep,
      status: 'COMPLETED' as const,
      checkerName: currentStaff.fullName,
      hash,
    };
    setReceiptDeposit(updated);
  };

  const handleReject = (id: string) => {
    const reason = prompt('Nhập lý do từ chối (Tuân thủ phòng chống rửa tiền AML):', 'Nguồn tiền mặt không chứng minh được');
    if (!reason) return;
    setDeposits(prev => prev.map(d => d.id === id ? { ...d, status: 'REJECTED', rejectionReason: reason } : d));
  };

  const closeReceipt = () => setReceiptDeposit(null);

  // Nếu chưa đăng nhập -> Hiển thị Màn hình Đăng nhập
  if (!currentStaff) {
    return (
      <div className={`app ${isDarkMode ? 'theme-dark' : ''}`}>
        <div className="demo-banner">
          <span className="badge-pill">BẢO MẬT CORE BANKING</span>
          <span>HỆ THỐNG XÁC THỰC CÁN BỘ — CẤP QUYỀN GIAO DỊCH VIÊN & KIỂM SOÁT VIÊN</span>
        </div>
        <LoginForm onLoginSuccess={setCurrentStaff} />
      </div>
    );
  }

  return (
    <div className={`app ${isDarkMode ? 'theme-dark' : ''}`}>
      {/* Top Banner - Góc Vuông */}
      <div className="demo-banner">
        <span className="badge-pill">CORE BANKING 2026</span>
        <span>HỆ THỐNG GIAO DỊCH QUẦY — QUY CHUẨN MAKER-CHECKER & SỔ CÁI BẢO TOÀN (DELTA = 0.00 VND)</span>
      </div>

      {/* Navbar Header Ngân Hàng */}
      <nav className="navbar">
        <div className="brand">
          <div className="brand-icon-box">
            <Landmark size={22} />
          </div>
          <div>
            <div className="brand-title">CỔNG QUẢN LÝ NẠP TIỀN QUẦY | CORE BANKING TELLER PORTAL</div>
            <div className="brand-sub">
              Chi nhánh: <b>{currentStaff.branchName}</b> | Mã: <b className="mono">{currentStaff.branchId}</b>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          {/* Thông tin Cán bộ đang đăng nhập */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            background: 'var(--bg-card-subtle)',
            padding: '5px 12px',
            border: '1px solid var(--border-color)',
            borderRadius: 'var(--radius-pill)',
            fontSize: '12px'
          }}>
            {role === 'TELLER' ? (
              <UserCheck size={14} color="var(--primary-blue)" />
            ) : (
              <ShieldCheck size={14} color="var(--warning-amber)" />
            )}
            <b style={{ color: 'var(--primary-navy)' }}>{currentStaff.fullName}</b>
            <span className={`badge ${role === 'TELLER' ? 'badge-cyan' : 'badge-amber'}`} style={{ padding: '2px 8px', fontSize: '10px' }}>
              {role === 'TELLER' ? 'TELLER' : 'MANAGER'}
            </span>
          </div>

          {/* Nút chuyển đổi vai trò nhanh */}
          <RoleSwitcher role={role} onSwitch={handleRoleSwitch} />

          {/* Nút Đăng Xuất - Bo Viên Thuốc */}
          <button
            type="button"
            className="btn btn-outline"
            onClick={() => setCurrentStaff(null)}
            style={{ padding: '6px 14px', fontSize: '12px', gap: '5px' }}
            title="Đăng xuất phiên làm việc"
          >
            <LogOut size={13} />
            <span>Đăng Xuất</span>
          </button>

          {/* Nút chuyển đổi Giao diện Sáng / Tối - Bo Viên Thuốc */}
          <button
            type="button"
            className="btn btn-outline"
            onClick={() => setIsDarkMode(prev => !prev)}
            style={{ padding: '6px 12px', fontSize: '12px' }}
            title="Chuyển chế độ Giao diện"
          >
            {isDarkMode ? <Sun size={13} /> : <Moon size={13} />}
          </button>
        </div>
      </nav>

      {/* Main Container */}
      <div className="container">
        <div className="grid-layout">
          <div>
            {role === 'TELLER' ? (
              <TellerForm onSubmit={handleCreateDeposit} accounts={accounts} />
            ) : (
              <ManagerQueue
                deposits={deposits.filter(d => d.status === 'PENDING_APPROVAL')}
                currentUserId={currentStaff.id}
                onApprove={handleApprove}
                onReject={handleReject}
              />
            )}
          </div>
          <div>
            <VaultSummaryWidget summary={vaultSummary} />
            <TransactionHistory deposits={deposits} onReceipt={setReceiptDeposit} />
            <DoubleEntryLedger ledger={ledgerBalance} />
          </div>
        </div>
      </div>

      {/* Modal In Biên Lai */}
      {receiptDeposit && (
        <ReceiptModal
          deposit={receiptDeposit}
          tellerName={receiptDeposit.makerName}
          onClose={closeReceipt}
          onPrint={() => window.print()}
        />
      )}
    </div>
  );
}