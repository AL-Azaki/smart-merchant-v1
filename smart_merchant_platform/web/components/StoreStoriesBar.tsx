'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import type { MarketplaceMerchant } from '@/lib/types';
import { useMarketplace } from '@/lib/marketplace-context';

interface StoreStoriesBarProps {
  merchants: MarketplaceMerchant[];
}

export function StoreStoriesBar({ merchants }: StoreStoriesBarProps) {
  const { t } = useMarketplace();
  const [activeStoryMerchant, setActiveStoryMerchant] = useState<MarketplaceMerchant | null>(null);

  if (!merchants || merchants.length === 0) return null;

  return (
    <>
      <section className="py-4 sm:py-6 border-b border-slate-100 dark:border-slate-800 bg-white dark:bg-slate-900/50 transition-colors">
        <div className="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <span className="flex h-2.5 w-2.5 relative">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-teal-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-teal-500"></span>
              </span>
              <h3 className="text-xs sm:text-sm font-black text-slate-800 dark:text-slate-100">
                {t('stories_title')}
              </h3>
            </div>
            <span className="text-[10px] sm:text-[11px] text-slate-500 dark:text-slate-400 font-medium hidden sm:inline">
              {t('stories_hint')}
            </span>
          </div>

          {/* Stories Horizontal Reel */}
          <div className="flex items-center gap-3 sm:gap-4 overflow-x-auto pb-2 scrollbar-none">
            {merchants.map((merchant) => {
              const initial = merchant.name.charAt(0);
              return (
                <button
                  key={merchant.id}
                  onClick={() => setActiveStoryMerchant(merchant)}
                  className="flex flex-col items-center gap-1.5 shrink-0 group focus:outline-none"
                >
                  {/* Story Gradient Ring */}
                  <div className="p-[2px] sm:p-[2.5px] rounded-full bg-gradient-to-tr from-amber-500 via-rose-500 to-teal-500 group-hover:scale-105 transition-transform duration-200 shadow-xs">
                    <div className="p-0.5 bg-white dark:bg-slate-900 rounded-full">
                      <div className="w-12 h-12 sm:w-16 sm:h-16 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center font-black text-slate-700 dark:text-slate-200 text-base sm:text-xl overflow-hidden relative border border-slate-100 dark:border-slate-700">
                        {merchant.logo ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            src={merchant.logo}
                            alt={merchant.name}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <span>{initial}</span>
                        )}
                        <span className="absolute bottom-0 right-0 w-3 h-3 sm:w-3.5 sm:h-3.5 bg-emerald-500 border-2 border-white dark:border-slate-900 rounded-full"></span>
                      </div>
                    </div>
                  </div>

                  <span className="text-[10px] sm:text-[11px] font-bold text-slate-700 dark:text-slate-300 group-hover:text-teal-600 dark:group-hover:text-teal-400 transition truncate max-w-[65px] sm:max-w-[75px] text-center">
                    {merchant.name}
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      </section>

      {/* 9:16 Interactive Story Modal */}
      {activeStoryMerchant && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-3 sm:p-4 animate-in fade-in duration-200">
          <div className="relative w-full max-w-sm aspect-[9/16] bg-gradient-to-b from-slate-900 via-slate-800 to-black rounded-3xl overflow-hidden shadow-2xl border border-slate-700 flex flex-col justify-between text-white p-5 sm:p-6">
            {/* Background Ambient Visual */}
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/marketing/tajer_story_ad.jpg"
              alt="Story Background"
              className="absolute inset-0 w-full h-full object-cover opacity-20 pointer-events-none mix-blend-luminosity"
            />
            <div className="absolute inset-0 bg-gradient-to-b from-slate-950/80 via-slate-900/60 to-black/90 pointer-events-none" />

            {/* Top Bar with Timer Bar */}
            <div className="relative z-10">
              <div className="w-full bg-slate-700 h-1 rounded-full overflow-hidden mb-3 sm:mb-4">
                <div className="bg-teal-400 h-full w-full animate-[progress_5s_linear]"></div>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5 sm:gap-3">
                  <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-teal-600 flex items-center justify-center font-black text-xs sm:text-sm border-2 border-white">
                    {activeStoryMerchant.logo ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={activeStoryMerchant.logo}
                        alt={activeStoryMerchant.name}
                        className="w-full h-full object-cover rounded-full"
                      />
                    ) : (
                      activeStoryMerchant.name.charAt(0)
                    )}
                  </div>
                  <div>
                    <h4 className="font-extrabold text-xs sm:text-sm">{activeStoryMerchant.name}</h4>
                    <span className="text-[9px] sm:text-[10px] text-teal-400 font-medium">{t('story_verified')}</span>
                  </div>
                </div>

                <button
                  onClick={() => setActiveStoryMerchant(null)}
                  className="w-7 h-7 sm:w-8 sm:h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white transition text-xs sm:text-sm"
                >
                  ✕
                </button>
              </div>
            </div>

            {/* Story Middle Content */}
            <div className="text-center space-y-3 sm:space-y-4 my-auto relative z-10">
              <div className="w-16 h-16 sm:w-20 sm:h-20 mx-auto rounded-2xl sm:rounded-3xl bg-teal-500/20 border border-teal-500/30 flex items-center justify-center text-3xl sm:text-4xl shadow-lg">
                🏪
              </div>

              <div className="space-y-1.5 sm:space-y-2">
                <span className="text-[10px] sm:text-xs bg-teal-500/20 text-teal-300 font-bold px-3 py-1 rounded-full border border-teal-500/30">
                  {activeStoryMerchant.business_type || t('merchants_default_type')}
                </span>
                <h3 className="text-xl sm:text-2xl font-black">{activeStoryMerchant.name}</h3>
                <p className="text-[11px] sm:text-xs text-slate-300 px-3 leading-relaxed">
                  {activeStoryMerchant.address || 'متوفر لخدمتكم والتوصيل المباشر داخل منطقتكم.'}
                </p>
              </div>

              <div className="bg-white/5 border border-white/10 rounded-2xl p-3 sm:p-3.5 backdrop-blur-sm max-w-xs mx-auto">
                <span className="text-[10px] sm:text-[11px] text-slate-400 block mb-0.5">{t('story_ready_products')}</span>
                <span className="text-base sm:text-lg font-black text-teal-300">
                  {activeStoryMerchant.active_products_count} {t('story_products_unit')}
                </span>
              </div>
            </div>

            {/* Bottom Call to Action */}
            <div className="space-y-3 pt-3 sm:pt-4 border-t border-white/10 relative z-10">
              <Link
                href={`/store/${activeStoryMerchant.slug}`}
                onClick={() => setActiveStoryMerchant(null)}
                className="w-full py-3 sm:py-3.5 px-4 bg-gradient-to-r from-teal-500 to-teal-600 hover:from-teal-600 hover:to-teal-700 text-slate-950 font-black text-xs sm:text-sm rounded-xl sm:rounded-2xl flex items-center justify-center gap-2 shadow-lg transition active:scale-95"
              >
                <span>{t('story_visit_btn')}</span>
                <span>←</span>
              </Link>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
