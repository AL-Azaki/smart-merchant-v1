'use client';

import React from 'react';
import Link from 'next/link';
import { useMarketplace } from '@/lib/marketplace-context';

export function MarketplaceFooter() {
  const { t } = useMarketplace();

  return (
    <footer className="bg-slate-950 text-slate-300 text-sm border-t border-slate-800 mt-16 sm:mt-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 sm:py-14 lg:py-16">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-8 lg:gap-12">
          {/* Brand Column */}
          <div className="space-y-3.5 sm:col-span-2">
            <div className="flex items-center gap-2.5">
              <span className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-teal-500 to-teal-700 text-white flex items-center justify-center font-black text-xl shadow-md shadow-teal-500/20 shrink-0">
                🛍️
              </span>
              <div>
                <h3 className="font-black text-white text-base sm:text-lg">{t('footer_brand_title')}</h3>
                <span className="text-[11px] text-teal-400 font-medium">{t('footer_brand_sub')}</span>
              </div>
            </div>

            <p className="text-xs text-slate-400 leading-relaxed max-w-lg">
              {t('footer_brand_desc')}
            </p>

            <div className="pt-2 flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 text-[10px] sm:text-[11px] font-bold text-teal-300 bg-teal-950/90 border border-teal-800/80 px-2.5 sm:px-3 py-1 rounded-full">
                <span>✓</span> {t('footer_badge_verified')}
              </span>
              <span className="inline-flex items-center gap-1.5 text-[10px] sm:text-[11px] font-bold text-slate-300 bg-slate-800/90 border border-slate-700 px-2.5 sm:px-3 py-1 rounded-full">
                <span>⚡</span> {t('footer_badge_cod')}
              </span>
              <span className="inline-flex items-center gap-1.5 text-[10px] sm:text-[11px] font-bold text-slate-300 bg-slate-800/90 border border-slate-700 px-2.5 sm:px-3 py-1 rounded-full">
                <span>💬</span> {t('footer_badge_whatsapp')}
              </span>
            </div>
          </div>

          {/* Quick Links */}
          <div className="space-y-3">
            <h4 className="font-black text-white text-xs sm:text-sm">{t('footer_shoppers_title')}</h4>
            <ul className="space-y-2 text-xs text-slate-400">
              <li>
                <Link href="/#explore-products" className="hover:text-teal-400 transition">
                  {t('footer_link_products')}
                </Link>
              </li>
              <li>
                <Link href="/#merchants-section" className="hover:text-teal-400 transition">
                  {t('footer_link_merchants')}
                </Link>
              </li>
              <li>
                <Link href="/#categories-section" className="hover:text-teal-400 transition">
                  {t('footer_link_categories')}
                </Link>
              </li>
              <li>
                <Link href="/#omnisearch-box" className="hover:text-teal-400 transition">
                  {t('footer_link_search')}
                </Link>
              </li>
            </ul>
          </div>

          {/* Merchant Solutions */}
          <div className="space-y-3">
            <h4 className="font-black text-white text-xs sm:text-sm">{t('footer_merchants_title')}</h4>
            <p className="text-xs text-slate-400">
              {t('footer_merchants_desc')}
            </p>
            <div className="pt-1">
              <Link
                href="/merchants/onboarding"
                className="inline-flex items-center gap-2 px-3.5 sm:px-4 py-2 bg-slate-800 hover:bg-slate-700 text-teal-300 text-xs font-bold rounded-xl border border-slate-700 transition active:scale-95"
              >
                <span>📲</span>
                <span>{t('footer_merchants_btn')}</span>
              </Link>
            </div>
          </div>
        </div>

        {/* Bottom Rights */}
        <div className="mt-10 sm:mt-12 pt-6 border-t border-slate-800 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-slate-500">
          <p>© {new Date().getFullYear()} {t('footer_rights')}</p>
          <div className="flex items-center gap-4">
            <span>{t('footer_made_in')}</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
