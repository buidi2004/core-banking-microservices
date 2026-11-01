export type Role = 'TELLER' | 'MANAGER';

export type DepositStatus = 'PENDING_APPROVAL' | 'APPROVED' | 'REJECTED' | 'COMPLETED';

export type SearchMethod = 'PHONE' | 'CITIZEN_ID' | 'ACCOUNT_NUMBER';

export interface LoggedInStaff {
  id: string;
  username: string;
  fullName: string;
  role: Role;
  branchId: string;
  branchName: string;
  token?: string;
}

export interface CashDeposit {
  id: string;
  code: string;
  customerName: string;
  accountNumber: string;
  citizenId?: string;
  phoneNumber?: string;
  amount: number;
  makerName: string;
  makerId: string;
  checkerName?: string | null;
  status: DepositStatus;
  timestamp: string;
  note?: string;
  hash?: string;
  rejectionReason?: string;
}

export interface CustomerAccount {
  accountNumber: string;
  phoneNumber: string;
  citizenId: string;
  customerName: string;
  balance: number;
  status: 'ACTIVE' | 'BLOCKED';
  kycTier: 'VERIFIED_BIOMETRIC' | 'TIER_1' | 'PENDING';
  branchName: string;
}

export interface VaultSummary {
  openingBalance: number;
  totalCashIn: number;
  currentBalance: number;
  maxLimit: number;
  successCount: number;
  pendingCount: number;
}

export interface LedgerBalance {
  debit1011: number;
  credit4211: number;
  delta: number;
}

// --- Transfer (P2P) Types ---

export type TransferStatus = 'PENDING' | 'COMPLETED' | 'FAILED' | 'REVERSED';

export interface Transfer {
  id: string;
  code: string;
  senderPhone: string;
  receiverPhone: string;
  senderAccountNumber: string;
  receiverAccountNumber: string;
  amount: number;
  currency: string;
  status: TransferStatus;
  note?: string;
  createdAt: string;
  completedAt?: string;
  failureReason?: string;
}

export interface TransferRequest {
  senderPhone: string;
  receiverPhone: string;
  amount: number;
  note?: string;
  senderAccountNumber?: string; // optional - can be derived from phone
}

export interface TransferResponse {
  success: boolean;
  transfer: Transfer;
  message: string;
  newSenderBalance: number;
  newReceiverBalance: number;
}

// --- Loan Application Types ---
export interface LoanApplication {
  id: string;
  userId: string;
  productCode?: string;
  productName?: string;
  amount: number;
  termMonths: number;
  interestRateYear?: number;
  purpose?: string;
  status: 'PENDING_APPROVAL' | 'APPROVED' | 'REJECTED' | 'ACTIVE' | 'PAID';
  monthlyEstimate?: number;
  createdAt?: string;
  approvedBy?: string;
  rejectionReason?: string;
}

// --- Admin Director & Ledger Types ---
export interface AdminAccount {
  id: string;
  walletId: string;
  accountNumber: string;
  userId: string;
  customerName: string;
  phoneNumber: string;
  balance: number;
  currency: string;
  status: 'ACTIVE' | 'BLOCKED';
  kycTier: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface LedgerReconciliation {
  totalDebit: number;
  totalCredit: number;
  delta: number;
  balanced: boolean;
  generatedAt?: string;
}

export interface LedgerPostingItem {
  id: string;
  accountId: string;
  accountNumber?: string;
  accountName?: string;
  type: 'DEBIT' | 'CREDIT';
  amount: number;
  currency: string;
}

export interface LedgerJournalEntry {
  id: string;
  transactionId: string;
  transactionType: string;
  description: string;
  status: string;
  totalDebit?: number;
  totalCredit?: number;
  postings?: LedgerPostingItem[];
  createdAt: string;
}

