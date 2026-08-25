/**
 * API Service Client for Fintech Wallet Mobile App
 * Connects to Spring Boot Backend (Hexagonal Architecture)
 *
 * ENVIRONMENT CONFIG:
 * - Development (Expo Go/Simulator): Set API_BASE_URL to your local machine IP, e.g. http://192.168.1.100:8080/api/v1
 * - Expo Tunnel: Use https://<your-ngrok-id>.ngrok.io/api/v1
 * - Production: Replace with your deployed API domain.
 *
 * NOTE: 'localhost' does NOT work from a physical device. Use your machine's LAN IP.
 * The app currently runs in OFFLINE DEMO MODE (API calls are not wired into screens yet).
 */

// --- ⚠️ IMPORTANT: Change this to your machine's LAN IP when testing on physical device ---
// Example: export const API_BASE_URL = 'http://192.168.1.100:8080/api/v1';
export const API_BASE_URL = 'http://172.29.37.86:8080/api/v1';

let authToken: string | null = null;
let refreshToken: string | null = null;

export const setAuthTokens = (access: string | null, refresh: string | null = null) => {
  authToken = access;
  refreshToken = refresh;
};

export const getAuthToken = () => authToken;

// Helper to generate RFC4122 UUID for Idempotency-Key
export const generateUUID = () => {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
};

interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  timestamp?: string;
  errorCode?: string;
}

async function request<T>(
  endpoint: string,
  options: RequestInit = {},
  requireIdempotency = false
): Promise<ApiResponse<T>> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`;
  }

  if (requireIdempotency && !headers['Idempotency-Key']) {
    headers['Idempotency-Key'] = generateUUID();
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 15000); // 15 seconds timeout

  let response;
  try {
    response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers,
      signal: controller.signal as any,
    });
  } catch (error: any) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('Kết nối tới máy chủ đã hết hạn (Timeout). Vui lòng kiểm tra lại mạng.');
    }
    throw error;
  }
  clearTimeout(timeoutId);

  // Interceptor for 401 Unauthorized - attempt to refresh token
  if (response.status === 401 && refreshToken && !endpoint.includes('/auth/refresh')) {
    try {
      const refreshResponse = await fetch(`${API_BASE_URL}/auth/refresh?refreshToken=${encodeURIComponent(refreshToken)}`, {
        method: 'POST',
      });
      const refreshJson = await refreshResponse.json();
      
      if (refreshResponse.ok && refreshJson.success) {
        authToken = refreshJson.data.accessToken;
        refreshToken = refreshJson.data.refreshToken;
        
        // Retry the original request with new token
        headers['Authorization'] = `Bearer ${authToken}`;
        
        const retryController = new AbortController();
        const retryTimeoutId = setTimeout(() => retryController.abort(), 15000);
        
        try {
          response = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers,
            signal: retryController.signal as any,
          });
        } catch (e: any) {
          clearTimeout(retryTimeoutId);
          if (e.name === 'AbortError') {
            throw new Error('Kết nối tới máy chủ đã hết hạn (Timeout). Vui lòng kiểm tra lại mạng.');
          }
          throw e;
        } finally {
          clearTimeout(retryTimeoutId);
        }
      } else {
        // Refresh failed, clear tokens (simulate logout)
        authToken = null;
        refreshToken = null;
      }
    } catch (e) {
      authToken = null;
      refreshToken = null;
    }
  }

  const json = await response.json();
  if (!response.ok || !json.success) {
    throw new Error(json.message || `Request failed with status ${response.status}`);
  }

  return json;
}

export const WalletApi = {
  // --- Auth & Security ---
  register: (phoneNumber: string, password: string) =>
    request<{ userId: string; accessToken: string; refreshToken: string }>('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ phoneNumber, password }),
    }),

  login: (phoneNumber: string, password: string) =>
    request<{ accessToken: string; refreshToken: string }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ phoneNumber, password }),
    }),

  logout: () =>
    request<void>('/auth/logout', {
      method: 'POST',
    }),

  sendOtp: (phoneNumber: string) =>
    request<void>(`/auth/otp/send?phoneNumber=${encodeURIComponent(phoneNumber)}`, {
      method: 'POST',
    }),

  verifyOtp: (phoneNumber: string, otp: string) =>
    request<boolean>(`/auth/otp/verify?phoneNumber=${encodeURIComponent(phoneNumber)}&otp=${encodeURIComponent(otp)}`, {
      method: 'POST',
    }),

  sendPasswordResetOtp: (phoneNumber: string) =>
    request<void>(`/auth/forgot-password?phoneNumber=${encodeURIComponent(phoneNumber)}`, {
      method: 'POST',
    }),

  resetPassword: (phoneNumber: string, otp: string, newPassword: string) =>
    request<void>(
      `/auth/reset-password?phoneNumber=${encodeURIComponent(phoneNumber)}&otp=${encodeURIComponent(otp)}&newPassword=${encodeURIComponent(newPassword)}`,
      { method: 'POST' }
    ),

  // --- Wallet Operations ---
  getWallet: (walletId: string) =>
    request<{ id: string; ownerId: string; balance: number; currency: string }>(`/wallets/${walletId}`),

  getRecipientInfo: (walletId?: string, phoneNumber?: string) => {
    const params = new URLSearchParams();
    if (walletId) params.append('walletId', walletId);
    if (phoneNumber) params.append('phoneNumber', phoneNumber);
    return request<{ walletId: string; phoneNumber: string; maskedName: string }>(
      `/wallets/recipient-info?${params.toString()}`
    );
  },

  deposit: (walletId: string, amount: number, currency = 'VND') =>
    request<{ id: string; status: string; amount: number }>(
      '/wallets/deposit',
      {
        method: 'POST',
        body: JSON.stringify({ requestId: generateUUID(), walletId, amount, currency }),
      },
      true
    ),

  verifyPin: (pin: string) =>
    request<{ pinToken: string }>('/users/pin/verify', {
      method: 'POST',
      body: JSON.stringify({ pin }),
    }),

  setPin: (pin: string) =>
    request<any>('/users/pin/set', {
      method: 'POST',
      body: JSON.stringify({ pin }),
    }),

  submitKyc: (idCardNumber: string, fullName: string, dob: string, frontCardUrl: string, backCardUrl: string, selfieUrl: string) =>
    request<any>('/users/kyc', {
      method: 'POST',
      body: JSON.stringify({ idCardNumber, fullName, dob, frontCardUrl, backCardUrl, selfieUrl }),
    }),

  getKycStatus: () =>
    request<any>('/users/kyc/status'),

  withdraw: (walletId: string, amount: number, currency = 'VND', bankAccountId: string, pinToken: string) =>
    request<{ id: string; status: string; amount: number }>(
      '/wallets/withdraw',
      {
        method: 'POST',
        body: JSON.stringify({ requestId: generateUUID(), walletId, amount, currency, bankAccountId, pinToken }),
      },
      true
    ),

  initTransfer: (sourceWalletId: string, targetWalletId: string, amount: number, currency = 'VND') =>
    request<{ transactionId: string; status: string; amount: number }>(
      '/wallets/transfer/init',
      {
        method: 'POST',
        body: JSON.stringify({ requestId: generateUUID(), sourceWalletId, targetWalletId, amount, currency }),
      },
      true
    ),

  confirmTransfer: (transactionId: string, pin: string, otp: string) => {
    const params = new URLSearchParams();
    if (pin) params.append('pin', pin);
    if (otp) params.append('otp', otp);
    return request<{ transactionId: string; status: string }>(
      `/wallets/transfer/${transactionId}/confirm?${params.toString()}`,
      { method: 'POST' },
      true
    );
  },

  initTransferQr: (qrCode: string, amount?: number) =>
    request<{ id: string; status: string; amount: number; transactionId?: string }>(
      '/wallets/transfer/qr/init',
      {
        method: 'POST',
        body: JSON.stringify({ requestId: generateUUID(), qrCode, amount }),
      },
      true
    ),

  decodeVietQr: (qrString: string) =>
    request<{ bankBin: string; accountNumber: string; amount: number; purpose: string; qrCodeString: string }>(
      `/payments/vietqr/decode?qrString=${encodeURIComponent(qrString)}`,
      { method: 'POST' }
    ),

  estimateFees: (sourceWalletId: string, amount: number, type = 'TRANSFER', currency = 'VND') =>
    request<{ feeAmount: number; totalAmount: number; feeDescription: string }>(
      `/wallets/fees/estimate?sourceWalletId=${sourceWalletId}&amount=${amount}&type=${type}&currency=${currency}`
    ),

  // --- Transactions & Statement ---
  getTransactionHistory: (walletId: string, page = 0, size = 20, type?: string) => {
    const params = new URLSearchParams({ walletId, page: page.toString(), size: size.toString() });
    if (type) params.append('type', type);
    return request<any[]>(`/transactions?${params.toString()}`);
  },

  downloadReceipt: (transactionId: string) => {
    // This returns the full URL to the PDF so we can download it via FileSystem
    return `${API_BASE_URL}/transactions/${transactionId}/receipt.pdf`;
  },

  exportStatement: (walletId: string, format: 'csv' | 'pdf' | 'excel', fromDate?: string, toDate?: string) => {
    const params = new URLSearchParams({ walletId });
    if (fromDate) params.append('fromDate', fromDate);
    if (toDate) params.append('toDate', toDate);
    return `${API_BASE_URL}/transactions/export/${format}?${params.toString()}`;
  },

  // --- Funding Sources (Cards / Bank Accounts) ---
  getFundingSources: () =>
    request<any[]>('/funding-sources'),

  linkFundingSource: (type: string, provider: string, number: string, cardHolderName?: string, expiryDate?: string, cvv?: string) =>
    request<any>('/funding-sources/link', {
      method: 'POST',
      body: JSON.stringify({ type, provider, number, cardHolderName, expiryDate, cvv }),
    }),

  unlinkFundingSource: (id: string) =>
    request<void>(`/funding-sources/${id}`, { method: 'DELETE' }),

  // --- QR ---
  getMyQrCode: () =>
    request<{ qrData: string; fullQrPayload: string }>('/users/me/qrcode'),

  // --- Notifications ---
  getNotifications: (page = 0, size = 20, type?: string) => {
    const params = new URLSearchParams({ page: page.toString(), size: size.toString() });
    if (type) params.append('type', type);
    return request<any>(`/notifications?${params.toString()}`);
  },

  markNotificationAsRead: (id: string) =>
    request<void>(`/notifications/${id}/read`, { method: 'PATCH' }),

  markAllAsRead: (type?: string) => {
    const params = new URLSearchParams();
    if (type) params.append('type', type);
    const queryString = params.toString() ? `?${params.toString()}` : '';
    return request<void>(`/notifications/read-all${queryString}`, { method: 'PATCH' });
  },

  // --- Beneficiaries ---
  getBeneficiaries: () =>
    request<any[]>('/beneficiaries'),

  addBeneficiary: (beneficiaryWalletId: string, nickname: string, bankCode: string, accountNumber: string) =>
    request<any>('/beneficiaries', {
      method: 'POST',
      body: JSON.stringify({ beneficiaryWalletId, nickname, bankCode, accountNumber }),
    }),

  deleteBeneficiary: (id: string) =>
    request<void>(`/beneficiaries/${id}`, {
      method: 'DELETE',
    }),

  // --- Legal Limits & Terms ---
  getLimitsConfig: () =>
    request<any>('/config/limits'),

  getTerms: () =>
    request<string>('/legal/terms'),

  // --- Support FAQ ---
  getFaq: () =>
    request<any[]>('/support/faq'),

  // --- Session & Device Management ---
  getActiveSessions: () =>
    request<any[]>('/sessions'),

  revokeSession: (deviceId: string) =>
    request<void>(`/sessions/${deviceId}`, { method: 'DELETE' }),

  // --- Bill Payment ---
  lookupBill: (type: string, customerCode: string) =>
    request<any>(`/bills/lookup?type=${type}&customerCode=${customerCode}`),

  payBill: (walletId: string, billId: string, amount: number, currency = 'VND') =>
    request<any>('/bills/pay', {
      method: 'POST',
      body: JSON.stringify({ requestId: generateUUID(), walletId, billId, amount, currency }),
    }, true),

  topupPhone: (walletId: string, phoneNumber: string, amount: number, currency = 'VND') =>
    request<any>('/bills/topup', {
      method: 'POST',
      body: JSON.stringify({ requestId: generateUUID(), walletId, phoneNumber, amount, currency }),
    }, true),
};
