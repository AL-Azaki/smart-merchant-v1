'use client';

import React from 'react';
import Link from 'next/link';
import { useMarketplace } from '@/lib/marketplace-context';

export function MerchantOnboardingBanner() {
  const { t, isAr } = useMarketplace();

  return (
    <section className="py-10 sm:py-16 lg:py-20 bg-gradient-to-tr from-slate-950 via-slate-900 to-teal-950 text-white relative overflow-hidden">
      {/* Background Gradients */}
      <div className="absolute top-0 right-0 w-80 h-80 bg-teal-500/10 rounded-full blur-3xl pointer-events-none"></div>
      <div className="absolute bottom-0 left-0 w-80 h-80 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none"></div>

      <div className="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 relative z-10">
        <div className="bg-gradient-to-r from-teal-900/40 to-slate-800/40 border border-teal-500/30 rounded-3xl p-5 sm:p-10 lg:p-16 backdrop-blur-md shadow-2xl flex flex-col lg:flex-row items-center justify-between gap-6 sm:gap-8">
          {/* Content */}
          <div className="space-y-3 sm:space-y-4 max-w-2xl text-center lg:text-right">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-teal-500/20 text-teal-300 text-[10px] sm:text-xs font-black border border-teal-500/30">
              <span>🚀</span>
              <span>{t('banner_badge')}</span>
            </span>

            <h2 className="text-xl sm:text-3xl lg:text-4xl font-black tracking-tight leading-tight">
              {t('banner_title')} <br />
              <span className="text-teal-400">{t('banner_title_highlight')}</span>
            </h2>

            <p className="text-slate-300 text-xs sm:text-sm leading-relaxed">
              {t('banner_desc')}
            </p>

            <div className="pt-2 flex flex-wrap items-center justify-center lg:justify-start gap-3 sm:gap-4 text-xs text-slate-300">
              <div className="flex items-center gap-1.5 font-bold">
                <span className="text-teal-400">✓</span> {t('banner_feat_slug')}
              </div>
              <div className="flex items-center gap-1.5 font-bold">
                <span className="text-teal-400">✓</span> {t('banner_feat_sync')}
              </div>
              <div className="flex items-center gap-1.5 font-bold">
                <span className="text-teal-400">✓</span> {t('banner_feat_whatsapp')}
              </div>
            </div>
          </div>

          {/* Action Card - Stacks neatly on phones with full-width touch areas */}
          <div className="shrink-0 flex flex-col sm:flex-row lg:flex-col gap-2.5 sm:gap-3 w-full sm:w-auto">
            <Link
              href="/merchants/onboarding"
              className="px-6 sm:px-8 py-3 sm:py-3.5 bg-gradient-to-r from-teal-500 to-teal-600 hover:from-teal-600 hover:to-teal-700 text-slate-950 font-black text-xs sm:text-sm rounded-xl sm:rounded-2xl shadow-xl shadow-teal-500/20 text-center transition active:scale-95 flex items-center justify-center gap-2"
            >
              <span>{t('banner_cta_open')}</span>
              <span>←</span>
            </Link>

            <a
              href={isAr ? "https://wa.me/?text=اريد+الانضمام+كمتجر+في+منصة+تاجركم" : "https://wa.me/?text=Hello,+I+want+to+join+as+a+merchant+on+Tajer"}
              target="_blank"
              rel="noopener noreferrer"
              className="px-6 sm:px-8 py-2.5 sm:py-3 bg-slate-800/80 hover:bg-slate-800 text-white font-bold text-xs rounded-xl sm:rounded-2xl border border-slate-700 text-center transition flex items-center justify-center gap-2"
            >
              <span>💬</span>
              <span>{t('banner_cta_support')}</span>
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
