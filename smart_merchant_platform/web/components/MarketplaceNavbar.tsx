'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useMarketplace } from '@/lib/marketplace-context';

export function MarketplaceNavbar() {
  const { lang, theme, isAr, toggleLang, toggleTheme, t } = useMarketplace();
  const pathname = usePathname();
  const isOnboarding = pathname === '/merchants/onboarding';

  const handleScrollTo = (e: React.MouseEvent<HTMLAnchorElement>, targetId: string) => {
    if (pathname === '/') {
      e.preventDefault();
      const elem = document.getElementById(targetId);
      if (elem) {
        elem.scrollIntoView({ behavior: 'smooth', block: 'start' });
        window.history.pushState(null, '', `#${targetId}`);
      }
    }
  };

  return (
    <header className="sticky top-0 z-40 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md border-b border-slate-200/80 dark:border-slate-800 shadow-[0_1px_8px_rgba(0,0,0,0.03)] transition-colors">
      {/* Top Value Strip (Desktop / Tablet) */}
      <div className="bg-slate-950 text-slate-300 text-xs py-1.5 px-4 hidden md:block border-b border-slate-800">
        <div className="max-w-7xl mx-auto flex items-center justify-between font-medium">
          <div className="flex items-center gap-2 text-teal-400">
            <span className="w-2 h-2 rounded-full bg-teal-400 animate-pulse"></span>
            <span className="font-bold">{t('nav_brand')}:</span>
            <span className="text-slate-300">{t('nav_top_strip')}</span>
          </div>

          <div className="flex items-center gap-4 text-slate-300 text-xs">
            {isOnboarding ? (
              <Link
                href="/"
                className="text-teal-400 hover:text-teal-300 transition font-bold flex items-center gap-1"
              >
                <span>←</span>
                <span>{t('nav_back_to_market_full')}</span>
              </Link>
            ) : (
              <>
                <span className="text-slate-400">{t('nav_are_you_merchant')}</span>
                <Link
                  href="/merchants/onboarding"
                  className="text-teal-400 hover:text-teal-300 transition font-bold"
                >
                  {t('nav_open_store_full')}
                </Link>
              </>
            )}
            <span className="text-slate-700">|</span>
            <div className="flex items-center gap-1 text-slate-400">
              <span>🛡️ {t('nav_verified_merchants')}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Main Bar - Responsive across ALL screens (320px -> 4K) */}
      <div className="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 h-14 sm:h-16 flex items-center justify-between gap-2 sm:gap-4">
        {/* Brand */}
        <Link href="/" className="flex items-center gap-2 sm:gap-3 hover:opacity-95 transition shrink-0 group">
          <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-xl sm:rounded-2xl bg-gradient-to-tr from-teal-600 via-teal-700 to-slate-900 text-white flex items-center justify-center font-black text-base sm:text-lg shadow-md shadow-teal-700/20 group-hover:scale-105 transition-transform shrink-0">
            🛒
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-1.5">
              <span className="font-black text-slate-900 dark:text-white text-sm sm:text-base tracking-tight group-hover:text-teal-600 transition-colors">
                {t('nav_brand')}
              </span>
              <span className="hidden xs:inline-block text-[9px] sm:text-[10px] bg-teal-50 dark:bg-teal-950/80 text-teal-700 dark:text-teal-300 font-extrabold px-1.5 sm:px-2 py-0.5 rounded-full border border-teal-200 dark:border-teal-800">
                {t('nav_badge')}
              </span>
            </div>
            <span className="text-[10px] text-slate-500 dark:text-slate-400 font-medium hidden lg:block">
              {t('nav_tagline')}
            </span>
          </div>
        </Link>

        {/* Quick Actions & Navigation */}
        <div className="flex items-center gap-1 sm:gap-2">
          {/* Home Link on large screens */}
          <Link
            href="/"
            className={`hidden lg:inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-bold rounded-lg transition ${
              pathname === '/' && !isOnboarding
                ? 'text-teal-600 dark:text-teal-400 bg-teal-50 dark:bg-teal-950/60'
                : 'text-slate-700 dark:text-slate-300 hover:text-teal-600 dark:hover:text-teal-400 hover:bg-slate-50 dark:hover:bg-slate-800'
            }`}
          >
            <span>🏠</span>
            <span>{t('nav_home')}</span>
          </Link>

          {/* Section links on large screens */}
          <Link
            href="/#explore-products"
            onClick={(e) => handleScrollTo(e, 'explore-products')}
            className="hidden lg:inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-bold text-slate-700 dark:text-slate-300 hover:text-teal-600 dark:hover:text-teal-400 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg transition"
          >
            <span>🏷️</span>
            <span>{t('nav_explore_products')}</span>
          </Link>

          <Link
            href="/#merchants-section"
            onClick={(e) => handleScrollTo(e, 'merchants-section')}
            className="hidden lg:inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-bold text-slate-700 dark:text-slate-300 hover:text-teal-600 dark:hover:text-teal-400 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg transition"
          >
            <span>🏪</span>
            <span>{t('nav_merchants_directory')}</span>
          </Link>

          {/* Language Toggle */}
          <button
            onClick={toggleLang}
            className="px-2 py-1 text-[11px] sm:text-xs font-bold rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-700 transition"
            title="Switch Language / تغيير اللغة"
          >
            {isAr ? 'EN' : 'عربي'}
          </button>

          {/* Theme Toggle */}
          <button
            onClick={toggleTheme}
            className="p-1.5 sm:p-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-700 transition text-xs sm:text-sm"
            title={theme === 'dark' ? 'الوضع النهاري / Light Mode' : 'الوضع الليلي / Dark Mode'}
            aria-label="Toggle Theme"
          >
            {theme === 'dark' ? '☀️' : '🌙'}
          </button>

          {/* Dynamic Smart Navigation Button */}
          {isOnboarding ? (
            <Link
              href="/"
              className="inline-flex items-center gap-1 sm:gap-1.5 px-2.5 sm:px-3.5 py-1.5 sm:py-2 bg-gradient-to-r from-teal-600 to-teal-700 hover:from-teal-700 hover:to-teal-800 text-white text-[11px] sm:text-xs font-bold rounded-lg sm:rounded-xl shadow-xs transition active:scale-95 shrink-0"
            >
              <span className="text-xs">🛒</span>
              <span className="sm:hidden">{t('nav_back_to_market')}</span>
              <span className="hidden sm:inline">{t('nav_back_to_market_full')}</span>
            </Link>
          ) : (
            <Link
              href="/merchants/onboarding"
              className="inline-flex items-center gap-1 sm:gap-1.5 px-2.5 sm:px-3.5 py-1.5 sm:py-2 bg-gradient-to-r from-teal-600 to-teal-700 hover:from-teal-700 hover:to-teal-800 text-white text-[11px] sm:text-xs font-bold rounded-lg sm:rounded-xl shadow-xs transition active:scale-95 shrink-0"
            >
              <span className="text-xs">🏪</span>
              <span className="sm:hidden">{t('nav_open_store')}</span>
              <span className="hidden sm:inline">{t('nav_open_store_full')}</span>
            </Link>
          )}

          {/* Discreet Admin Lock Link (World Standard) */}
          <Link
            href="/admin/login"
            className="w-7 h-7 sm:w-8 sm:h-8 rounded-lg border border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:hover:border-slate-600 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 bg-slate-50 dark:bg-slate-800 flex items-center justify-center text-xs transition shrink-0"
            title={t('nav_admin_portal')}
            aria-label="Admin Access"
          >
            🔐
          </Link>
        </div>
      </div>

      {/* Mobile Quick-Navigation Row (Sticky under main header on screens < lg) */}
      <nav className="lg:hidden flex items-center justify-around gap-1 px-2 py-1.5 bg-slate-100/90 dark:bg-slate-800/90 border-t border-slate-200/60 dark:border-slate-800/60 text-[11px] font-bold">
        <Link
          href="/"
          className={`px-2.5 py-1 rounded-md transition flex items-center gap-1 ${
            pathname === '/'
              ? 'bg-white dark:bg-slate-700 text-teal-600 dark:text-teal-400 shadow-xs'
              : 'text-slate-600 dark:text-slate-300 hover:text-teal-600'
          }`}
        >
          <span>🏠</span>
          <span>{t('nav_home')}</span>
        </Link>

        <Link
          href="/#explore-products"
          onClick={(e) => handleScrollTo(e, 'explore-products')}
          className="px-2.5 py-1 rounded-md text-slate-600 dark:text-slate-300 hover:text-teal-600 dark:hover:text-teal-400 transition flex items-center gap-1"
        >
          <span>🏷️</span>
          <span>{t('nav_explore_products')}</span>
        </Link>

        <Link
          href="/#merchants-section"
          onClick={(e) => handleScrollTo(e, 'merchants-section')}
          className="px-2.5 py-1 rounded-md text-slate-600 dark:text-slate-300 hover:text-teal-600 dark:hover:text-teal-400 transition flex items-center gap-1"
        >
          <span>🏪</span>
          <span>{t('nav_merchants_directory')}</span>
        </Link>

        {isOnboarding ? (
          <Link
            href="/"
            className="px-2.5 py-1 rounded-md bg-teal-600 hover:bg-teal-700 text-white font-extrabold transition flex items-center gap-1 shadow-xs"
          >
            <span>🛒</span>
            <span>{t('nav_back_to_market')}</span>
          </Link>
        ) : (
          <Link
            href="/merchants/onboarding"
            className="px-2.5 py-1 rounded-md bg-teal-50 dark:bg-teal-950/80 text-teal-700 dark:text-teal-300 border border-teal-200 dark:border-teal-800 font-extrabold transition flex items-center gap-1"
          >
            <span>🚀</span>
            <span>{t('nav_open_store')}</span>
          </Link>
        )}
      </nav>
    </header>
  );
}
