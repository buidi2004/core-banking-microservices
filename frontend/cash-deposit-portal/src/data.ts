import { CashDeposit, CustomerAccount, LoggedInStaff } from './types';

export const OPENING_VAULT_BALANCE = 50_000_000;
export const MAX_VAULT_LIMIT = 500_000_000;
export const AUTO_APPROVE_LIMIT = 50_000_000;

export const STAFF_ACCOUNTS: LoggedInStaff[] = [
  {
    id: 't0000001-0000-0000-0000-000000000001',
    username: 'teller1',
    fullName: 'Teller Nguyễn Văn A',
    role: 'TELLER',
    branchId: 'BR_Q1',
    branchName: 'Chi nhánh Quận 1 (TP.HCM)',
  },
  {
    id: 't0000002-0000-0000-0000-000000000002',
    username: 'teller2',
    fullName: 'Teller Trần Thị B',
    role: 'TELLER',
    branchId: 'BR_HK',
    branchName: 'Chi nhánh Hoàn Kiếm (Hà Nội)',
  },
  {
    id: 'm0000001-0000-0000-0000-000000000001',
    username: 'manager1',
    fullName: 'Manager Lê Hoàng C',
    role: 'MANAGER',
    branchId: 'BR_Q1',
    branchName: 'Kiểm soát viên Chi nhánh Quận 1',
  },
];

export const CUSTOMER_ACCOUNTS: CustomerAccount[] = [
  {
    accountNumber: 'W-BUIDI-7777',
    phoneNumber: '0987654321',
    citizenId: '079204009999',
    customerName: 'Bùi Văn Dĩ',
    balance: 10_000_000,
    status: 'ACTIVE',
    kycTier: 'VERIFIED_BIOMETRIC',
    branchName: 'Chi nhánh Quận 1 (TP.HCM)',
  },
  {
    accountNumber: 'W-ALICE-1001',
    phoneNumber: '0901234567',
    citizenId: 'a11ce000-0000-0000-0000-000000000001',
    customerName: 'Alice Nguyen',
    balance: 14_500_000,
    status: 'ACTIVE',
    kycTier: 'VERIFIED_BIOMETRIC',
    branchName: 'Chi nhánh Quận 1 (TP.HCM)',
  },
  {
    accountNumber: 'W-BOB-2002',
    phoneNumber: '0909876543',
    citizenId: '079204005678',
    customerName: 'Bob Tran',
    balance: 151_500_000,
    status: 'ACTIVE',
    kycTier: 'VERIFIED_BIOMETRIC',
    branchName: 'Chi nhánh Quận 1 (TP.HCM)',
  },
  {
    accountNumber: 'W-CHARLIE-3003',
    phoneNumber: '0912345678',
    citizenId: '001091234567',
    customerName: 'Charlie Le',
    balance: 25_000_000,
    status: 'ACTIVE',
    kycTier: 'TIER_1',
    branchName: 'Chi nhánh Hoàn Kiếm (Hà Nội)',
  },
  {
    accountNumber: 'W-DAVID-4004',
    phoneNumber: '0933333333',
    citizenId: '079093333333',
    customerName: 'David Pham',
    balance: 5_000_000,
    status: 'BLOCKED',
    kycTier: 'VERIFIED_BIOMETRIC',
    branchName: 'Chi nhánh Quận 1 (TP.HCM)',
  },
  {
    accountNumber: 'W-HOANG-5005',
    phoneNumber: '0988889999',
    citizenId: '001098889999',
    customerName: 'Hoang Mai',
    balance: 80_000_000,
    status: 'ACTIVE',
    kycTier: 'VERIFIED_BIOMETRIC',
    branchName: 'Chi nhánh Đà Nẵng',
  },
];

export const INITIAL_DEPOSITS: CashDeposit[] = [];