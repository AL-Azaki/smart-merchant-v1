'use client';

import React, { useState } from 'react';
import type { MarketplaceCategory, MarketplaceMerchant } from '@/lib/types';
import { useMarketplace } from '@/lib/marketplace-context';

interface MarketplaceHeroProps {
  categories: MarketplaceCategory[];
  merchants: MarketplaceMerchant[];
  onSearch: (q: string) => void;
  onSelectCategory: (catId: string | null) => void;
  activeCategory: string | null;
  totalMerchants: number;
  totalProducts: number;
}

export function MarketplaceHero({
  categories,
  onSearch,
  onSelectCategory,
  activeCategory,
  totalMerchants,
  totalProducts,
}: MarketplaceHeroProps) {
  const { t, isAr } = useMarketplace();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCity, setSelectedCity] = useState(isAr ? 'صنعاء' : 'Sanaa');

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSearch(searchTerm.trim());
  };

  const cities = [
    { key: 'city_sanaa', valAr: 'صنعاء', valEn: 'Sanaa' },
    { key: 'city_aden', valAr: 'عدن', valEn: 'Aden' },
    { key: 'city_taiz', valAr: 'تعز', valEn: 'Taiz' },
    { key: 'city_hadramout', valAr: 'حضرموت', valEn: 'Hadramout' },
    { key: 'city_hodeidah', valAr: 'الحديدة', valEn: 'Hodeidah' },
    { key: 'city_ibb', valAr: 'إب', valEn: 'Ibb' },
  ] as const;

  return (
    <section id="omnisearch-box" className="relative overflow-hidden bg-gradient-to-b from-slate-900 via-slate-800 to-slate-900 text-white pt-10 pb-14 sm:pt-14 sm:pb-20 lg:pt-16 lg:pb-24">
      {/* Decorative Background Glows */}
      <div className="absolute top-0 right-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl pointer-events-none"></div>
      <div className="absolute bottom-0 left-1/4 w-96 h-96 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none"></div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="max-w-3xl mx-auto text-center space-y-4 sm:space-y-6">
          {/* Badge */}
          <div className="inline-flex items-center gap-1.5 sm:gap-2 px-3 sm:px-3.5 py-1.5 rounded-full bg-teal-500/10 border border-teal-500/20 text-teal-300 text-[11px] sm:text-xs font-black">
            <span>✨</span>
            <span>{t('hero_badge')}</span>
          </div>

          {/* Heading */}
          <h1 className="text-2xl sm:text-4xl lg:text-5xl xl:text-6xl font-black tracking-tight leading-tight sm:leading-tight">
            {t('hero_title_1')} <br className="hidden sm:inline" />
            <span className="bg-gradient-to-r from-teal-400 via-teal-200 to-indigo-300 bg-clip-text text-transparent">
              {t('hero_title_highlight')}
            </span>
          </h1>

          <p className="text-slate-300 text-xs sm:text-sm lg:text-base leading-relaxed max-w-2xl mx-auto px-2">
            {t('hero_subtitle')}
          </p>

          {/* Omnisearch Box + City Selector - Responsive for all mobile screens */}
          <form
            onSubmit={handleSearchSubmit}
            className="mt-6 sm:mt-8 bg-white dark:bg-slate-900/90 p-2 sm:p-2.5 rounded-2xl sm:rounded-3xl shadow-2xl shadow-black/40 border border-slate-200 dark:border-slate-700/80 flex flex-col sm:flex-row items-center gap-2 max-w-2xl mx-auto backdrop-blur-md"
          >
            {/* City Selector */}
            <div className="flex items-center gap-2 px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl sm:rounded-2xl shrink-0 w-full sm:w-auto">
              <span className="text-slate-500 dark:text-slate-400 text-xs sm:text-sm">📍</span>
              <select
                value={selectedCity}
                onChange={(e) => setSelectedCity(e.target.value)}
                className="bg-transparent text-xs font-bold text-slate-800 dark:text-slate-100 focus:outline-none cursor-pointer w-full sm:w-auto"
              >
                {cities.map((c) => (
                  <option key={c.key} value={isAr ? c.valAr : c.valEn} className="dark:bg-slate-800 text-slate-900 dark:text-white">
                    {t(c.key)}
                  </option>
                ))}
              </select>
            </div>

            {/* Input */}
            <div className="relative flex-1 w-full">
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder={t('hero_search_placeholder')}
                className="w-full px-3 sm:px-4 py-2 sm:py-2.5 text-slate-900 dark:text-white placeholder-slate-400 dark:placeholder-slate-500 text-xs sm:text-sm font-medium focus:outline-none bg-transparent"
              />
              {searchTerm && (
                <button
                  type="button"
                  onClick={() => {
                    setSearchTerm('');
                    onSearch('');
                  }}
                  className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-xs"
                >
                  ✕
                </button>
              )}
            </div>

            {/* Search Button */}
            <button
              type="submit"
              className="w-full sm:w-auto px-5 sm:px-6 py-2.5 sm:py-3 bg-gradient-to-r from-teal-600 to-teal-700 hover:from-teal-700 hover:to-teal-800 text-white font-black text-xs sm:text-sm rounded-xl sm:rounded-2xl shadow-md transition active:scale-95 shrink-0 flex items-center justify-center gap-1.5"
            >
              <span>🔍</span>
              <span>{t('hero_search_btn')}</span>
            </button>
          </form>

          {/* Quick Stats Pill */}
          <div className="pt-2 flex flex-wrap items-center justify-center gap-3 sm:gap-6 text-[11px] sm:text-xs text-slate-400">
            <span className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-teal-400"></span>
              <span><strong>{totalMerchants}</strong> {t('hero_stat_merchants')}</span>
            </span>
            <span>•</span>
            <span className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-indigo-400"></span>
              <span><strong>{totalProducts}</strong> {t('hero_stat_products')}</span>
            </span>
            <span className="hidden sm:inline">•</span>
            <span className="text-teal-400 font-semibold">{t('hero_stat_delivery')}</span>
          </div>

          {/* Category Chips Bar */}
          {categories && categories.length > 0 && (
            <div id="categories-section" className="pt-3 sm:pt-4 flex items-center justify-start sm:justify-center gap-2 overflow-x-auto pb-1 scrollbar-none max-w-3xl mx-auto px-1">
              <button
                onClick={() => onSelectCategory(null)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition shrink-0 ${
                  activeCategory === null
                    ? 'bg-teal-500 text-slate-950 font-black shadow-md shadow-teal-500/20'
                    : 'bg-slate-800/80 hover:bg-slate-800 text-slate-300 border border-slate-700'
                }`}
              >
                {t('hero_all_categories')}
              </button>
              {categories.map((cat) => (
                <button
                  key={cat.id}
                  onClick={() => onSelectCategory(cat.id)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold transition shrink-0 ${
                    activeCategory === cat.id
                      ? 'bg-teal-500 text-slate-950 font-black shadow-md shadow-teal-500/20'
                      : 'bg-slate-800/80 hover:bg-slate-800 text-slate-300 border border-slate-700'
                  }`}
                >
                  {cat.name} ({cat.products_count})
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
