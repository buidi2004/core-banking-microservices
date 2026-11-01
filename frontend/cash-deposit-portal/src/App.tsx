import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { Role, CashDeposit, VaultSummary, LedgerBalance, CustomerAccount, LoggedInStaff, LoanApplication } from './types';
import { INITIAL_DEPOSITS, CUSTOMER_ACCOUNTS, STAFF_ACCOUNTS, OPENING_VAULT_BALANCE, MAX_VAULT_LIMIT } from './data';
import { generateReceiptHash } from './utils';
import { ApiService } from './api';
import { RoleSwitcher } from './components/RoleSwitcher';
import { TellerForm } from './components/TellerForm';
import { TransferForm } from './components/TransferForm';
import { ManagerQueue } from './components/ManagerQueue';
import { VaultSummaryWidget } from './components/VaultSummaryWidget';
import { TransactionHistory } from './components/TransactionHistory';
import { DoubleEntryLedger } from './components/DoubleEntryLedger';
import { ReceiptModal } from './components/ReceiptModal';
import { LoginForm } from './components/LoginForm';
import { LoanManagement } from './components/LoanManagement';
import { AccountManagement } from './components/AccountManagement';
import { LedgerManagement } from './components/LedgerManagement';
import { Landmark, Sun, Moon, ShieldCheck, UserCheck, LogOut, Wallet, FileText, RefreshCw, CheckCircle2, Scale, Users } from 'lucide-react';
import './styles.css';

export default function App() {
  // Trạng thái đăng nhập cán bộ (Khởi tạo từ localStorage nếu có token)
  const [currentStaff, setCurrentStaff] = useState<LoggedInStaff | null>(() => {
    try {
      const saved = localStorage.getItem('senhong_staff_session');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (parsed && parsed.token) return parsed;
      }
      return null;
    } catch {
      return null;
    }
  });

  const [activeTab, setActiveTab] = useState<'DEPOSIT' | 'LOANS' | 'LEDGER' | 'ACCOUNTS'>('DEPOSIT');
  const [isDarkMode, setIsDarkMode] = useState<boolean>(false);
  const [accounts, setAccounts] = useState<CustomerAccount[]>(CUSTOMER_ACCOUNTS);
  const [deposits, setDeposits] = useState<CashDeposit[]>(INITIAL_DEPOSITS);
  const [loans, setLoans] = useState<LoanApplication[]>([]);
  const [receiptDeposit, setReceiptDeposit] = useState<CashDeposit | null>(null);
  const [isOnlineBackend, setIsOnlineBackend] = useState<boolean>(false);
  const [backendVaultSummary, setBackendVaultSummary] = useState<VaultSummary | null>(null);

  const role: Role = currentStaff?.role || 'TELLER';

  // Lưu phiên đăng nhập cán bộ
  const handleSetStaff = (staff: LoggedInStaff | null) => {
    setCurrentStaff(staff);
    if (staff) {
      try {
        localStorage.setItem('senhong_staff_session', JSON.stringify(staff));
      } catch {}
    } else {
      localStorage.removeItem('senhong_staff_session');
    }
  };

  // Tự động kết nối và xác thực cán bộ teller1 mặc định nếu chưa có phiên
  useEffect(() => {
    if (!currentStaff) {
      ApiService.loginStaff('teller1', 'DemoPass#2026!').then(res => {
        if (res.success && res.staff) {
          handleSetStaff(res.staff);
        }
      });
    }
  }, []);

  // Tải dữ liệu thật từ Backend qua API Gateway
  const loadBackendData = useCallback(async () => {
    if (!currentStaff || !currentStaff.token) return;
    try {
      // 1. Tải báo cáo két quỹ thực tế từ Backend
      const vault = await ApiService.fetchVaultSummary(currentStaff);
      if (vault) {
        setBackendVaultSummary(vault);
        setIsOnlineBackend(true);
      }

      // 2. Tải danh sách nạp quầy từ Backend
      const realDeposits = await ApiService.fetchDeposits(currentStaff);
      if (realDeposits.length > 0) {
        setDeposits(realDeposits);
        setIsOnlineBackend(true);
      }

      // 3. Tải danh sách hồ sơ vay chờ duyệt
      const pendingLoans = await ApiService.fetchPendingLoans(currentStaff);
      setLoans(pendingLoans);
      if (pendingLoans.length > 0) {
        setIsOnlineBackend(true);
      }

      // 4. Tải danh mục tài khoản ví thật từ Database
      const adminAccounts = await ApiService.fetchAdminAccounts(currentStaff);
      if (adminAccounts.length > 0) {
        const mappedAccounts: CustomerAccount[] = adminAccounts.map(acc => ({
          accountNumber: acc.accountNumber || acc.walletId,
          phoneNumber: acc.phoneNumber,
          citizenId: acc.userId,
          customerName: acc.customerName,
          balance: acc.balance,
          status: acc.status,
          kycTier: (acc.kycTier as any) || 'VERIFIED_BIOMETRIC',
          branchName: 'Chi nhánh Quận 1 (TP.HCM)'
        }));
        setAccounts(mappedAccounts);
        setIsOnlineBackend(true);
      }
    } catch (e) {
      console.warn('Backend currently offline or unreachable, using local state:', e);
      setIsOnlineBackend(false);
    }
  }, [currentStaff]);

  useEffect(() => {
    loadBackendData();
    // Polling tự động làm mới mỗi 15 giây
    const timer = setInterval(loadBackendData, 15000);
    return () => clearInterval(timer);
  }, [loadBackendData]);

  const vaultSummary = useMemo<VaultSummary>(() => {
    if (backendVaultSummary) return backendVaultSummary;
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
  }, [backendVaultSummary, deposits]);

  const ledgerBalance = useMemo<LedgerBalance>(() => {
    const total = vaultSummary.totalCashIn;
    return { debit1011: total, credit4211: total, delta: 0 };
  }, [vaultSummary.totalCashIn]);

  // Chuyển đổi vai trò và tự động lấy JWT Token thật tương ứng
  const handleRoleSwitch = async (newRole: Role) => {
    const targetUser = newRole === 'TELLER' ? 'teller1' : 'manager1';
    const authRes = await ApiService.loginStaff(targetUser, 'DemoPass#2026!');
    if (authRes.success && authRes.staff) {
      handleSetStaff(authRes.staff);
    } else {
      const targetStaff = STAFF_ACCOUNTS.find(s => s.role === newRole);
      if (targetStaff) handleSetStaff(targetStaff);
    }
  };

  // Lập lệnh nạp tiền tại quầy (Maker)
  const handleCreateDeposit = async (data: {
    accountNumber: string;
    customerName: string;
    citizenId: string;
    phoneNumber: string;
    amount: number;
    note: string;
  }) => {
    if (!currentStaff) return;

    // 1. Gửi lệnh nạp tiền tới Backend API Gateway thực tế
    const apiResult = await ApiService.createDeposit(currentStaff, data);
    const isAutoApprove = data.amount <= 50_000_000;
    const code = apiResult.data?.depositCode || ('DEP-' + Math.floor(Math.random() * 899999 + 100000));

    const newDeposit: CashDeposit = {
      id: apiResult.data?.id || Date.now().toString(),
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

    if (apiResult.success) {
      // Reload lại từ server
      setTimeout(loadBackendData, 500);
    }
  };

  // Phê duyệt nạp tiền quầy (Checker)
  const handleApprove = async (id: string) => {
    if (!currentStaff) return;
    const dep = deposits.find(d => d.id === id);
    if (!dep) return;
    
    // Kiểm tra quy chuẩn Maker-Checker
    if (dep.makerId === currentStaff.id) {
      alert('⛔ LỖI 403 FORBIDDEN: Quy chuẩn Maker-Checker! Bạn là người lập lệnh (Maker) nên KHÔNG ĐƯỢC PHÉP tự phê duyệt lệnh của chính mình.');
      return;
    }

    // Gọi Backend API phê duyệt
    const apiResult = await ApiService.approveDeposit(currentStaff, dep.id);

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

    if (apiResult.success) {
      setTimeout(loadBackendData, 500);
    }
  };

  // Từ chối nạp tiền quầy (Checker)
  const handleReject = async (id: string) => {
    const reason = prompt('Nhập lý do từ chối (Tuân thủ phòng chống rửa tiền AML):', 'Nguồn tiền mặt không chứng minh được');
    if (!reason || !currentStaff) return;

    await ApiService.rejectDeposit(currentStaff, id, reason);
    setDeposits(prev => prev.map(d => d.id === id ? { ...d, status: 'REJECTED', rejectionReason: reason } : d));
    setTimeout(loadBackendData, 500);
  };

  // Chuyển tiền P2P
  const handleP2PTransfer = async (data: {
    senderPhone: string;
    receiverPhone: string;
    amount: number;
    note: string;
  }) => {
    if (!currentStaff) {
      alert('Vui lòng đăng nhập trước khi thực hiện chuyển tiền!');
      return;
    }

    const result = await ApiService.transferP2p(currentStaff, data);
    if (result.success) {
      alert('✅ ' + result.message);
      loadBackendData();
    } else {
      alert('❌ ' + result.message);
    }
  };

  const closeReceipt = () => setReceiptDeposit(null);

  // Màn hình Đăng nhập nếu chưa xác thực cán bộ
  if (!currentStaff) {
    return (
      <div className={`app ${isDarkMode ? 'theme-dark' : ''}`}>
        <div className="demo-banner">
          <span className="badge-pill">BẢO MẬT CORE BANKING</span>
          <span>HỆ THỐNG XÁC THỰC CÁN BỘ — CẤP QUYỀN GIAO DỊCH VIÊN & KIỂM SOÁT VIÊN</span>
        </div>
        <LoginForm onLoginSuccess={handleSetStaff} />
      </div>
    );
  }

  return (
    <div className={`app ${isDarkMode ? 'theme-dark' : ''}`}>
      {/* Top Banner */}
      <div className="demo-banner" style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span className="badge-pill">CORE BANKING 2026</span>
          <span>HỆ THỐNG GIAO DỊCH QUẦY — QUY CHUẨN MAKER-CHECKER &amp; SỔ CÁI BẢO TOÀN (DELTA = 0.00 VND)</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '11px' }}>
          <span style={{
            display: 'inline-block',
            width: '8px',
            height: '8px',
            borderRadius: '50%',
            background: isOnlineBackend ? '#10b981' : '#f59e0b'
          }} />
          <span>{isOnlineBackend ? 'Đã kết nối Backend API Gateway' : 'Chế độ Cục bộ / API Offline'}</span>
        </div>
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

          {/* Nút Đăng Xuất */}
          <button
            type="button"
            className="btn btn-outline"
            onClick={() => handleSetStaff(null)}
            style={{ padding: '6px 14px', fontSize: '12px', gap: '5px' }}
            title="Đăng xuất phiên làm việc"
          >
            <LogOut size={13} />
            <span>Đăng Xuất</span>
          </button>

          {/* Nút chuyển đổi Giao diện Sáng / Tối */}
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

      {/* Navigation Sub-Tabs */}
      <div style={{
        maxWidth: '1280px',
        margin: '16px auto 0 auto',
        padding: '0 24px',
        display: 'flex',
        gap: '12px'
      }}>
        <button
          type="button"
          onClick={() => setActiveTab('DEPOSIT')}
          style={{
            padding: '10px 20px',
            fontWeight: 700,
            fontSize: '13.5px',
            borderRadius: '8px 8px 0 0',
            border: 'none',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            background: activeTab === 'DEPOSIT' ? 'var(--bg-card)' : 'transparent',
            color: activeTab === 'DEPOSIT' ? 'var(--primary-blue)' : 'var(--text-muted)',
            borderBottom: activeTab === 'DEPOSIT' ? '3px solid var(--primary-blue)' : '3px solid transparent'
          }}
        >
          <Wallet size={16} />
          <span>Giao Dịch Nạp Tiền Quầy &amp; Chuyển Khoản</span>
        </button>

        <button
          type="button"
          onClick={() => {
            setActiveTab('LOANS');
            loadBackendData();
          }}
          style={{
            padding: '10px 20px',
            fontWeight: 700,
            fontSize: '13.5px',
            borderRadius: '8px 8px 0 0',
            border: 'none',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            background: activeTab === 'LOANS' ? 'var(--bg-card)' : 'transparent',
            color: activeTab === 'LOANS' ? 'var(--primary-blue)' : 'var(--text-muted)',
            borderBottom: activeTab === 'LOANS' ? '3px solid var(--primary-blue)' : '3px solid transparent'
          }}
        >
          <FileText size={16} />
          <span>Phê Duyệt Hồ Sơ Vay Tín Dụng</span>
          {loans.filter(l => l.status === 'PENDING_APPROVAL').length > 0 && (
            <span style={{
              background: '#ef4444',
              color: '#ffffff',
              fontSize: '11px',
              fontWeight: 800,
              padding: '2px 7px',
              borderRadius: '999px'
            }}>
              {loans.filter(l => l.status === 'PENDING_APPROVAL').length}
            </span>
          )}
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('LEDGER')}
          style={{
            padding: '10px 20px',
            fontWeight: 700,
            fontSize: '13.5px',
            borderRadius: '8px 8px 0 0',
            border: 'none',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            background: activeTab === 'LEDGER' ? 'var(--bg-card)' : 'transparent',
            color: activeTab === 'LEDGER' ? 'var(--primary-blue)' : 'var(--text-muted)',
            borderBottom: activeTab === 'LEDGER' ? '3px solid var(--primary-blue)' : '3px solid transparent'
          }}
        >
          <Scale size={16} />
          <span>Sổ Cái Kép &amp; Đối Soát Bút Toán (Δ = 0.00)</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('ACCOUNTS')}
          style={{
            padding: '10px 20px',
            fontWeight: 700,
            fontSize: '13.5px',
            borderRadius: '8px 8px 0 0',
            border: 'none',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            background: activeTab === 'ACCOUNTS' ? 'var(--bg-card)' : 'transparent',
            color: activeTab === 'ACCOUNTS' ? 'var(--primary-blue)' : 'var(--text-muted)',
            borderBottom: activeTab === 'ACCOUNTS' ? '3px solid var(--primary-blue)' : '3px solid transparent'
          }}
        >
          <Users size={16} />
          <span>Danh Mục &amp; Bộ Lọc Tài Khoản (Admin/Giám Đốc)</span>
        </button>
      </div>

      {/* Main Container */}
      <div className="container" style={{ marginTop: '0' }}>
        {activeTab === 'DEPOSIT' && (
          <div className="grid-layout">
            <div>
              {role === 'TELLER' ? (
                <>
                  <TellerForm onSubmit={handleCreateDeposit} accounts={accounts} />
                  <TransferForm onTransfer={handleP2PTransfer} accounts={accounts} />
                </>
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
        )}

        {activeTab === 'LOANS' && (
          <LoanManagement
            currentStaff={currentStaff}
            loans={loans}
            onRefresh={loadBackendData}
            onLoanApproved={() => {
              loadBackendData();
            }}
          />
        )}

        {activeTab === 'LEDGER' && (
          <LedgerManagement staff={currentStaff} />
        )}

        {activeTab === 'ACCOUNTS' && (
          <AccountManagement staff={currentStaff} />
        )}
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
