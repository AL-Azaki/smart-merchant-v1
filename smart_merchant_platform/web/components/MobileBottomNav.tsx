'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useCart } from '@/lib/cart-context';
import { buildWhatsAppUrl } from '@/lib/utils';
import type { StoreBootstrap } from '@/lib/types';

interface MobileBottomNavProps {
  slug: string;
  store: StoreBootstrap;
}

export function MobileBottomNav({ slug, store }: MobileBottomNavProps) {
  const pathname = usePathname();
  const { itemCount, isLoaded } = useCart();

  const storeTitle = store.display_name || store.business_name || 'المتجر';
  const whatsappUrl = buildWhatsAppUrl(store.whatsapp || store.phone, storeTitle);

  const isHome = pathname === `/store/${slug}`;
  const isCart = pathname.startsWith(`/store/${slug}/cart`);

  return (
    <nav
      aria-label="التنقل السفلي للموبايل"
      className="md:hidden fixed bottom-0 left-0 right-0 z-50 h-16 bg-white/95 backdrop-blur-xl border-t border-slate-200/90 shadow-[0_-4px_20px_rgba(15,23,42,0.06)] px-4 flex items-center justify-around"
    >
      {/* Home Tab */}
      <Link
        href={`/store/${slug}`}
        className={`flex flex-col items-center justify-center flex-1 py-1 transition-all ${
          isHome ? 'text-teal-700 font-bold' : 'text-slate-500 hover:text-slate-800'
        }`}
      >
        <div className="relative">
          <svg
            className={`w-5 h-5 transition-transform ${isHome ? 'scale-110' : ''}`}
            fill={isHome ? 'currentColor' : 'none'}
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={isHome ? 2.2 : 1.8}
              d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
            />
          </svg>
        </div>
        <span className="text-[11px] mt-0.5 leading-tight">الرئيسية</span>
      </Link>

      {/* Cart Tab with Badge */}
      <Link
        href={`/store/${slug}/cart`}
        className={`flex flex-col items-center justify-center flex-1 py-1 transition-all ${
          isCart ? 'text-teal-700 font-bold' : 'text-slate-500 hover:text-slate-800'
        }`}
      >
        <div className="relative">
          <svg
            className={`w-5 h-5 transition-transform ${isCart ? 'scale-110' : ''}`}
            fill={isCart ? 'currentColor' : 'none'}
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={isCart ? 2.2 : 1.8}
              d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
            />
          </svg>
          {isLoaded && itemCount > 0 && (
            <span className="absolute -top-1.5 -right-2.5 bg-amber-500 text-white text-[10px] font-extrabold min-w-4 h-4 px-1 rounded-full flex items-center justify-center shadow-xs">
              {itemCount > 99 ? '99+' : itemCount}
            </span>
          )}
        </div>
        <span className="text-[11px] mt-0.5 leading-tight">السلة</span>
      </Link>

      {/* Direct WhatsApp Contact Tab */}
      {whatsappUrl ? (
        <a
          href={whatsappUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="flex flex-col items-center justify-center flex-1 py-1 text-emerald-600 hover:text-emerald-700 transition-all"
        >
          <div className="w-8 h-8 rounded-full bg-emerald-50 border border-emerald-200/60 flex items-center justify-center shadow-xs">
            <svg
              className="w-4 h-4 text-emerald-600 shrink-0"
              fill="currentColor"
              viewBox="0 0 24 24"
            >
              <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981z" />
            </svg>
          </div>
          <span className="text-[10px] mt-0.5 leading-tight font-semibold">واتساب</span>
        </a>
      ) : store.phone ? (
        <a
          href={`tel:${store.phone}`}
          className="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-slate-800 transition-all"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.8} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
          </svg>
          <span className="text-[11px] mt-0.5 leading-tight">اتصال</span>
        </a>
      ) : null}

      {/* Store Location / Info Quick Link */}
      <a
        href="#store-footer"
        className="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-slate-800 transition-all"
      >
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.8} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
        </svg>
        <span className="text-[11px] mt-0.5 leading-tight">عن المتجر</span>
      </a>
    </nav>
  );
}
