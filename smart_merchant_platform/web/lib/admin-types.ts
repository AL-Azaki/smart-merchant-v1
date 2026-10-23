export interface AdminAccount {
  id: string;
  name: string;
  owner_name: string;
  email: string;
  phone?: string | null;
  status: 'Pending' | 'Active' | 'Suspended' | 'Closed';
  created_at: string;
  businesses_count?: number;
  users_count?: number;
}

export interface AdminBusiness {
  id: string;
  account_id: string;
  business_name: string;
  business_type?: string;
  primary_phone?: string | null;
  primary_email?: string | null;
  status: 'Active' | 'Inactive' | 'Suspended' | 'Closed';
  storefront_slug: string;
  created_at: string;
}

export interface PlatformUser {
  id: string;
  account_id?: string;
  username: string;
  email: string;
  full_name: string;
  phone?: string | null;
  is_active: boolean;
  created_at: string;
  account?: {
    id: string;
    name: string;
  };
  roles?: Array<{
    id: string;
    role_name: string;
  }>;
}

export interface DashboardMetrics {
  total_businesses: number;
  total_users: number;
  total_orders: number;
  total_devices: number;
  accounts?: {
    total: number;
    active: number;
    suspended: number;
    closed: number;
  };
}

import type { adminTranslations } from './admin-translations';

export interface AdminAuthContextType {
  token: string | null;
  user: PlatformUser | null;
  lang: 'ar' | 'en';
  theme: 'light' | 'dark' | 'system';
  t: typeof adminTranslations['ar'];
  pageTitle: string;
  setPageTitle: (title: string) => void;
  setLang: (lang: 'ar' | 'en') => void;
  setTheme: (theme: 'light' | 'dark' | 'system') => void;
  login: (token: string, user: PlatformUser) => void;
  logout: () => void;
}

export interface CreateAccountPayload {
  first_name: string;
  last_name: string;
  username: string;
  email: string;
  phone?: string;
  password: string;
  business_name: string;
  business_type: string;
  primary_phone?: string;
  primary_email?: string;
  country?: string;
  city?: string;
  address?: string;
  currency?: string;
}

export interface CreatedAccountResponse {
  message: string;
  data: {
    account: AdminAccount;
    business: AdminBusiness;
    branch: {
      id: string;
      branch_name: string;
      branch_code: string;
    };
    user: {
      id: string;
      full_name: string;
      username: string;
      email: string;
      phone?: string | null;
      is_active: boolean;
    };
    credentials: {
      email: string;
      password: string;
    };
  };
}

export interface SubscriptionPlan {
  id: string;
  plan_name: string;
  billing_cycle: string;
  duration_months: number;
  price: string | number;
  currency_id?: string;
  currency?: {
    id: string;
    currency_code: string;
    currency_symbol: string;
  };
}

export interface SubscriptionInstallment {
  id: string;
  subscription_id: string;
  account_id: string;
  installment_number: number;
  due_date: string;
  amount: string | number;
  paid_amount: string | number;
  status: 'Pending' | 'Paid' | 'PartiallyPaid' | 'Overdue' | 'Cancelled';
  paid_at?: string | null;
  payment_method?: string | null;
  transaction_reference?: string | null;
  notes?: string | null;
}

export interface SubscriptionPayment {
  id: string;
  subscription_id: string;
  account_id: string;
  receipt_number: string;
  payment_date: string;
  amount: string | number;
  payment_method?: string | null;
  reference_number?: string | null;
  status: string;
  notes?: string | null;
}

export interface AdminSubscription {
  id: string;
  account_id: string;
  plan_id?: string | null;
  start_date: string;
  end_date: string;
  total_amount: string | number;
  amount_paid: string | number;
  installments_count: number;
  installment_frequency: string;
  status: 'Active' | 'Expired' | 'Suspended' | 'Cancelled';
  offline_lease_valid_until?: string | null;
  max_offline_days: number;
  grace_period_days: number;
  notes?: string | null;
  created_at: string;
  account?: AdminAccount;
  plan?: SubscriptionPlan;
  installments?: SubscriptionInstallment[];
  payments?: SubscriptionPayment[];
}

export interface SubscriptionMetrics {
  total_subscriptions: number;
  active_subscriptions: number;
  expired_subscriptions: number;
  total_revenue: number;
  total_contracted: number;
  pending_installments_count: number;
  overdue_installments_count: number;
}

export interface ApproveAccountPayload {
  plan_id?: string;
  total_amount?: number;
  down_payment?: number;
  installment_frequency?: string;
  installments_count?: number;
  start_date?: string;
  max_offline_days?: number;
  grace_period_days?: number;
  notes?: string;
  custom_installments?: Array<{
    installment_number: number;
    due_date: string;
    amount: number;
    paid_amount?: number;
    status?: string;
    notes?: string;
  }>;
}

export interface AccountStatementResponse {
  account: AdminAccount;
  active_subscription?: AdminSubscription | null;
  all_subscriptions: AdminSubscription[];
  installments: SubscriptionInstallment[];
}


