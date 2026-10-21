'use client';

import React from 'react';
import Link from 'next/link';
import type { StoreBootstrap } from '@/lib/types';
import { useCart } from '@/lib/cart-context';
import { buildWhatsAppUrl, isValidImageUrl } from '@/lib/utils';

interface NavbarProps {
  slug: string;
  store: StoreBootstrap;
}

export function Navbar({ slug, store }: NavbarProps) {
  const { itemCount, isLoaded } = useCart();

  const storeTitle = store.display_name || store.business_name || 'المتجر الإلكتروني';
  const whatsappUrl = buildWhatsAppUrl(store.whatsapp || store.phone, storeTitle);
  const hasLogo = store.logo_path && isValidImageUrl(store.logo_path);

  return (
    <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200/80 shadow-[0_1px_8px_rgba(0,0,0,0.03)]">
      {/* Top Utility Reassurance Strip (Desktop & Tablet) */}
      <div className="bg-slate-900 text-slate-300 text-xs py-1.5 px-4 hidden sm:block border-b border-slate-800">
        <div className="max-w-7xl mx-auto flex items-center justify-between font-medium">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-1.5 text-teal-400">
              <span className="w-2 h-2 rounded-full bg-teal-400 animate-pulse"></span>
              <span className="font-bold">تسوق مباشر وآمن:</span>
              <span className="text-slate-200">دفع نقداً عند الاستلام • معاينة المنتجات قبل الدفع • بدون عمولات وسيطة</span>
            </div>
          </div>

          <div className="flex items-center gap-4 text-slate-300">
            {store.phone && (
              <a
                href={`tel:${store.phone}`}
                className="hover:text-teal-400 transition flex items-center gap-1 font-semibold"
                dir="ltr"
              >
                <span>📞</span>
                <span>{store.phone}</span>
              </a>
            )}
            <span className="text-slate-700">|</span>
            <div className="flex items-center gap-1 text-slate-400">
              <span>🛡️ متجر معتمد وموثق</span>
            </div>
          </div>
        </div>
      </div>

      {/* Main Branded Navigation Bar */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 sm:h-18 flex items-center justify-between gap-4">
        {/* Brand Logo & Store Details */}
        <Link
          href={`/store/${slug}`}
          className="flex items-center gap-3 hover:opacity-95 transition shrink-0 group"
        >
          <div className="relative">
            {hasLogo ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={store.logo_path!}
                alt={storeTitle}
                className="w-10 h-10 sm:w-12 sm:h-12 rounded-2xl object-cover border border-slate-100 shadow-sm group-hover:scale-105 transition-transform"
              />
            ) : (
              <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-2xl bg-gradient-to-tr from-teal-700 to-teal-600 text-white flex items-center justify-center font-black text-lg sm:text-xl shadow-md shadow-teal-700/20 group-hover:scale-105 transition-transform">
                {storeTitle.charAt(0)}
              </div>
            )}
            {/* Verified Merchant Badge */}
            <span
              className="absolute -bottom-1 -left-1 w-4 h-4 rounded-full bg-teal-600 text-white flex items-center justify-center text-[10px] ring-2 ring-white shadow-xs font-bold"
              title="متجر رسمي معتمد وموثق"
            >
              ✓
            </span>
          </div>

          <div className="flex flex-col">
            <div className="flex items-center gap-2">
              <h1 className="font-black text-base sm:text-lg text-slate-900 tracking-tight leading-tight group-hover:text-teal-700 transition-colors">
                {storeTitle}
              </h1>
              <span className="hidden sm:inline-flex items-center gap-1 text-[10px] font-bold text-teal-800 bg-teal-50 border border-teal-200/80 px-2 py-0.5 rounded-full">
                <span>🛡️</span>
                <span>متجر موثق</span>
              </span>
            </div>

            {!store.storefront_active ? (
              <span className="text-[11px] font-bold text-amber-700 bg-amber-50 px-2.5 py-0.5 rounded-full inline-block mt-0.5 w-fit">
                المتجر مغلق مؤقتاً
              </span>
            ) : (
              <span className="text-[11px] text-slate-500 hidden sm:inline-block font-medium">
                شحن وتوصيل مباشر • أسعار معتمدة رسمياً
              </span>
            )}
          </div>
        </Link>

        {/* Action Controls: WhatsApp & Cart */}
        <div className="flex items-center gap-2 sm:gap-3">
          {whatsappUrl && (
            <a
              href={whatsappUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 text-xs font-bold text-white bg-[#25D366] hover:bg-[#20bd5a] px-3.5 py-2 sm:px-4 sm:py-2.5 rounded-full shadow-sm hover:shadow-md transition active:scale-95 cursor-pointer"
              aria-label="تواصل مع المتجر عبر واتساب"
              title="تواصل مباشر وفوري مع مسؤول المتجر"
            >
              <svg
                className="w-4 h-4 text-white shrink-0"
                fill="currentColor"
                viewBox="0 0 24 24"
              >
                <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981z" />
              </svg>
              <span className="hidden sm:inline">خدمة العملاء عبر واتساب</span>
            </a>
          )}

          {/* Cart Trigger */}
          <Link
            href={`/store/${slug}/cart`}
            className="relative inline-flex items-center justify-center gap-2 px-3 py-2 sm:px-4 sm:py-2.5 rounded-2xl bg-teal-50 hover:bg-teal-100/90 text-teal-800 border border-teal-200/80 font-bold text-xs transition active:scale-95 shadow-xs"
            aria-label="سلة المشتريات"
          >
            <svg
              className="w-5 h-5 text-teal-700 shrink-0"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
              />
            </svg>
            <span className="hidden md:inline">سلة المشتريات</span>
            {isLoaded && itemCount > 0 && (
              <span className="bg-amber-500 text-white text-[10px] font-black px-1.5 py-0.5 rounded-full shadow-xs animate-in zoom-in-50 duration-200 min-w-5 text-center">
                {itemCount > 99 ? '99+' : itemCount}
              </span>
            )}
          </Link>
        </div>
      </div>
    </header>
  );
}
