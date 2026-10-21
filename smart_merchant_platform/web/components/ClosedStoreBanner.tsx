import React from 'react';
import { buildWhatsAppUrl } from '@/lib/utils';
import type { StoreBootstrap } from '@/lib/types';

interface ClosedStoreBannerProps {
  store: StoreBootstrap;
}

export function ClosedStoreBanner({ store }: ClosedStoreBannerProps) {
  const storeTitle = store.display_name || store.business_name || 'المتجر';
  const whatsappUrl = buildWhatsAppUrl(store.whatsapp || store.phone, storeTitle);

  return (
    <div className="bg-amber-50 border-b border-amber-200 px-4 py-3 text-amber-900">
      <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3 text-sm">
        <div className="flex items-center gap-2 text-center sm:text-right">
          <svg
            className="w-5 h-5 text-amber-600 shrink-0"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            width="20"
            height="20"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <span>
            <strong>المتجر مغلق حالياً:</strong> يمكنك تصفح المنتجات ولكن لا يمكن استقبال طلبات جديدة في الوقت الحالي.
          </span>
        </div>

        {whatsappUrl && (
          <a
            href={whatsappUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="shrink-0 text-xs font-semibold bg-amber-600 hover:bg-amber-700 text-white px-3 py-1.5 rounded-lg transition"
          >
            تواصل عبر واتساب
          </a>
        )}
      </div>
    </div>
  );
}
