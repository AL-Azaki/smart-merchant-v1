'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import type { PlatformUser, AdminAuthContextType } from './admin-types';
import { getStoredToken, getStoredUser, removeStoredToken, setStoredToken, setStoredUser } from './admin-api';
import { adminTranslations } from './admin-translations';

const AdminAuthContext = createContext<AdminAuthContextType | null>(null);

export function AdminAuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setTokenState] = useState<string | null>(() => getStoredToken());
  const [user, setUserState] = useState<PlatformUser | null>(() => getStoredUser());
  const [lang, setLangState] = useState<'ar' | 'en'>(() => {
    if (typeof window !== 'undefined') {
      return (localStorage.getItem('smart_merchant_admin_lang') as 'ar' | 'en') || 'ar';
    }
    return 'ar';
  });
  const [theme, setThemeState] = useState<'light' | 'dark' | 'system'>(() => {
    if (typeof window !== 'undefined') {
      return (localStorage.getItem('smart_merchant_admin_theme') as 'light' | 'dark' | 'system') || 'light';
    }
    return 'light';
  });
  const [pageTitle, setPageTitle] = useState<string>('');

  // Synchronize document attributes and CSS classes with lang and theme
  useEffect(() => {
    // 1. Language & Direction
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';

    // 2. Theme (Light, Dark, System)
    const applyThemeClass = (isDark: boolean) => {
      if (isDark) {
        document.documentElement.classList.add('dark');
        document.documentElement.style.colorScheme = 'dark';
      } else {
        document.documentElement.classList.remove('dark');
        document.documentElement.style.colorScheme = 'light';
      }
    };

    if (theme === 'dark') {
      applyThemeClass(true);
    } else if (theme === 'light') {
      applyThemeClass(false);
    } else if (theme === 'system') {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      applyThemeClass(mediaQuery.matches);

      const handler = (e: MediaQueryListEvent) => applyThemeClass(e.matches);
      mediaQuery.addEventListener('change', handler);
      return () => mediaQuery.removeEventListener('change', handler);
    }
  }, [lang, theme]);

  const setLang = (newLang: 'ar' | 'en') => {
    setLangState(newLang);
    if (typeof window !== 'undefined') {
      localStorage.setItem('smart_merchant_admin_lang', newLang);
    }
  };

  const setTheme = (newTheme: 'light' | 'dark' | 'system') => {
    setThemeState(newTheme);
    if (typeof window !== 'undefined') {
      localStorage.setItem('smart_merchant_admin_theme', newTheme);
    }
  };

  const login = (newToken: string, newUser: PlatformUser) => {
    setTokenState(newToken);
    setUserState(newUser);
    setStoredToken(newToken);
    setStoredUser(newUser);
  };

  const logout = () => {
    setTokenState(null);
    setUserState(null);
    removeStoredToken();
    if (typeof window !== 'undefined') {
      window.location.href = '/admin/login';
    }
  };

  const t = adminTranslations[lang] || adminTranslations.ar;

  return (
    <AdminAuthContext.Provider
      value={{
        token,
        user,
        lang,
        theme,
        t,
        pageTitle,
        setPageTitle,
        setLang,
        setTheme,
        login,
        logout,
      }}
    >
      {children}
    </AdminAuthContext.Provider>
  );
}

export function useAdminAuth() {
  const context = useContext(AdminAuthContext);
  if (!context) {
    throw new Error('useAdminAuth must be used within an AdminAuthProvider');
  }
  return context;
}
