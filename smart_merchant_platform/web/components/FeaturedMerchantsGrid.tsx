'use client';

import React from 'react';
import Link from 'next/link';
import type { MarketplaceMerchant } from '@/lib/types';
import { useMarketplace } from '@/lib/marketplace-context';

interface FeaturedMerchantsGridProps {
  merchants: MarketplaceMerchant[];
}

export function FeaturedMerchantsGrid({ merchants }: FeaturedMerchantsGridProps) {
  const { t } = useMarketplace();

  if (!merchants || merchants.length === 0) return null;

  return (
    <section id="merchants-section" className="py-10 sm:py-14 lg:py-16 bg-slate-50 dark:bg-slate-950 border-b border-slate-200/80 dark:border-slate-800 transition-colors">
      <div className="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8">
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-3 mb-6 sm:mb-8">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="text-base sm:text-lg">🏪</span>
              <span className="text-[11px] sm:text-xs font-bold text-teal-600 dark:text-teal-400 bg-teal-50 dark:bg-teal-950/60 px-2.5 py-0.5 rounded-full border border-teal-200 dark:border-teal-800">
                {t('merchants_badge')}
              </span>
            </div>
            <h2 className="text-lg sm:text-2xl font-black text-slate-900 dark:text-white tracking-tight">
              {t('merchants_title')}
            </h2>
            <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
              {t('merchants_sub')}
            </p>
          </div>

          <span className="text-[11px] sm:text-xs font-bold text-slate-500 dark:text-slate-400">
            {merchants.length} {t('merchants_active_count')}
          </span>
        </div>

        {/* Merchant Cards Grid - Responsive for phones and desktops */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3 sm:gap-6">
          {merchants.map((m) => {
            const initial = m.name.charAt(0);
            return (
              <div
                key={m.id}
                className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-800 hover:border-teal-400 dark:hover:border-teal-500 p-4 sm:p-5 shadow-xs hover:shadow-md transition-all group flex flex-col justify-between"
              >
                <div>
                  {/* Header: Logo + Title */}
                  <div className="flex items-start gap-3 sm:gap-3.5 mb-3 sm:mb-3.5">
                    <div className="w-11 h-11 sm:w-12 sm:h-12 rounded-xl bg-gradient-to-tr from-slate-100 to-slate-200 dark:from-slate-800 dark:to-slate-700 text-slate-800 dark:text-slate-200 flex items-center justify-center font-black text-base sm:text-lg border border-slate-200 dark:border-slate-700 shrink-0 overflow-hidden relative">
                      {m.logo ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={m.logo} alt={m.name} className="w-full h-full object-cover" />
                      ) : (
                        <span>{initial}</span>
                      )}
                    </div>

                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-1.5">
                        <h3 className="font-black text-slate-900 dark:text-white text-xs sm:text-sm truncate group-hover:text-teal-600 dark:group-hover:text-teal-400 transition">
                          {m.name}
                        </h3>
                        <span className="text-teal-500 text-xs shrink-0" title="متجر موثق">
                          ✓
                        </span>
                      </div>
                      <span className="text-[10px] sm:text-[11px] text-slate-400 dark:text-slate-500 font-medium block truncate">
                        {m.business_type || t('merchants_default_type')}
                      </span>
                    </div>
                  </div>

                  {/* Address */}
                  {m.address && (
                    <p className="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400 mb-3 line-clamp-1 flex items-center gap-1">
                      <span>📍</span>
                      <span>{m.address}</span>
                    </p>
                  )}

                  {/* Badge Info */}
                  <div className="flex items-center gap-2 mb-3 sm:mb-4">
                    <span className="text-[10px] sm:text-[11px] font-bold text-teal-700 dark:text-teal-300 bg-teal-50 dark:bg-teal-950/60 px-2 py-0.5 rounded-md border border-teal-200 dark:border-teal-800">
                      {m.active_products_count} {t('merchants_products_available')}
                    </span>
                    <span className="text-[10px] sm:text-[11px] font-semibold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-md border border-emerald-200/50 dark:border-emerald-800/50">
                      {t('merchants_open_orders')}
                    </span>
                  </div>
                </div>

                {/* Visit Button */}
                <Link
                  href={`/store/${m.slug}`}
                  className="w-full py-2 sm:py-2.5 px-3 bg-slate-900 hover:bg-teal-600 dark:bg-teal-600 dark:hover:bg-teal-500 text-white text-xs font-black rounded-xl text-center transition flex items-center justify-center gap-1.5 group-hover:shadow-xs active:scale-95"
                >
                  <span>{t('merchants_view_store')}</span>
                  <span className="text-sm">←</span>
                </Link>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
