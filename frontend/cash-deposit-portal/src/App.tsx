import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { Role, CashDeposit, VaultSummary, LedgerBalance, CustomerAccount, LoggedInStaff, LoanApplication } from './types';
import { INITIAL_DEPOSITS, CUSTOMER_ACCOUNTS, OPENING_VAULT_BALANCE, MAX_VAULT_LIMIT } from './data';
import { generateReceiptHash } from './utils';
import { ApiService } from './api';
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
import { KycManagement } from './components/KycManagement';
import { SavingsManagement } from './components/SavingsManagement';
import { SupportDeskManagement } from './components/SupportDeskManagement';
import { AdminOperations } from './components/AdminOperations';
import { AmlCaseManagement } from './components/AmlCaseManagement';
import { LedgerAuditLogManagement } from './components/LedgerAuditLogManagement';
import { Landmark, Sun, Moon, ShieldCheck, UserCheck, LogOut, Wallet, FileText, RefreshCw, CheckCircle2, Scale, Users, PiggyBank, Headphones, ShieldAlert, ScrollText, Clock, Layers } from 'lucide-react';
import { realtimeNotificationManager, RealtimeNotification } from './realtime';
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

  const [activeTab, setActiveTab] = useState<'DEPOSIT' | 'LOANS' | 'LEDGER' | 'ACCOUNTS' | 'KYC' | 'SAVINGS' | 'SUPPORT' | 'OPERATIONS' | 'AML' | 'AUDIT'>('DEPOSIT');
  const [isDarkMode, setIsDarkMode] = useState<boolean>(false);
  const [accounts, setAccounts] = useState<CustomerAccount[]>(CUSTOMER_ACCOUNTS);
  const [deposits, setDeposits] = useState<CashDeposit[]>(INITIAL_DEPOSITS);
  const [loans, setLoans] = useState<LoanApplication[]>([]);
  const [receiptDeposit, setReceiptDeposit] = useState<CashDeposit | null>(null);
  const [isOnlineBackend, setIsOnlineBackend] = useState<boolean>(false);
  const [backendVaultSummary, setBackendVaultSummary] = useState<VaultSummary | null>(null);
  const [liveToast, setLiveToast] = useState<{ id: string; title: string; body: string; time: string } | null>(null);

  type CategoryId = 'ALL' | 'OPERATIONS' | 'LENDING' | 'CUSTOMERS' | 'LEDGER_GOVERNANCE';
  const [selectedCategory, setSelectedCategory] = useState<CategoryId>('ALL');
  const [currentTime, setCurrentTime] = useState<string>(() => new Date().toLocaleTimeString('vi-VN'));
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date().toLocaleTimeString('vi-VN'));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

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

    // 1. Lắng nghe sự kiện Realtime STOMP WebSocket (cập nhật tức thì 0s, không cần F5)
    const unsubscribe = realtimeNotificationManager.subscribe((notif: RealtimeNotification) => {
      console.log('⚡ [Realtime STOMP Web] Giao dịch mới phát sinh, làm mới giao diện ngay lập tức:', notif);
      loadBackendData();
      const title = notif.title || 'Biến động số dư mới';
      const body = notif.body || `${notif.type || 'Giao dịch'}: ${notif.amount ? (notif.amount.toLocaleString('vi-VN') + ' đ') : ''}`;
      const now = new Date().toLocaleTimeString('vi-VN');
      setLiveToast({ id: `${Date.now()}`, title, body, time: now });
      setTimeout(() => {
        setLiveToast((prev) => (prev && prev.time === now ? null : prev));
      }, 6000);
    });

    // 2. Polling dự phòng thông minh: chỉ poll khi tab đang hiển thị, chu kỳ 20s (thay vì 5s gây nghẽn)
    const timer = setInterval(() => {
      if (document.visibilityState === 'visible') {
        loadBackendData();
      }
    }, 20000);

    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        loadBackendData();
      }
    };
    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      clearInterval(timer);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      unsubscribe();
    };
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

  const handleManualRefresh = async () => {
    setIsRefreshing(true);
    await loadBackendData();
    setTimeout(() => setIsRefreshing(false), 500);
  };

  const navTabs = useMemo(() => [
    {
      id: 'DEPOSIT' as const,
      category: 'OPERATIONS' as const,
      label: 'Nạp Quầy & Chuyển Tiền',
      icon: Wallet,
    },
    {
      id: 'LOANS' as const,
      category: 'LENDING' as const,
      label: 'Phê Duyệt Vay',
      icon: FileText,
      badge: loans.filter(l => l.status === 'PENDING_APPROVAL').length,
    },
    {
      id: 'SAVINGS' as const,
      category: 'LENDING' as const,
      label: 'Sổ Tiết Kiệm',
      icon: PiggyBank,
    },
    {
      id: 'LEDGER' as const,
      category: 'LEDGER_GOVERNANCE' as const,
      label: 'Sổ Cái Kép (Δ=0)',
      icon: Scale,
    },
    {
      id: 'ACCOUNTS' as const,
      category: 'CUSTOMERS' as const,
      label: 'Danh Mục Tài Khoản',
      icon: Users,
    },
    {
      id: 'KYC' as const,
      category: 'CUSTOMERS' as const,
      label: 'Duyệt Hồ Sơ eKYC',
      icon: UserCheck,
    },
    {
      id: 'SUPPORT' as const,
      category: 'CUSTOMERS' as const,
      label: 'Hỗ Trợ CSKH',
      icon: Headphones,
    },
    {
      id: 'AML' as const,
      category: 'LEDGER_GOVERNANCE' as const,
      label: 'Hồ Sơ AML / PCRT',
      icon: ShieldAlert,
    },
    {
      id: 'AUDIT' as const,
      category: 'LEDGER_GOVERNANCE' as const,
      label: 'Kiểm Toán Sổ Cái',
      icon: ScrollText,
    },
    {
      id: 'OPERATIONS' as const,
      category: 'LEDGER_GOVERNANCE' as const,
      label: 'Vận Hành Hệ Thống',
      icon: Layers,
    },
  ], [loans]);

  const categories = useMemo(() => [
    { id: 'ALL' as const, label: 'Tất cả nghiệp vụ (10)' },
    { id: 'OPERATIONS' as const, label: 'Giao dịch quầy' },
    { id: 'LENDING' as const, label: 'Tín dụng & Tiết kiệm' },
    { id: 'CUSTOMERS' as const, label: 'Khách hàng' },
    { id: 'LEDGER_GOVERNANCE' as const, label: 'Sổ cái & Kiểm soát' },
  ], []);

  const visibleTabs = useMemo(() => {
    if (selectedCategory === 'ALL') return navTabs;
    return navTabs.filter(t => t.category === selectedCategory);
  }, [navTabs, selectedCategory]);

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
      {/* Toast thông báo Realtime 0s (Không cần F5) */}
      {liveToast && (
        <div style={{
          position: 'fixed',
          top: '36px',
          right: '24px',
          zIndex: 99999,
          background: 'rgba(15, 23, 42, 0.96)',
          color: '#ffffff',
          padding: '14px 20px',
          borderRadius: '12px',
          boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.4), 0 8px 10px -6px rgba(0, 0, 0, 0.3)',
          border: '1px solid #10b981',
          backdropFilter: 'blur(12px)',
          maxWidth: '440px',
          cursor: 'pointer',
          transition: 'all 0.3s ease'
        }} onClick={() => setLiveToast(null)}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '6px' }}>
            <span style={{ fontSize: '13px', fontWeight: 700, color: '#34d399', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#10b981', display: 'inline-block', boxShadow: '0 0 8px #10b981' }} />
              ⚡ {liveToast.title}
            </span>
            <span style={{ fontSize: '11px', color: '#94a3b8' }}>{liveToast.time}</span>
          </div>
          <div style={{ fontSize: '12px', color: '#f1f5f9', lineHeight: 1.4 }}>{liveToast.body}</div>
        </div>
      )}

      {/* Top Banner */}
      <div className="demo-banner" style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 24px', flexWrap: 'wrap', gap: '8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span className="badge-pill">CORE BANKING 2026</span>
          <span style={{ fontSize: '12px' }}>HỆ THỐNG GIAO DỊCH QUẦY — QUY CHUẨN MAKER-CHECKER &amp; SỔ CÁI BẢO TOÀN (Δ = 0.00 VND)</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px', fontSize: '11px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#cbd5e1' }}>
            <Clock size={12} />
            <span className="mono">{currentTime} (Hà Nội UTC+7)</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span className={`status-pulse-dot ${isOnlineBackend ? 'online' : 'offline'}`} />
            <span>{isOnlineBackend ? 'Gateway :8080 Sẵn Sàng' : 'Chế độ Cục bộ / API Offline'}</span>
          </div>
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

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
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

          {/* Nút Làm Mới Dữ Liệu */}
          <button
            type="button"
            className="btn btn-outline"
            onClick={handleManualRefresh}
            style={{ padding: '6px 14px', fontSize: '12px', gap: '6px' }}
            title="Đồng bộ lại dữ liệu tức thời từ Backend Gateway"
          >
            <RefreshCw size={13} className={isRefreshing ? 'spin-anim' : ''} />
            <span>Làm Mới</span>
          </button>

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

      {/* Navigation Sub-Tabs Enterprise */}
      <div className="nav-subtabs-wrapper">
        <div className="nav-subtabs-container">
          {/* Category Filter Pills */}
          <div className="nav-categories-bar">
            {categories.map(cat => (
              <button
                key={cat.id}
                type="button"
                className={`nav-category-btn ${selectedCategory === cat.id ? 'active' : ''}`}
                onClick={() => setSelectedCategory(cat.id)}
              >
                <span>{cat.label}</span>
              </button>
            ))}
          </div>

          {/* Tab Rail Buttons */}
          <div className="nav-tabs-scroll-rail">
            {visibleTabs.map(tab => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  className={`nav-tab-button ${isActive ? 'active' : ''}`}
                  onClick={() => {
                    setActiveTab(tab.id);
                    if (tab.id === 'LOANS') {
                      loadBackendData();
                    }
                  }}
                  title={tab.label}
                >
                  <span className="tab-icon">
                    <Icon size={15} />
                  </span>
                  <span>{tab.label}</span>
                  {tab.badge && tab.badge > 0 ? (
                    <span className="nav-tab-badge">{tab.badge}</span>
                  ) : null}
                </button>
              );
            })}
          </div>
        </div>
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
              <TransactionHistory deposits={deposits} onReceipt={setReceiptDeposit} staff={currentStaff} />
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

        {activeTab === 'KYC' && (
          <KycManagement currentStaff={currentStaff} onRefresh={loadBackendData} />
        )}

        {activeTab === 'SAVINGS' && (
          <SavingsManagement currentStaff={currentStaff} onRefresh={loadBackendData} />
        )}

        {activeTab === 'SUPPORT' && (
          <SupportDeskManagement currentStaff={currentStaff} onRefresh={loadBackendData} />
        )}

        {activeTab === 'OPERATIONS' && (
          <AdminOperations staff={currentStaff} />
        )}

        {activeTab === 'AML' && (
          <AmlCaseManagement currentStaff={currentStaff} onRefresh={loadBackendData} />
        )}

        {activeTab === 'AUDIT' && (
          <LedgerAuditLogManagement currentStaff={currentStaff} />
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
