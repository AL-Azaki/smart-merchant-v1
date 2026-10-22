'use client';

import React from 'react';
import Link from 'next/link';
import type { MarketplaceProductItem } from '@/lib/types';
import { formatCurrency } from '@/lib/utils';
import { useMarketplace } from '@/lib/marketplace-context';

interface CrossStoreProductGridProps {
  products: MarketplaceProductItem[];
  searchTerm: string;
}

export function CrossStoreProductGrid({ products, searchTerm }: CrossStoreProductGridProps) {
  const { t } = useMarketplace();

  return (
    <section id="explore-products" className="py-10 sm:py-14 lg:py-16 bg-white dark:bg-slate-900 transition-colors">
      <div className="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8">
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-3 mb-6 sm:mb-8">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="text-base sm:text-lg">🏷️</span>
              <span className="text-[11px] sm:text-xs font-bold text-indigo-600 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-950/60 px-2.5 py-0.5 rounded-full border border-indigo-200 dark:border-indigo-800">
                {t('products_badge')}
              </span>
            </div>
            <h2 className="text-lg sm:text-2xl font-black text-slate-900 dark:text-white tracking-tight">
              {searchTerm ? `${t('products_title_search')} "${searchTerm}"` : t('products_title_default')}
            </h2>
            <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
              {t('products_sub')}
            </p>
          </div>

          <span className="text-[11px] sm:text-xs font-bold text-slate-500 dark:text-slate-400">
            {products.length} {t('products_count')}
          </span>
        </div>

        {/* Empty State */}
        {products.length === 0 ? (
          <div className="text-center py-12 sm:py-16 bg-slate-50 dark:bg-slate-800/40 rounded-3xl border border-slate-200/80 dark:border-slate-800 p-6 sm:p-8">
            <span className="text-3xl sm:text-4xl mb-3 block">🔍</span>
            <h3 className="text-sm sm:text-base font-black text-slate-800 dark:text-slate-200 mb-1">
              {t('products_empty_title')}
            </h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 max-w-sm mx-auto">
              {t('products_empty_sub')}
            </p>
          </div>
        ) : (
          /* Products Grid - 2 cols on mobile, 3 on tablet, 4 on desktop */
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-6">
            {products.map((p) => {
              const primaryUnit = p.units && p.units.length > 0 ? p.units[0] : null;
              const price = p.selling_price ?? primaryUnit?.selling_price ?? 0;
              const merchantSlug = p.merchant?.slug || '';

              return (
                <div
                  key={p.id}
                  className="bg-white dark:bg-slate-800/90 rounded-2xl border border-slate-200/80 dark:border-slate-700/80 hover:border-teal-400 dark:hover:border-teal-500 p-3 sm:p-4 shadow-xs hover:shadow-md transition-all flex flex-col justify-between group"
                >
                  <div>
                    {/* Product Image */}
                    <div className="w-full aspect-square rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-700/50 flex items-center justify-center overflow-hidden mb-2.5 sm:mb-3 relative">
                      {p.primary_image ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={p.primary_image}
                          alt={p.product_name}
                          className="w-full h-full object-cover group-hover:scale-105 transition duration-300"
                        />
                      ) : (
                        <span className="text-3xl sm:text-4xl">📦</span>
                      )}

                      {/* Store Badge Over Image */}
                      {p.merchant && (
                        <div className="absolute top-1.5 right-1.5 sm:top-2 sm:right-2 bg-slate-900/85 backdrop-blur-md text-white text-[9px] sm:text-[10px] font-bold px-1.5 sm:px-2 py-0.5 sm:py-1 rounded-md sm:rounded-lg border border-slate-700/50 flex items-center gap-1 shadow-xs">
                          <span>🏪</span>
                          <span className="truncate max-w-[70px] sm:max-w-[90px]">{p.merchant.name}</span>
                        </div>
                      )}
                    </div>

                    {/* Category */}
                    {p.category_name && (
                      <span className="text-[9px] sm:text-[10px] font-bold text-slate-400 dark:text-slate-400 uppercase tracking-wider block mb-1 truncate">
                        {p.category_name}
                      </span>
                    )}

                    {/* Product Name */}
                    <h3 className="text-xs sm:text-sm font-black text-slate-900 dark:text-slate-100 line-clamp-2 mb-2 group-hover:text-teal-600 dark:group-hover:text-teal-400 transition leading-snug">
                      {p.product_name}
                    </h3>

                    {/* Price */}
                    <div className="flex items-baseline gap-1 text-teal-600 dark:text-teal-400 font-black text-xs sm:text-base mb-2.5 sm:mb-3">
                      <span>{formatCurrency(price)}</span>
                      {primaryUnit && (
                        <span className="text-[9px] sm:text-[10px] text-slate-400 dark:text-slate-500 font-medium">
                          / {primaryUnit.unit_name}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="pt-2 border-t border-slate-100 dark:border-slate-700/60">
                    {merchantSlug ? (
                      <Link
                        href={`/store/${merchantSlug}/product/${p.id}`}
                        className="w-full py-1.5 sm:py-2 px-2.5 sm:px-3 bg-teal-50 hover:bg-teal-600 dark:bg-slate-700 dark:hover:bg-teal-600 text-teal-700 hover:text-white dark:text-teal-300 dark:hover:text-white text-[11px] sm:text-xs font-bold rounded-xl text-center transition flex items-center justify-center gap-1 active:scale-95"
                      >
                        <span>{t('products_view_buy')}</span>
                        <span className="text-xs sm:text-sm">←</span>
                      </Link>
                    ) : (
                      <span className="text-[10px] sm:text-[11px] text-slate-400 dark:text-slate-500 block text-center">
                        {t('products_unavailable')}
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </section>
  );
}
