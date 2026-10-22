'use client';

import React, { useState } from 'react';
import Link from 'next/link';
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
    <div className="min-h-screen flex flex-col justify-between items-center p-4 sm:p-6 bg-radial from-slate-100 via-slate-50 to-slate-200 dark:from-[#080E1A] dark:via-[#0B1220] dark:to-[#050912] text-[#1F2937] dark:text-[#E5EAF2] transition-colors duration-200">
      {/* Decorative ambient background glows */}
      <div className="fixed top-1/4 -right-20 w-80 h-80 bg-[#1E3557]/10 dark:bg-[#B3945B]/10 rounded-full blur-3xl pointer-events-none"></div>
      <div className="fixed bottom-1/4 -left-20 w-80 h-80 bg-teal-500/10 dark:bg-[#1E3557]/20 rounded-full blur-3xl pointer-events-none"></div>

      {/* Empty top spacer to vertically balance */}
      <div className="w-full py-2"></div>

      {/* Main Unified Login Card */}
      <div className="w-full max-w-md relative z-10">
        <div className="bg-white/95 dark:bg-[#111C2F]/95 backdrop-blur-xl border border-slate-200/90 dark:border-slate-800 rounded-3xl p-6 sm:p-9 shadow-2xl shadow-slate-900/10 dark:shadow-black/40 transition-all duration-200">
          
          {/* Top Integrated Controls Bar (Inside the Card) */}
          <div className="flex items-center justify-between pb-6 mb-6 border-b border-slate-100 dark:border-slate-800/80">
            {/* Return to Central Marketplace */}
            <Link
              href="/"
              className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-teal-600 dark:text-slate-400 dark:hover:text-teal-400 transition group"
              title={t.backToMarketplace}
            >
              <span className="text-sm transition-transform group-hover:-translate-x-0.5">←</span>
              <span>{t.backToMarketplace}</span>
            </Link>

            {/* Language & Theme Integrated Toggles */}
            <div className="flex items-center gap-1.5 bg-slate-100 dark:bg-[#0B1220] p-1 rounded-xl border border-slate-200/70 dark:border-slate-800">
              <button
                type="button"
                onClick={toggleLang}
                className="px-2.5 py-1 text-[11px] font-bold rounded-lg bg-white dark:bg-[#1A263C] text-[#14233B] dark:text-amber-400 shadow-2xs hover:bg-slate-50 dark:hover:bg-slate-800 transition cursor-pointer"
                title="Switch Language / تغيير اللغة"
              >
                {lang === 'ar' ? 'English' : 'عربي'}
              </button>

              <button
                type="button"
                onClick={toggleTheme}
                className="p-1.5 rounded-lg text-slate-600 dark:text-slate-300 hover:bg-white dark:hover:bg-[#1A263C] hover:text-amber-500 transition cursor-pointer"
                title={theme === 'dark' ? t.themeLight : t.themeDark}
                aria-label="Toggle Theme"
              >
                {theme === 'dark' ? (
                  <svg className="w-3.5 h-3.5 text-amber-400" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
                  </svg>
                ) : (
                  <svg className="w-3.5 h-3.5 text-slate-700" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                  </svg>
                )}
              </button>
            </div>
          </div>

          {/* Brand & Monogram Header */}
          <div className="text-center mb-7">
            <div className="w-14 h-14 sm:w-16 sm:h-16 mx-auto mb-3.5 rounded-2xl bg-gradient-to-br from-[#14233B] via-[#1E3557] to-[#0A1322] flex items-center justify-center text-white font-extrabold text-xl sm:text-2xl shadow-xl shadow-[#14233B]/20 border-2 border-[#B3945B]/60 relative group">
              <span className="text-[#B3945B] tracking-wider group-hover:scale-105 transition-transform">SM</span>
              <span className="absolute -bottom-1 -right-1 w-4 h-4 rounded-full bg-emerald-500 border-2 border-white dark:border-[#111C2F]"></span>
            </div>
            
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-600 dark:text-amber-400 text-[10px] font-black mb-2">
              <span>🛡️</span>
              <span>{t.brandPlatformAdmin}</span>
            </div>

            <h1 className="text-xl sm:text-2xl font-black tracking-tight text-[#14233B] dark:text-[#E5EAF2]">
              {t.loginBrandTitle}
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-medium">
              {t.loginBrandSubtitle}
            </p>
          </div>

          {/* Error Banner */}
          {error && (
            <div className="mb-5 p-3 rounded-xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900/50 text-red-700 dark:text-red-300 text-xs flex items-center gap-2 animate-shake">
              <svg className="w-4 h-4 shrink-0 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
              <span className="font-medium">{error}</span>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                {t.loginEmailLabel}
              </label>
              <div className="relative">
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder={t.loginEmailPlaceholder}
                  className="w-full px-4 py-2.5 bg-slate-50 dark:bg-[#0B1220] border border-slate-200 dark:border-slate-800 rounded-xl text-[#1F2937] dark:text-white text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-amber-500/50 focus:border-[#1E3557] dark:focus:border-amber-500 transition"
                />
              </div>
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
                  className="w-full px-4 py-2.5 bg-slate-50 dark:bg-[#0B1220] border border-slate-200 dark:border-slate-800 rounded-xl text-[#1F2937] dark:text-white text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-amber-500/50 focus:border-[#1E3557] dark:focus:border-amber-500 transition pe-14"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 end-0 px-3.5 flex items-center text-xs font-bold text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 transition cursor-pointer"
                  tabIndex={-1}
                >
                  {showPassword ? t.loginHidePassword : t.loginShowPassword}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full mt-3 py-3 px-4 bg-gradient-to-r from-[#14233B] via-[#1E3557] to-[#14233B] hover:from-[#1E3557] hover:to-[#2A4A7A] text-white font-extrabold rounded-xl text-sm transition shadow-lg shadow-[#14233B]/25 border border-[#B3945B]/40 disabled:opacity-50 flex items-center justify-center gap-2 cursor-pointer active:scale-98"
            >
              {loading ? (
                <>
                  <svg className="animate-spin h-4 w-4 text-amber-400" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span>{t.loginSubmitting}</span>
                </>
              ) : (
                <>
                  <span>🔐</span>
                  <span>{t.loginSubmit}</span>
                </>
              )}
            </button>
          </form>

          {/* Secure Notice */}
          <div className="mt-6 pt-4 border-t border-slate-100 dark:border-slate-800/80 text-center text-[11px] text-slate-500 dark:text-slate-400 font-medium">
            {t.loginSecureNotice}
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="text-center text-[11px] text-slate-400 dark:text-slate-500 py-3 relative z-10 font-medium">
        {t.loginFooter}
      </footer>
    </div>
  );
}
