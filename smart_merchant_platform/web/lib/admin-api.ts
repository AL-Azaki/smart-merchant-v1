import { API_BASE_URL } from './config';
import type { 
  AdminAccount, 
  AdminBusiness, 
  CreateAccountPayload, 
  CreatedAccountResponse, 
  DashboardMetrics, 
  PlatformUser,
  SubscriptionPlan,
  AdminSubscription,
  SubscriptionMetrics,
  ApproveAccountPayload,
  AccountStatementResponse
} from './admin-types';

const ADMIN_API_BASE = `${API_BASE_URL}/api/admin/v1`;
const AUTH_API_BASE = `${API_BASE_URL}/api/auth`;

const TOKEN_KEY = 'smart_merchant_admin_token';
const USER_KEY = 'smart_merchant_admin_user';

export function getStoredToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setStoredToken(token: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(TOKEN_KEY, token);
}

export function removeStoredToken(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

export function getStoredUser(): PlatformUser | null {
  if (typeof window === 'undefined') return null;
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function setStoredUser(user: PlatformUser): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

async function adminFetch<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getStoredToken();
  const headers: Record<string, string> = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  let res: Response;
  try {
    res = await fetch(endpoint, {
      ...options,
      headers,
    });
  } catch {
    throw new Error('فشل الاتصال بالخادم. يرجى التحقق من تشغيل خدمة الـ Backend.');
  }

  if (res.status === 401) {
    removeStoredToken();
    if (typeof window !== 'undefined' && !window.location.pathname.includes('/admin/login')) {
      window.location.href = '/admin/login';
    }
    throw new Error('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.');
  }

  const data = await res.json().catch(() => ({}));

  if (!res.ok) {
    const errorMsg = data.message || data.error || `خطأ في الطلب: ${res.status}`;
    throw new Error(errorMsg);
  }

  return data as T;
}

export const adminApi = {
  async login(email: string, password: string): Promise<{ token: string; user: PlatformUser }> {
    const res = await fetch(`${AUTH_API_BASE}/login`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });

    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new Error(data.message || 'بيانات الدخول غير صحيحة');
    }

    setStoredToken(data.token);
    setStoredUser(data.user);
    return data;
  },

  async logout(): Promise<void> {
    try {
      await adminFetch(`${AUTH_API_BASE}/logout`, { method: 'POST' });
    } catch {
      // ignore
    } finally {
      removeStoredToken();
    }
  },

  async getMe(): Promise<PlatformUser> {
    const res = await adminFetch<{ data: PlatformUser }>(`${ADMIN_API_BASE}/me`);
    setStoredUser(res.data);
    return res.data;
  },

  async getDashboard(): Promise<DashboardMetrics> {
    const res = await adminFetch<{ data: DashboardMetrics }>(`${ADMIN_API_BASE}/dashboard`);
    return res.data;
  },

  async getAccounts(params?: { search?: string; status?: string; page?: number }): Promise<{
    data: AdminAccount[];
    current_page: number;
    last_page: number;
    total: number;
  }> {
    const query = new URLSearchParams();
    if (params?.search) query.set('search', params.search);
    if (params?.status && params.status !== 'All') query.set('status', params.status);
    if (params?.page) query.set('page', String(params.page));

    return adminFetch(`${ADMIN_API_BASE}/accounts?${query.toString()}`);
  },

  async createAccount(payload: CreateAccountPayload): Promise<CreatedAccountResponse> {
    return adminFetch<CreatedAccountResponse>(`${ADMIN_API_BASE}/accounts`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async approveAccount(id: string, payload?: ApproveAccountPayload): Promise<AdminAccount> {
    const res = await adminFetch<{ data: AdminAccount; message: string }>(`${ADMIN_API_BASE}/accounts/${id}/approve`, {
      method: 'POST',
      body: payload ? JSON.stringify(payload) : undefined,
    });
    return res.data;
  },

  async suspendAccount(id: string, reason?: string): Promise<AdminAccount> {
    const res = await adminFetch<{ data: AdminAccount; message: string }>(`${ADMIN_API_BASE}/accounts/${id}/suspend`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
    return res.data;
  },

  async reactivateAccount(id: string): Promise<AdminAccount> {
    const res = await adminFetch<{ data: AdminAccount; message: string }>(`${ADMIN_API_BASE}/accounts/${id}/reactivate`, {
      method: 'POST',
    });
    return res.data;
  },

  async getBusinesses(params?: { page?: number }): Promise<{
    data: AdminBusiness[];
    current_page: number;
    last_page: number;
    total: number;
  }> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', String(params.page));
    return adminFetch(`${ADMIN_API_BASE}/businesses?${query.toString()}`);
  },

  async updateBusinessStatus(id: string, status: 'Active' | 'Suspended' | 'Closed'): Promise<AdminBusiness> {
    const res = await adminFetch<{ data: AdminBusiness }>(`${ADMIN_API_BASE}/businesses/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ status }),
    });
    return res.data;
  },

  async getUsers(params?: { search?: string; page?: number }): Promise<{
    data: PlatformUser[];
    current_page: number;
    last_page: number;
    total: number;
  }> {
    const query = new URLSearchParams();
    if (params?.search) query.set('search', params.search);
    if (params?.page) query.set('page', String(params.page));
    return adminFetch(`${ADMIN_API_BASE}/users?${query.toString()}`);
  },

  async toggleUserActive(id: string, isActive: boolean): Promise<PlatformUser> {
    const res = await adminFetch<{ data: PlatformUser }>(`${ADMIN_API_BASE}/users/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ is_active: isActive }),
    });
    return res.data;
  },

  async getPlans(): Promise<SubscriptionPlan[]> {
    const res = await adminFetch<{ data: SubscriptionPlan[] }>(`${ADMIN_API_BASE}/plans`);
    return res.data;
  },

  async getAccountStatement(accountId: string): Promise<AccountStatementResponse> {
    return adminFetch<AccountStatementResponse>(`${ADMIN_API_BASE}/accounts/${accountId}/statement`);
  },

  async getSubscriptions(params?: { search?: string; status?: string; page?: number }): Promise<{
    metrics: SubscriptionMetrics;
    subscriptions: {
      data: AdminSubscription[];
      current_page: number;
      last_page: number;
      total: number;
    };
  }> {
    const query = new URLSearchParams();
    if (params?.search) query.set('search', params.search);
    if (params?.status && params.status !== 'All') query.set('status', params.status);
    if (params?.page) query.set('page', String(params.page));

    return adminFetch(`${ADMIN_API_BASE}/subscriptions?${query.toString()}`);
  },

  async getSubscriptionDetail(id: string): Promise<{ subscription: AdminSubscription; lease: any }> {
    return adminFetch<{ subscription: AdminSubscription; lease: any }>(`${ADMIN_API_BASE}/subscriptions/${id}`);
  },

  async paySubscriptionInstallment(
    subscriptionId: string,
    installmentId: string,
    payload: {
      amount?: number;
      payment_method?: string;
      reference_number?: string;
      notes?: string;
    }
  ): Promise<{ message: string; installment: any; subscription: AdminSubscription }> {
    return adminFetch(`${ADMIN_API_BASE}/subscriptions/${subscriptionId}/installments/${installmentId}/pay`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
};
