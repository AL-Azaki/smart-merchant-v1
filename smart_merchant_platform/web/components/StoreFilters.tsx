'use client';

import React, { useState, useTransition } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import type { StoreCategory } from '@/lib/types';

interface StoreFiltersProps {
  slug: string;
  categories: StoreCategory[];
  currentCategoryId?: string;
  currentSearch?: string;
}

export function StoreFilters({
  slug,
  categories,
  currentCategoryId,
  currentSearch = '',
}: StoreFiltersProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();
  const [searchValue, setSearchValue] = useState(currentSearch);

  const updateParam = (key: string, value: string | null) => {
    const params = new URLSearchParams(searchParams.toString());
    if (value) {
      params.set(key, value);
    } else {
      params.delete(key);
    }
    // Always reset page when filter changes
    params.delete('page');

    startTransition(() => {
      router.push(`/store/${slug}?${params.toString()}`);
    });
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    updateParam('search', searchValue.trim() || null);
  };

  const clearSearch = () => {
    setSearchValue('');
    updateParam('search', null);
  };

  return (
    <div className="space-y-4 mb-6 sm:mb-8">
      {/* Search Input Bar */}
      <form onSubmit={handleSearchSubmit} className="relative w-full max-w-2xl mx-auto">
        <div className="relative flex items-center bg-white rounded-2xl border border-slate-200/90 shadow-[0_1px_3px_rgba(15,23,42,0.04)] focus-within:ring-2 focus-within:ring-teal-600 focus-within:border-transparent transition-all overflow-hidden">
          <div className="pr-4 pl-2 text-teal-600 shrink-0 pointer-events-none">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>

          <input
            type="search"
            value={searchValue}
            onChange={(e) => setSearchValue(e.target.value)}
            placeholder="ابحث عما يهمك من منتجات وماركات مميزة بالمتجر..."
            className="w-full bg-transparent pr-2 pl-24 py-3.5 text-sm text-slate-800 placeholder-slate-400 focus:outline-none text-right font-medium"
          />

          {searchValue && (
            <button
              type="button"
              onClick={clearSearch}
              className="p-1 text-slate-400 hover:text-slate-600 ml-1 text-xs"
              aria-label="مسح البحث"
            >
              ✕
            </button>
          )}

          <button
            type="submit"
            disabled={isPending}
            className="m-1.5 px-4 py-2 bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white text-xs font-bold rounded-xl transition shadow-xs cursor-pointer shrink-0"
          >
            {isPending ? 'جاري...' : 'بحث'}
          </button>
        </div>
      </form>

      {/* Category Pills Slider */}
      {categories.length > 0 && (
        <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none pt-1">
          <button
            type="button"
            onClick={() => updateParam('category_id', null)}
            className={`shrink-0 px-4 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
              !currentCategoryId
                ? 'bg-teal-600 text-white shadow-xs'
                : 'bg-white border border-slate-200/90 text-slate-700 hover:border-teal-500 hover:text-teal-700'
            }`}
          >
            جميع الأقسام
          </button>

          {categories.map((cat) => {
            const isSelected = currentCategoryId === cat.id;
            return (
              <button
                key={cat.id}
                type="button"
                onClick={() => updateParam('category_id', cat.id)}
                className={`shrink-0 px-4 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
                  isSelected
                    ? 'bg-teal-600 text-white shadow-xs'
                    : 'bg-white border border-slate-200/90 text-slate-700 hover:border-teal-500 hover:text-teal-700'
                }`}
              >
                {cat.category_name}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
