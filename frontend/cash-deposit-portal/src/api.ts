import { CashDeposit, LoggedInStaff, LoanApplication, VaultSummary, AdminAccount, LedgerReconciliation, LedgerJournalEntry, KycApplication, AdminSavingsAccount, SupportTicket, TicketMessage, AmlTransaction, AmlReportResponse } from './types';

const API_BASE = ''; // Proxied by Vite to http://localhost:8080

function getAuthHeaders(staff?: LoggedInStaff | null): HeadersInit {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (staff?.token) {
    headers['Authorization'] = `Bearer ${staff.token}`;
  }
  if (staff?.id) {
    headers['X-User-Id'] = staff.id;
  }
  if (staff?.role) {
    headers['X-User-Role'] = staff.role === 'TELLER' ? 'ROLE_TELLER' : 'ROLE_MANAGER';
    headers['X-User-Roles'] = staff.role === 'TELLER' ? 'ROLE_TELLER' : 'ROLE_MANAGER';
  }
  if (staff?.branchId) {
    headers['X-Branch-Id'] = staff.branchId;
  }
  return headers;
}

export const ApiService = {
  // --- AUTHENTICATION ---
  async loginStaff(username: string, password: string): Promise<{ success: boolean; staff?: LoggedInStaff; message?: string }> {
    try {
      const cleanUser = username.trim();
      const res = await fetch(`${API_BASE}/api/v1/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: cleanUser,
          phoneNumber: cleanUser,
          phoneOrEmail: cleanUser,
          password
        }),
      });
      const data = await res.json();
      if (res.ok && data.success && data.data) {
        const token = data.data.accessToken || data.data.token;
        const payload = data.data.user || data.data;
        const roles: string[] = Array.isArray(payload.roles)
          ? payload.roles
          : (payload.role ? [payload.role] : []);
        const isManager = roles.some((r: string) => r.toUpperCase().includes('MANAGER')) ||
          (payload.role || '').toUpperCase().includes('MANAGER');

        const staff: LoggedInStaff = {
          id: payload.userId || payload.id || 'staff-' + Date.now(),
          username: payload.username || payload.phoneNumber || cleanUser,
          fullName: payload.fullName || payload.name || (isManager ? 'Kiểm soát viên' : 'Giao dịch viên'),
          role: isManager ? 'MANAGER' : 'TELLER',
          branchId: payload.branchId || 'BR_Q1',
          branchName: payload.branchName || (isManager ? 'Kiểm soát viên Chi nhánh Quận 1' : 'Chi nhánh Quận 1 (TP.HCM)'),
          token,
        };
        return { success: true, staff };
      }
      return { success: false, message: data.message || 'Đăng nhập không thành công' };
    } catch (err: any) {
      return { success: false, message: err.message || 'Không thể kết nối API Gateway' };
    }
  },

  // --- CASH DEPOSITS ---
  async fetchVaultSummary(staff?: LoggedInStaff | null): Promise<VaultSummary | null> {
    try {
      // Thử gọi /api/v1/cash/vault/summary trước, nếu cần fallback sang /vault-summary
      let res = await fetch(`${API_BASE}/api/v1/cash/vault/summary`, {
        headers: getAuthHeaders(staff),
      });
      if (!res.ok) {
        res = await fetch(`${API_BASE}/api/v1/cash/vault-summary`, {
          headers: getAuthHeaders(staff),
        });
      }
      if (res.ok) {
        const json = await res.json();
        if (json.data) return json.data;
      }
      return null;
    } catch {
      return null;
    }
  },

  async fetchDeposits(staff?: LoggedInStaff | null): Promise<CashDeposit[]> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/cash/deposits`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        if (Array.isArray(json.data)) {
          return json.data.map((item: any) => ({
            id: item.id || item.depositCode,
            code: item.depositCode || item.code,
            customerName: item.customerName,
            accountNumber: item.accountNumber,
            citizenId: item.citizenId,
            phoneNumber: item.phoneNumber,
            amount: Number(item.amount),
            makerName: item.makerName || item.makerId || 'Giao dịch viên',
            makerId: item.makerId,
            checkerName: item.checkerName || item.checkerId,
            status: item.status,
            timestamp: item.createdAt || item.timestamp || new Date().toISOString(),
            note: item.note,
            hash: item.receiptHash || item.hash,
            rejectionReason: item.rejectionReason,
          }));
        }
      }
      return [];
    } catch {
      return [];
    }
  },

  async createDeposit(
    staff: LoggedInStaff,
    data: { accountNumber: string; customerName: string; amount: number; note: string; citizenId?: string; phoneNumber?: string }
  ): Promise<{ success: boolean; data?: any; message?: string }> {
    try {
      const idemKey = 'dep_fe_' + Date.now() + '_' + Math.floor(Math.random() * 10000);
      const res = await fetch(`${API_BASE}/api/v1/cash/deposits`, {
        method: 'POST',
        headers: {
          ...getAuthHeaders(staff),
          'Idempotency-Key': idemKey,
        },
        body: JSON.stringify({
          accountNumber: data.accountNumber,
          customerName: data.customerName,
          amount: data.amount,
          currency: 'VND',
          branchId: staff.branchId,
          makerId: staff.id,
          note: data.note,
          idempotencyKey: idemKey,
        }),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, data: json.data, message: json.message };
      }
      return { success: false, message: json.message || 'Lỗi khi lập lệnh nạp tiền' };
    } catch (err: any) {
      return { success: false, message: err.message };
    }
  },

  async approveDeposit(staff: LoggedInStaff, depositId: string): Promise<{ success: boolean; message?: string }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/cash/deposits/${depositId}/approve`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
        body: JSON.stringify({
          checkerId: staff.id,
          role: 'ROLE_MANAGER',
        }),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message };
      }
      return { success: false, message: json.message || 'Lỗi khi phê duyệt nạp tiền' };
    } catch (err: any) {
      return { success: false, message: err.message };
    }
  },

  async rejectDeposit(staff: LoggedInStaff, depositId: string, reason: string): Promise<{ success: boolean; message?: string }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/cash/deposits/${depositId}/reject`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
        body: JSON.stringify({
          checkerId: staff.id,
          role: 'ROLE_MANAGER',
          reason,
        }),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message };
      }
      return { success: false, message: json.message || 'Lỗi khi từ chối nạp tiền' };
    } catch (err: any) {
      return { success: false, message: err.message };
    }
  },

  // --- P2P TRANSFERS ---
  async lookupRecipientInfo(staff: LoggedInStaff, phoneNumber: string): Promise<{ ownerId?: string; fullName?: string; walletId?: string } | null> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/wallets/recipient-info?phoneNumber=${encodeURIComponent(phoneNumber.trim())}`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        if (json.success && json.data) {
          return {
            ownerId: json.data.ownerId || json.data.userId,
            fullName: json.data.fullName || json.data.customerName,
            walletId: json.data.walletId || json.data.id,
          };
        }
      }
      return null;
    } catch {
      return null;
    }
  },

  async transferP2p(
    staff: LoggedInStaff,
    data: { senderPhone: string; receiverPhone: string; amount: number; note: string }
  ): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      // 1. Tra cứu người gửi và người nhận để lấy userId
      const [senderInfo, receiverInfo] = await Promise.all([
        this.lookupRecipientInfo(staff, data.senderPhone),
        this.lookupRecipientInfo(staff, data.receiverPhone),
      ]);

      if (!senderInfo || !senderInfo.ownerId) {
        return { success: false, message: `Không tìm thấy ví của người gửi (SĐT: ${data.senderPhone})` };
      }
      if (!receiverInfo || !receiverInfo.ownerId) {
        return { success: false, message: `Không tìm thấy ví của người nhận (SĐT: ${data.receiverPhone})` };
      }

      const idemKey = 'tf_fe_' + Date.now() + '_' + Math.floor(Math.random() * 10000);
      const res = await fetch(`${API_BASE}/api/v1/payments/transfer`, {
        method: 'POST',
        headers: {
          ...getAuthHeaders(staff),
          'Idempotency-Key': idemKey,
        },
        body: JSON.stringify({
          sourceUserId: senderInfo.ownerId,
          targetUserId: receiverInfo.ownerId,
          amount: data.amount,
          currency: 'VND',
          note: data.note || 'Chuyển tiền ví điện tử',
          idempotencyKey: idemKey,
        }),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message || 'Chuyển tiền P2P thành công', data: json.data };
      }
      return { success: false, message: json.message || 'Chuyển tiền thất bại' };
    } catch (err: any) {
      return { success: false, message: err.message || 'Lỗi mạng khi thực hiện chuyển tiền' };
    }
  },

  // --- LOAN APPROVALS ---
  async fetchPendingLoans(staff?: LoggedInStaff | null): Promise<LoanApplication[]> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/loans/pending`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        if (Array.isArray(json.data)) {
          return json.data.map((item: any) => ({
            id: item.id,
            userId: item.userId,
            productCode: item.productCode,
            productName: item.productName || 'Vay tiêu dùng tín chấp Sen Hồng',
            amount: Number(item.principalAmount || item.amount || 0),
            termMonths: Number(item.termMonths || 6),
            interestRateYear: Number(item.interestRateYear || 9.5),
            purpose: item.purpose || 'Chi tiêu cá nhân',
            status: item.status || 'PENDING_APPROVAL',
            monthlyEstimate: Number(item.monthlyPayment || item.monthlyEstimate || 0),
            createdAt: item.createdAt || new Date().toISOString(),
            approvedBy: item.approvedBy,
            rejectionReason: item.rejectionReason,
          }));
        }
      }
      return [];
    } catch {
      return [];
    }
  },

  async approveLoan(staff: LoggedInStaff, loanId: string): Promise<{ success: boolean; message?: string }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/loans/${loanId}/approve`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message || 'Phê duyệt khoản vay và giải ngân thành công' };
      }
      return { success: false, message: json.message || 'Lỗi khi duyệt khoản vay' };
    } catch (err: any) {
      return { success: false, message: err.message };
    }
  },

  async rejectLoan(staff: LoggedInStaff, loanId: string, reason: string): Promise<{ success: boolean; message?: string }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/loans/${loanId}/reject?reason=${encodeURIComponent(reason)}`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message || 'Từ chối hồ sơ vay thành công' };
      }
      return { success: false, message: json.message || 'Lỗi khi từ chối hồ sơ vay' };
    } catch (err: any) {
      return { success: false, message: err.message };
    }
  },

  // --- ADMIN / DIRECTOR: ACCOUNT DIRECTORY & FILTER ---
  async fetchAdminAccounts(
    staff: LoggedInStaff,
    filters?: { keyword?: string; status?: string; minBalance?: number; maxBalance?: number }
  ): Promise<AdminAccount[]> {
    try {
      const params = new URLSearchParams();
      if (filters?.keyword) params.append('keyword', filters.keyword);
      if (filters?.status && filters.status !== 'ALL') params.append('status', filters.status);
      if (filters?.minBalance !== undefined && filters.minBalance > 0) params.append('minBalance', filters.minBalance.toString());
      if (filters?.maxBalance !== undefined && filters.maxBalance > 0) params.append('maxBalance', filters.maxBalance.toString());

      const url = `${API_BASE}/api/v1/wallets/admin/accounts${params.toString() ? '?' + params.toString() : ''}`;
      const res = await fetch(url, { headers: getAuthHeaders(staff) });
      if (res.ok) {
        const json = await res.json();
        if (Array.isArray(json.data)) {
          return json.data.map((item: any) => ({
            id: item.id || item.walletId,
            walletId: item.walletId || item.id,
            accountNumber: item.accountNumber || item.id,
            userId: item.userId || item.ownerId,
            customerName: item.customerName || 'Khách hàng',
            phoneNumber: item.phoneNumber || 'N/A',
            balance: Number(item.balance || 0),
            overdraftLimit: Number(item.overdraftLimit || 0),
            currency: item.currency || 'VND',
            status: item.status || 'ACTIVE',
            kycTier: item.kycTier || 'TIER_1',
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
          }));
        }
      }
      return [];
    } catch (e) {
      console.error('fetchAdminAccounts error:', e);
      return [];
    }
  },

  async updateWalletStatus(
    staff: LoggedInStaff,
    walletId: string,
    status: 'ACTIVE' | 'BLOCKED'
  ): Promise<{ success: boolean; message?: string }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/wallets/admin/accounts/${walletId}/status?status=${status}`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message || `Cập nhật trạng thái ví thành công: ${status}` };
      }
      return { success: false, message: json.message || 'Lỗi khi cập nhật trạng thái ví' };
    } catch (err: any) {
      return { success: false, message: err.message };
    }
  },

  // --- TÍNH NĂNG 4.1: HẠN MỨC THẤU CHI (OVERDRAFT LIMIT) ---
  async setOverdraftLimit(
    staff: LoggedInStaff,
    walletId: string,
    limit: number
  ): Promise<{ success: boolean; message?: string; data?: any }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/wallets/admin/accounts/${walletId}/overdraft-limit?limit=${limit}`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message || 'Cập nhật hạn mức thấu chi thành công', data: json.data };
      }
      return { success: false, message: json.message || 'Lỗi khi cập nhật hạn mức thấu chi' };
    } catch (err: any) {
      return { success: false, message: err.message };
    }
  },

  async accrueOverdraftInterest(
    staff?: LoggedInStaff | null,
    annualRate: number = 16.0,
    days: number = 1
  ): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/wallets/admin/overdraft-interest/accrue?annualRate=${annualRate}&daysInPeriod=${days}`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message || 'Tính lãi vay thấu chi thành công', data: json.data };
      }
      return { success: false, message: json.message || 'Lỗi tính lãi thấu chi' };
    } catch (e: any) {
      return { success: false, message: e.message || 'Lỗi kết nối tính lãi thấu chi' };
    }
  },

  // --- LEDGER RECONCILIATION & JOURNAL ENTRIES ---
  async fetchLedgerBalanceCheck(staff?: LoggedInStaff | null): Promise<LedgerReconciliation | null> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/ledger/accounts/balance-check`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        const data = json.data;
        if (data) {
          const totalDebit = Number(data.totalDebit || 0);
          const totalCredit = Number(data.totalCredit || 0);
          const delta = Math.abs(totalDebit - totalCredit);
          return {
            totalDebit,
            totalCredit,
            delta,
            balanced: data.balanced ?? (delta === 0),
            generatedAt: data.reconciledAt || new Date().toISOString(),
          };
        }
      }
      return null;
    } catch (e) {
      console.error('fetchLedgerBalanceCheck error:', e);
      return null;
    }
  },

  async closeEndOfDay(staff?: LoggedInStaff | null): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/ledger/admin/eod/close-day`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message || 'Khóa sổ kế toán cuối ngày thành công', data: json.data };
      }
      return { success: false, message: json.message || 'Lỗi khóa sổ cuối ngày' };
    } catch (e: any) {
      return { success: false, message: e.message || 'Lỗi kết nối khóa sổ cuối ngày' };
    }
  },

  async accrueCasaInterest(
    staff?: LoggedInStaff | null,
    annualRate: number = 0.2,
    days: number = 30
  ): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/wallets/admin/casa-interest/accrue?annualRate=${annualRate}&daysInPeriod=${days}`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message || 'Tính lãi tiền gửi không kỳ hạn CASA thành công', data: json.data };
      }
      return { success: false, message: json.message || 'Lỗi tính lãi CASA' };
    } catch (e: any) {
      return { success: false, message: e.message };
    }
  },

  async fetchJournalEntries(staff?: LoggedInStaff | null): Promise<LedgerJournalEntry[]> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/ledger/entries`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        if (Array.isArray(json.data)) {
          return json.data.map((item: any) => ({
            id: item.id || item.entryId,
            transactionId: item.transactionId || item.referenceId || 'N/A',
            transactionType: item.transactionType || item.type || 'P2P_TRANSFER',
            description: item.description || 'Giao dịch chuyển tiền / nạp rút',
            status: item.status || 'POSTED',
            totalDebit: Number(item.totalDebit || 0),
            totalCredit: Number(item.totalCredit || 0),
            postings: Array.isArray(item.postings) ? item.postings.map((p: any) => ({
              id: p.id,
              accountId: p.accountId,
              accountNumber: p.accountNumber,
              accountName: p.accountName,
              type: p.type || p.entryType,
              amount: Number(p.amount || 0),
              currency: p.currency || 'VND',
            })) : [],
            createdAt: item.createdAt || item.postedAt || new Date().toISOString(),
          }));
        }
      }
      return [];
    } catch (e) {
      console.error('fetchJournalEntries error:', e);
      return [];
    }
  },

  // --- eKYC Management ---
  async fetchPendingKyc(staff?: LoggedInStaff | null): Promise<KycApplication[]> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/kyc/pending`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        if (Array.isArray(json.data)) {
          return json.data.map((item: any) => ({
            id: item.id,
            userId: item.userId,
            documentType: item.documentType || 'CCCD',
            documentNumber: item.documentNumber,
            frontImageUrl: item.frontImageUrl,
            backImageUrl: item.backImageUrl,
            faceImageUrl: item.faceImageUrl,
            verificationStatus: item.verificationStatus || 'PENDING',
            rejectReason: item.rejectReason,
            currentKycTier: item.currentKycTier || 'BASIC',
            createdAt: item.createdAt || new Date().toISOString(),
            verifiedAt: item.verifiedAt,
          }));
        }
      }
      return [];
    } catch (e) {
      console.error('fetchPendingKyc error:', e);
      return [];
    }
  },

  async reviewKyc(
    staff: LoggedInStaff | null,
    kycId: string,
    status: 'APPROVED' | 'REJECTED',
    reason?: string
  ): Promise<{ success: boolean; message: string }> {
    try {
      const query = new URLSearchParams({ status });
      if (reason) query.set('reason', reason);
      const res = await fetch(`${API_BASE}/api/v1/kyc/${kycId}/review?${query.toString()}`, {
        method: 'PUT',
        headers: getAuthHeaders(staff),
      });
      const data = await res.json();
      if (res.ok && data.success) {
        return { success: true, message: data.message || 'Cập nhật trạng thái duyệt eKYC thành công' };
      }
      return { success: false, message: data.message || 'Thao tác không thành công' };
    } catch (e: any) {
      return { success: false, message: e.message || 'Lỗi kết nối duyệt eKYC' };
    }
  },

  // --- Admin Savings Accounts ---
  async fetchAdminSavings(staff?: LoggedInStaff | null): Promise<AdminSavingsAccount[]> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/savings/admin/accounts`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        if (Array.isArray(json.data)) {
          return json.data.map((item: any) => ({
            id: item.id,
            userId: item.userId,
            walletId: item.walletId,
            accountNumber: item.accountNumber,
            productType: item.productType || 'TERM_DEPOSIT',
            productName: item.productName || 'Tiết kiệm có kỳ hạn',
            principal: Number(item.principal || 0),
            interestRate: Number(item.interestRate || 0),
            termMonths: Number(item.termMonths || 0),
            expectedInterest: Number(item.expectedInterest || 0),
            accruedInterest: Number(item.accruedInterest || 0),
            rolloverType: item.rolloverType || 'PRINCIPAL_AND_INTEREST',
            status: item.status || 'ACTIVE',
            startDate: item.startDate || new Date().toISOString().split('T')[0],
            maturityDate: item.maturityDate || new Date().toISOString().split('T')[0],
          }));
        }
      }
      return [];
    } catch (e) {
      console.error('fetchAdminSavings error:', e);
      return [];
    }
  },

  async withdrawSavingsPartial(
    staff: LoggedInStaff | null,
    savingsId: string,
    amount: number,
    pinToken?: string
  ): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/savings/accounts/${savingsId}/withdraw-partial`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
        body: JSON.stringify({ withdrawAmount: amount, pinToken }),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        return { success: true, message: json.message || 'Rút gốc từng phần thành công', data: json.data };
      }
      return { success: false, message: json.message || 'Lỗi rút gốc từng phần' };
    } catch (e: any) {
      return { success: false, message: e.message || 'Lỗi kết nối rút gốc từng phần' };
    }
  },

  // --- Customer Support Helpdesk ---
  async fetchSupportTickets(staff?: LoggedInStaff | null): Promise<SupportTicket[]> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/support/admin/tickets`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        if (Array.isArray(json.data)) {
          return json.data;
        }
      }
      return [];
    } catch (e) {
      console.error('fetchSupportTickets error:', e);
      return [];
    }
  },

  async fetchTicketDetail(staff: LoggedInStaff | null, ticketId: string): Promise<{ ticket: SupportTicket; messages: TicketMessage[] } | null> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/support/tickets/${ticketId}`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data) {
          return json.data;
        }
      }
      return null;
    } catch (e) {
      console.error('fetchTicketDetail error:', e);
      return null;
    }
  },

  async sendTicketReply(staff: LoggedInStaff | null, ticketId: string, content: string): Promise<{ success: boolean; message: string; data?: TicketMessage }> {
    try {
      const query = new URLSearchParams({ content, senderType: 'STAFF' });
      const res = await fetch(`${API_BASE}/api/v1/support/tickets/${ticketId}/messages?${query.toString()}`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const data = await res.json();
      if (res.ok && data.success) {
        return { success: true, message: data.message || 'Phản hồi thành công', data: data.data };
      }
      return { success: false, message: data.message || 'Không thể gửi phản hồi' };
    } catch (e: any) {
      return { success: false, message: e.message || 'Lỗi gửi tin nhắn phản hồi' };
    }
  },

  async resolveSupportTicket(staff: LoggedInStaff | null, ticketId: string, notes?: string): Promise<{ success: boolean; message: string }> {
    try {
      const query = new URLSearchParams();
      if (notes) query.set('resolutionNotes', notes);
      const res = await fetch(`${API_BASE}/api/v1/support/tickets/${ticketId}/resolve?${query.toString()}`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const data = await res.json();
      if (res.ok && data.success) {
        return { success: true, message: data.message || 'Đã giải quyết yêu cầu hỗ trợ' };
      }
      return { success: false, message: data.message || 'Không thể giải quyết ticket' };
    } catch (e: any) {
      return { success: false, message: e.message || 'Lỗi xử lý yêu cầu' };
    }
  },

  async closeSupportTicket(staff: LoggedInStaff | null, ticketId: string): Promise<{ success: boolean; message: string }> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/support/tickets/${ticketId}/close`, {
        method: 'POST',
        headers: getAuthHeaders(staff),
      });
      const data = await res.json();
      if (res.ok && data.success) {
        return { success: true, message: data.message || 'Đã đóng yêu cầu hỗ trợ' };
      }
      return { success: false, message: data.message || 'Không thể đóng ticket' };
    } catch (e: any) {
      return { success: false, message: e.message || 'Lỗi đóng ticket' };
    }
  },

  // --- Export Statements & Receipts ---
  async exportTransactionsCsv(staff?: LoggedInStaff | null, walletId?: string): Promise<Blob | null> {
    try {
      const query = new URLSearchParams();
      if (walletId) query.set('walletId', walletId);
      const res = await fetch(`${API_BASE}/api/v1/transactions/export/csv?${query.toString()}`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        return await res.blob();
      }
      return null;
    } catch (e) {
      console.error('exportTransactionsCsv error:', e);
      return null;
    }
  },

  async downloadReceiptPdf(staff: LoggedInStaff | null, txId: string): Promise<Blob | null> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/transactions/${txId}/receipt.pdf`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        return await res.blob();
      }
      return null;
    } catch (e) {
      console.error('downloadReceiptPdf error:', e);
      return null;
    }
  },

  // --- AML Large Transactions Monitoring (Luật PCRT 2022) ---
  async fetchAmlLargeTransactions(
    staff?: LoggedInStaff | null,
    minAmount: number = 400000000,
    page: number = 0,
    size: number = 50
  ): Promise<AmlReportResponse | null> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/transactions/aml/large?minAmount=${minAmount}&page=${page}&size=${size}`, {
        headers: getAuthHeaders(staff),
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data) {
          return json.data;
        }
      }
      return null;
    } catch (e) {
      console.error('fetchAmlLargeTransactions error:', e);
      return null;
    }
  },
};

