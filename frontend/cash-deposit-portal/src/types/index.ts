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
  /** Hạn mức thấu chi cấp cho ví (tính năng 4.1). 0 = không thấu chi */
  overdraftLimit: number;
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

// --- eKYC Management Types ---
export interface KycApplication {
  id: string;
  userId: string;
  documentType: string;
  documentNumber: string;
  frontImageUrl?: string;
  backImageUrl?: string;
  faceImageUrl?: string;
  verificationStatus: 'PENDING' | 'APPROVED' | 'REJECTED';
  rejectReason?: string;
  currentKycTier?: string;
  createdAt: string;
  verifiedAt?: string;
}

// --- Admin Savings Management Types ---
export interface AdminSavingsAccount {
  id: string;
  userId: string;
  walletId: string;
  accountNumber: string;
  productType: string;
  productName: string;
  principal: number;
  interestRate: number;
  termMonths: number;
  expectedInterest?: number;
  accruedInterest?: number;
  rolloverType: string;
  status: 'ACTIVE' | 'SETTLED' | 'CLOSED';
  startDate: string;
  maturityDate: string;
}

// --- Support Helpdesk Types ---
export interface TicketMessage {
  id: string;
  ticketId: string;
  senderId: string;
  senderType: 'USER' | 'STAFF' | 'SYSTEM';
  content: string;
  sentAt: string;
}

export interface SupportTicket {
  id: string;
  userId: string;
  subject: string;
  description: string;
  category: string;
  status: 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED';
  priority: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  messagesJson?: string;
  resolvedAt?: string;
  resolvedBy?: string;
  createdAt: string;
  updatedAt: string;
}

// --- Anti-Money Laundering (AML) Types (Luật PCRT 2022) ---
export interface AmlTransaction {
  id: string;
  transactionId: string;
  transactionCode?: string;
  type: string;
  status: string;
  amount: number;
  fee?: number;
  currency: string;
  note?: string;
  createdAt: string;
  timestamp?: string;
  sourceWalletId?: string;
  targetWalletId?: string;
  counterpartyWalletId?: string;
  runningBalance?: number;
}

export interface AmlReportResponse {
  content: AmlTransaction[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  last: boolean;
  minThreshold: number;
  standard: string;
}

// --- Dispute & Refund Types (Tra soát & Hoàn tiền) ---
export interface DisputeCase {
  id: string;
  transactionId: string;
  customerId: string;
  disputeType: string;
  reason: string;
  status: 'OPEN' | 'UNDER_REVIEW' | 'APPROVED_REFUND' | 'REJECTED' | 'REVERSED';
  refundAmount: number;
  resolutionNote?: string;
  createdBy: string;
  assignedTo?: string;
  resolvedBy?: string;
  createdAt: string;
  updatedAt: string;
  resolvedAt?: string;
}

export interface DisputeEvent {
  id: string;
  disputeId: string;
  actorId: string;
  action: string;
  note?: string;
  createdAt: string;
}

// --- Notification Operations Types ---
export interface NotificationDlqStats {
  dlqQueueName: string;
  messageCount: number;
  mainQueueName: string;
  mainQueueMessageCount: number;
  exchange: string;
  dlqRoutingKey: string;
}

export interface NotificationProviderHealth {
  overallStatus: 'UP' | 'DOWN';
  fcm?: { status: 'UP' | 'DOWN'; initialized: boolean; message: string };
  websocket?: { status: 'UP' | 'DOWN'; path: string; broker: string; message: string };
  rabbitmq?: { status: 'UP' | 'DOWN'; message: string };
  kafka?: { status: 'UP' | 'DOWN'; message: string };
  activeDeviceTokens?: number;
}

export interface TestPushRequest {
  recipientId: string;
  title: string;
  message: string;
  channel?: 'FCM' | 'WEBSOCKET' | 'ALL';
  referenceId?: string;
}

// --- Staff IAM Administration Types ---
export interface StaffMember {
  id: string;
  username: string;
  fullName: string;
  phoneNumber: string;
  email: string;
  role: string;
  roles?: string[];
  branchId: string;
  status: 'ACTIVE' | 'BLOCKED' | 'CLOSED';
  kycTier?: string;
}

export interface CreateStaffPayload {
  username: string;
  phoneNumber: string;
  fullName: string;
  email: string;
  role: string;
  branchId: string;
  initialPassword?: string;
}

// --- Resilience & Observability Types ---
export interface ResilienceDashboardData {
  overallStatus: 'HEALTHY' | 'DEGRADED' | 'UNHEALTHY';
  timestamp: string;
  database?: {
    status: string;
    poolName: string;
    activeConnections: number;
    idleConnections: number;
    totalConnections: number;
    threadsAwaitingConnection: number;
    connectionTimeoutMs: number;
  };
  redis?: {
    status: string;
    latencyMs: number;
    mode: string;
  };
  messaging?: {
    rabbitMqStatus: string;
    rabbitMqExchange: string;
    kafkaStatus: string;
    kafkaLifecycleTopic: string;
  };
  grpc?: {
    status: string;
    targetService: string;
    port: string;
  };
  microservices?: Record<string, {
    name: string;
    status: string;
    uri: string;
    note: string;
  }>;
}

// --- AML Case Management (Luật PCRT 2022) ---
export type AmlCaseStatus = 'OPEN' | 'ASSIGNED' | 'INVESTIGATING' | 'FROZEN' | 'RELEASED' | 'CLOSED';

export interface AmlCase {
  id: string;
  transactionId: string;
  customerId?: string;
  status: AmlCaseStatus;
  reason?: string;
  assignedTo?: string;
  createdBy?: string;
  slaDueAt?: string;
  createdAt?: string;
  updatedAt?: string;
  closedAt?: string;
  version?: number;
}

export interface AmlCaseEvent {
  id: string;
  caseId: string;
  actorId?: string;
  action: string;
  reason?: string;
  createdAt?: string;
}

export interface CreateAmlCasePayload {
  transactionId: string;
  customerId?: string;
  reason: string;
  slaHours?: number;
}

// --- Ledger Audit Log (Sổ cái kép) ---
export interface LedgerAuditLog {
  id: string;
  eventType: string;
  entityType: string;
  entityId: string;
  description?: string;
  performedBy?: string;
  performedAt?: string;
  serviceName?: string;
  actorRole?: string;
  branchId?: string;
  correlationId?: string;
  clientIp?: string;
  deviceId?: string;
}

export interface AuditLogFilter {
  actorId?: string;
  entityType?: string;
  entityId?: string;
  correlationId?: string;
}




