'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { adminApi } from '@/lib/admin-api';
import { useAdminAuth } from '@/lib/admin-context';

export default function AdminLoginPage() {
  const router = useRouter();
  const { login, lang, setLang, theme, setTheme, t } = useAdminAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!email.trim() || !password.trim()) {
      setError(t.loginErrorMissing);
      return;
    }

    setLoading(true);
    try {
      const res = await adminApi.login(email.trim(), password);
      login(res.token, res.user);
      router.push('/admin/dashboard');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : t.loginErrorGeneral;
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const toggleLang = () => {
    setLang(lang === 'ar' ? 'en' : 'ar');
  };

  const toggleTheme = () => {
    setTheme(theme === 'dark' ? 'light' : 'dark');
  };

  return (
    <div className="min-h-screen flex flex-col justify-between p-4 sm:p-6 bg-[#F7F8FA] dark:bg-[#0B1220] text-[#1F2937] dark:text-[#E5EAF2] transition-colors duration-200">
      {/* Top utility bar on login page for language & theme */}
      <div className="flex items-center justify-between max-w-5xl w-full mx-auto py-2">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-[#14233B] dark:bg-[#1E3557] flex items-center justify-center text-white font-extrabold text-xs border border-[#B3945B]/30 shadow-xs">
            SM
          </div>
          <span className="font-bold text-sm tracking-tight text-[#14233B] dark:text-[#E5EAF2]">
            {t.brandName}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={toggleLang}
            className="px-3 py-1.5 text-xs font-semibold rounded-lg border border-[#E2E8F0] dark:border-[#1E293B] bg-white dark:bg-[#111C2F] text-[#14233B] dark:text-[#E5EAF2] hover:bg-slate-50 dark:hover:bg-slate-800 transition shadow-2xs"
          >
            {t.switchLang}
          </button>
          <button
            onClick={toggleTheme}
            className="p-1.5 rounded-lg border border-[#E2E8F0] dark:border-[#1E293B] bg-white dark:bg-[#111C2F] text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition shadow-2xs"
            title={theme === 'dark' ? t.themeLight : t.themeDark}
            aria-label={theme === 'dark' ? t.themeLight : t.themeDark}
          >
            {theme === 'dark' ? (
              <svg className="w-4 h-4 text-[#B3945B]" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
              </svg>
            ) : (
              <svg className="w-4 h-4 text-[#14233B]" fill="currentColor" viewBox="0 0 20 20">
                <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
              </svg>
            )}
          </button>
        </div>
      </div>

      {/* Login Card */}
      <div className="w-full max-w-md mx-auto my-auto">
        <div className="bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-3xl p-8 sm:p-10 shadow-xl transition-colors duration-200">
          {/* Header */}
          <div className="text-center mb-8">
            <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-[#14233B] dark:bg-[#0F1C30] flex items-center justify-center text-white font-extrabold text-2xl shadow-lg border-2 border-[#B3945B]">
              <span className="text-[#B3945B]">SM</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-[#14233B] dark:text-[#E5EAF2]">
              {t.loginBrandTitle}
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-2 font-medium">
              {t.loginBrandSubtitle}
            </p>
          </div>

          {error && (
            <div className="mb-6 p-3.5 rounded-xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900/50 text-red-700 dark:text-red-300 text-xs flex items-center gap-2">
              <svg className="w-4 h-4 shrink-0 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                {t.loginEmailLabel}
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder={t.loginEmailPlaceholder}
                className="w-full px-4 py-2.5 bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-white text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B] transition"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                {t.loginPasswordLabel}
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder={t.loginPasswordPlaceholder}
                  className="w-full px-4 py-2.5 bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-white text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B] transition"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 end-0 px-3 flex items-center text-xs font-medium text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
                  tabIndex={-1}
                >
                  {showPassword ? t.loginHidePassword : t.loginShowPassword}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full mt-2 py-3 px-4 bg-[#14233B] hover:bg-[#1E3557] active:bg-[#0F1C30] text-white font-bold rounded-xl text-sm transition shadow-md shadow-[#14233B]/20 border border-[#B3945B]/40 disabled:opacity-50 flex items-center justify-center gap-2 cursor-pointer"
            >
              {loading ? (
                <>
                  <svg className="animate-spin h-4 w-4 text-[#B3945B]" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span>{t.loginSubmitting}</span>
                </>
              ) : (
                <span>{t.loginSubmit}</span>
              )}
            </button>
          </form>

          <div
            className="mt-6 text-center text-[11px] text-slate-500 dark:text-slate-400"
            dangerouslySetInnerHTML={{ __html: t.loginSecureNotice }}
          />
        </div>
      </div>

      {/* Footer */}
      <footer className="text-center text-[11px] text-slate-400 py-3">
        {t.loginFooter}
      </footer>
    </div>
  );
}
