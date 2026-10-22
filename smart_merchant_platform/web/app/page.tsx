'use client';

import React, { useEffect, useState, useTransition } from 'react';
import { MarketplaceNavbar } from '@/components/MarketplaceNavbar';
import { MarketplaceFooter } from '@/components/MarketplaceFooter';
import { StoreStoriesBar } from '@/components/StoreStoriesBar';
import { MarketplaceHero } from '@/components/MarketplaceHero';
import { FeaturedMerchantsGrid } from '@/components/FeaturedMerchantsGrid';
import { CrossStoreProductGrid } from '@/components/CrossStoreProductGrid';
import { MerchantOnboardingBanner } from '@/components/MerchantOnboardingBanner';
import { getMarketplaceExplore } from '@/lib/api';
import type { MarketplaceExploreData } from '@/lib/types';
import { MarketplaceProvider, useMarketplace } from '@/lib/marketplace-context';

function MarketplaceHomeContent() {
  const { t } = useMarketplace();
  const [data, setData] = useState<MarketplaceExploreData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const loadData = async (q?: string, catId?: string | null) => {
    try {
      setLoading(true);
      setError(null);
      const res = await getMarketplaceExplore({
        q: q || undefined,
        category_id: catId || undefined,
      });
      setData(res.data);
    } catch {
      setError(t('error_loading'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Smoothly scroll to target section when arriving with a hash (e.g., #explore-products)
  useEffect(() => {
    if (!loading && data && typeof window !== 'undefined') {
      const handleHashScroll = () => {
        const hash = window.location.hash;
        if (hash) {
          const targetId = hash.replace('#', '');
          const element = document.getElementById(targetId);
          if (element) {
            setTimeout(() => {
              element.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }, 120);
          }
        }
      };

      handleHashScroll();
      window.addEventListener('hashchange', handleHashScroll);
      return () => window.removeEventListener('hashchange', handleHashScroll);
    }
  }, [loading, data]);

  const handleSearch = (q: string) => {
    setSearchQuery(q);
    startTransition(() => {
      loadData(q, selectedCategory);
    });
  };

  const handleSelectCategory = (catId: string | null) => {
    setSelectedCategory(catId);
    startTransition(() => {
      loadData(searchQuery, catId);
    });
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 font-sans transition-colors duration-200">
      {/* 1. Global Navigation Bar */}
      <MarketplaceNavbar />

      {/* 2. Interactive Stories Reel (9:16 Visuals) */}
      {data && data.merchants && data.merchants.length > 0 && (
        <StoreStoriesBar merchants={data.merchants} />
      )}

      {/* 3. Hero Search & Omnisearch Section */}
      <MarketplaceHero
        categories={data?.categories || []}
        merchants={data?.merchants || []}
        onSearch={handleSearch}
        onSelectCategory={handleSelectCategory}
        activeCategory={selectedCategory}
        totalMerchants={data?.total_merchants || 0}
        totalProducts={data?.total_products || 0}
      />

      {/* Loading Skeleton */}
      {loading && (
        <div className="max-w-7xl mx-auto px-4 py-16 w-full space-y-8 animate-pulse">
          <div className="h-8 bg-slate-200 dark:bg-slate-800 rounded-xl w-64"></div>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            <div className="h-44 bg-slate-200 dark:bg-slate-800 rounded-2xl"></div>
            <div className="h-44 bg-slate-200 dark:bg-slate-800 rounded-2xl"></div>
            <div className="h-44 bg-slate-200 dark:bg-slate-800 rounded-2xl"></div>
          </div>
        </div>
      )}

      {/* Error Message */}
      {error && !loading && (
        <div className="max-w-xl mx-auto my-12 p-6 bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/50 rounded-3xl text-center space-y-3">
          <span className="text-3xl">⚠️</span>
          <p className="text-rose-700 dark:text-rose-300 text-sm font-bold">{error}</p>
          <button
            onClick={() => loadData(searchQuery, selectedCategory)}
            className="px-5 py-2.5 bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs rounded-xl transition"
          >
            {t('retry')}
          </button>
        </div>
      )}

      {/* Main Content Area */}
      {!loading && data && (
        <main className={`flex-1 transition-opacity ${isPending ? 'opacity-60' : 'opacity-100'}`}>
          {/* 4. Verified Featured Merchants */}
          <FeaturedMerchantsGrid merchants={data.merchants} />

          {/* 5. Cross-Store Products Grid */}
          <CrossStoreProductGrid products={data.products} searchTerm={searchQuery} />

          {/* 6. Merchant Conversion & Acquisition Banner */}
          <MerchantOnboardingBanner />
        </main>
      )}

      {/* 7. Central Marketplace Footer */}
      <MarketplaceFooter />
    </div>
  );
}

export default function MarketplaceHomePage() {
  return (
    <MarketplaceProvider>
      <MarketplaceHomeContent />
    </MarketplaceProvider>
  );
}
