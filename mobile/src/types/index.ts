// ============ API Response Wrapper ============
export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

// ============ Auth Types ============
export interface LoginRequest {
  phoneNumber: string;
  password: string;
}

export interface RegisterRequest {
  phoneNumber: string;
  password: string;
}

export interface AuthResponse {
  userId: string | null;
  token: string;
}

export interface User {
  id: string;
  phoneNumber: string;
  email?: string;
  fullName?: string;
  status: string;
  createdAt: string;
}

// ============ Profile Types ============
export interface UserProfile {
  userId: string;
  fullName?: string;
  email?: string;
  dateOfBirth?: string;
  avatarUrl?: string;
  address?: string;
  city?: string;
  country?: string;
  updatedAt: string;
}

// ============ Wallet Types ============
export interface Wallet {
  id: string;
  userId: string;
  balance: Money;
  currency: string;
  status: string;
  type: string;
  createdAt: string;
}

export interface Money {
  amount: number;
  currency: string;
}

// ============ Transaction Types ============
export enum TransactionType {
  TRANSFER = 'TRANSFER',
  DEPOSIT = 'DEPOSIT',
  WITHDRAWAL = 'WITHDRAWAL',
  BILL_PAYMENT = 'BILL_PAYMENT',
  TOPUP = 'TOPUP',
  REFUND = 'REFUND',
}

export enum TransactionStatus {
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
}

export interface Transaction {
  id: string;
  requestId: string;
  fromWalletId?: string;
  toWalletId?: string;
  type: TransactionType;
  amount: Money;
  fee: Money;
  status: TransactionStatus;
  description?: string;
  metadata?: Record<string, any>;
  createdAt: string;
  completedAt?: string;
}

export interface TransferRequest {
  requestId: string;
  fromWalletId: string;
  toWalletId: string;
  amount: number;
  currency: string;
  description?: string;
}

// ============ Payment Types ============
export interface VietQrPayload {
  bankBin: string;
  accountNumber: string;
  amount?: number;
  purpose?: string;
  qrString: string;
}

export interface GenerateQrRequest {
  bankBin: string;
  accountNumber: string;
  amount?: number;
  purpose?: string;
}

export enum BillType {
  ELECTRICITY = 'ELECTRICITY',
  WATER = 'WATER',
  INTERNET = 'INTERNET',
  PHONE = 'PHONE',
}

export interface Bill {
  id: string;
  type: BillType;
  customerCode: string;
  customerName: string;
  amount: Money;
  dueDate: string;
  status: string;
}

export interface PayBillRequest {
  requestId: string;
  walletId: string;
  billId: string;
  amount: number;
  currency: string;
}

export interface TopupRequest {
  requestId: string;
  walletId: string;
  phoneNumber: string;
  amount: number;
  currency: string;
}

// ============ Bank Account Types ============
export interface BankAccount {
  id: string;
  userId: string;
  bankName: string;
  accountNumber: string;
  accountHolderName: string;
  bankBin: string;
  isDefault: boolean;
  verified: boolean;
  createdAt: string;
}

export interface AddBankAccountRequest {
  bankName: string;
  accountNumber: string;
  accountHolderName: string;
  bankBin: string;
}

// ============ Beneficiary Types ============
export interface Beneficiary {
  id: string;
  userId: string;
  recipientName: string;
  recipientPhone: string;
  recipientWalletId?: string;
  nickname?: string;
  createdAt: string;
}

// ============ Notification Types ============
export interface Notification {
  id: string;
  userId: string;
  title: string;
  message: string;
  type: string;
  read: boolean;
  metadata?: Record<string, any>;
  createdAt: string;
}

// ============ KYC Types ============
export enum KycStatus {
  NOT_STARTED = 'NOT_STARTED',
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

export interface UserKyc {
  userId: string;
  fullName: string;
  idNumber: string;
  idType: string;
  idIssuedDate: string;
  idExpiryDate?: string;
  idIssuedPlace: string;
  status: KycStatus;
  frontIdImageUrl?: string;
  backIdImageUrl?: string;
  faceImageUrl?: string;
  submittedAt?: string;
  reviewedAt?: string;
}

// ============ Promotion Types ============
export interface Promotion {
  id: string;
  title: string;
  description: string;
  code: string;
  discountType: string;
  discountValue: number;
  minAmount?: number;
  maxDiscount?: number;
  startDate: string;
  endDate: string;
  isActive: boolean;
}

// ============ Referral Types ============
export interface ReferralInfo {
  userId: string;
  referralCode: string;
  referredBy?: string;
  referralCount: number;
  totalRewards: Money;
}

// ============ Navigation Types ============
export type RootStackParamList = {
  // Auth Stack
  Login: undefined;
  Register: undefined;
  ForgotPassword: undefined;
  OtpVerification: {phoneNumber: string; type: 'register' | 'reset'};
  
  // Main Stack
  Home: undefined;
  Profile: undefined;
  EditProfile: undefined;
  Wallet: {walletId: string};
  
  // Transaction Stack
  Transfer: undefined;
  TransferConfirm: {transferData: TransferRequest};
  TransactionDetail: {transactionId: string};
  TransactionHistory: {walletId: string};
  
  // Payment Stack
  ScanQr: undefined;
  GenerateQr: undefined;
  PayBill: undefined;
  Topup: undefined;
  
  // Settings Stack
  Settings: undefined;
  BankAccounts: undefined;
  AddBankAccount: undefined;
  Beneficiaries: undefined;
  AddBeneficiary: undefined;
  Notifications: undefined;
  Security: undefined;
  ChangePassword: undefined;
  
  // KYC Stack
  KycVerification: undefined;
  KycUpload: undefined;
  
  // Other
  Promotions: undefined;
  Referral: undefined;
};
