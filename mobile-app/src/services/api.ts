/**
 * API Service Client for Fintech Wallet Mobile App
 * Connects to Spring Boot Backend (Hexagonal Architecture)
 */

export const API_BASE_URL = 'http://localhost:8080/api/v1';

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

  let response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

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
        response = await fetch(`${API_BASE_URL}${endpoint}`, {
          ...options,
          headers,
        });
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
    request<{ userId: string; token: string }>('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ phoneNumber, password }),
    }),

  login: (phoneNumber: string, password: string) =>
    request<{ token: string }>('/auth/login', {
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
    request<{ id: string; ownerId: string; balanceAmount: number; currency: string }>(`/wallets/${walletId}`),

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

  initTransfer: (sourceWalletId: string, targetWalletId: string, amount: number, currency = 'VND') =>
    request<{ id: string; status: string; amount: number }>(
      '/wallets/transfer/init',
      {
        method: 'POST',
        body: JSON.stringify({ requestId: generateUUID(), sourceWalletId, targetWalletId, amount, currency }),
      },
      true
    ),

  confirmTransfer: (transactionId: string, pin: string, otp: string) =>
    request<{ id: string; status: string }>(
      '/wallets/transfer/confirm',
      {
        method: 'POST',
        body: JSON.stringify({ transactionId, pin, otp }),
      },
      true
    ),

  initTransferQr: (qrCode: string, amount?: number) =>
    request<{ id: string; status: string }>(
      '/wallets/transfer/qr/init',
      {
        method: 'POST',
        body: JSON.stringify({ requestId: generateUUID(), qrCode, amount }),
      },
      true
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
    // This endpoint returns a PDF file, so it should be handled differently (e.g., via browser download or Blob fetch)
    return fetch(`${API_BASE_URL}/transactions/${transactionId}/receipt.pdf`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
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

  addBeneficiary: (name: string, phoneNumber?: string, bankAccount?: string, bankName?: string) =>
    request<any>('/beneficiaries', {
      method: 'POST',
      body: JSON.stringify({ name, phoneNumber, bankAccount, bankName }),
    }),

  // --- Legal Limits & Terms ---
  getLimitsConfig: () =>
    request<any>('/config/limits'),

  getTerms: () =>
    request<string>('/legal/terms'),

  // --- Support FAQ ---
  getFaq: () =>
    request<any[]>('/support/faq'),

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
