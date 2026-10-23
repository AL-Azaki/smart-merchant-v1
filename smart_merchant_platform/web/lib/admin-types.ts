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


