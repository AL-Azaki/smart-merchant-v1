'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { buildWhatsAppUrl, formatCurrency } from '@/lib/utils';
import { getStoreBootstrap } from '@/lib/api';
import type { StoreBootstrap } from '@/lib/types';

interface OrderSuccessCache {
  orderNumber: string;
  grandTotal: number;
  date: string | null;
  customerName: string;
  slug: string;
}

export default function OrderSuccessPage() {
  const params = useParams();
  const slug = params.slug as string;
  const orderNumber = params.orderNumber as string;

  const [store, setStore] = useState<StoreBootstrap | null>(null);
  const [cachedOrder, setCachedOrder] = useState<OrderSuccessCache | null>(null);

  useEffect(() => {
    // Load store bootstrap to get WhatsApp & store name
    getStoreBootstrap(slug)
      .then((res) => setStore(res.data))
      .catch(() => null);

    // Retrieve temporary order summary from sessionStorage safely
    const timer = setTimeout(() => {
      try {
        const stored = sessionStorage.getItem(`smart-merchant-order-success:${orderNumber}`);
        if (stored) {
          setCachedOrder(JSON.parse(stored));
        }
      } catch {
        // ignore
      }
    }, 0);

    return () => clearTimeout(timer);
  }, [slug, orderNumber]);

  const storeTitle = store?.display_name || store?.business_name || 'المتجر';
  const whatsappUrl = buildWhatsAppUrl(
    store?.whatsapp || store?.phone,
    storeTitle,
    orderNumber,
  );

  return (
    <div className="py-8 sm:py-12 max-w-xl mx-auto space-y-6">
      <div className="bg-white p-6 sm:p-10 rounded-3xl border border-slate-200/80 shadow-[0_4px_25px_rgba(15,23,42,0.05)] text-center space-y-6">
        {/* Animated Celebration Badge */}
        <div className="w-20 h-20 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center mx-auto text-3xl shadow-sm border border-emerald-100 animate-in zoom-in-75 duration-300">
          ✓
        </div>

        <div>
          <span className="inline-block text-xs font-bold text-teal-800 bg-teal-50 border border-teal-200/80 px-3 py-1 rounded-full mb-2">
            تم استلام الطلب وتأكيده بنجاح
          </span>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
            شكراً لك! طلبك في أيدٍ أمينة
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-2 leading-relaxed">
            تم إرسال طلبك مباشرة إلى فريق عمل متجر <strong>{storeTitle}</strong>، وبدأنا في مراجعة وتجهيز المنتجات لتسليمها لك.
          </p>
        </div>

        {/* Order Details Receipt Card */}
        <div className="p-4 sm:p-5 rounded-2xl bg-slate-50 border border-slate-200/80 space-y-3 text-right">
          <div className="flex items-center justify-between text-xs sm:text-sm pb-2 border-b border-slate-200/60">
            <span className="text-slate-500 font-medium">رقم الطلب الرسمي:</span>
            <span className="font-mono font-black text-slate-900 text-sm sm:text-base bg-white px-2.5 py-0.5 rounded-lg border border-slate-200" dir="ltr">
              #{orderNumber}
            </span>
          </div>

          {cachedOrder?.customerName && (
            <div className="flex items-center justify-between text-xs">
              <span className="text-slate-500">اسم العميل:</span>
              <span className="font-bold text-slate-800">{cachedOrder.customerName}</span>
            </div>
          )}

          {cachedOrder?.grandTotal != null && (
            <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-200/50">
              <span className="text-slate-500">المبلغ الإجمالي المعتمد:</span>
              <span className="font-black text-teal-800 text-sm sm:text-base" dir="ltr">
                {formatCurrency(cachedOrder.grandTotal)}
              </span>
            </div>
          )}

          <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-200/50">
            <span className="text-slate-500">طريقة الدفع:</span>
            <span className="font-bold text-slate-800">نقداً عند الاستلام (COD)</span>
          </div>
        </div>

        {/* 3 Step Visual Progress */}
        <div className="p-4 rounded-2xl bg-teal-50/60 border border-teal-100 text-right space-y-3">
          <h2 className="text-xs font-black text-teal-950">ما هي الخطوات القادمة؟</h2>
          <div className="space-y-2 text-xs text-teal-900">
            <div className="flex items-center gap-2">
              <span className="w-5 h-5 rounded-full bg-teal-600 text-white flex items-center justify-center text-[10px] font-bold shrink-0">1</span>
              <span><strong>مراجعة الطلب:</strong> يقوم المتجر بمطابقة البضائع بالمخزن.</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-5 h-5 rounded-full bg-teal-200 text-teal-900 flex items-center justify-center text-[10px] font-bold shrink-0">2</span>
              <span><strong>التواصل والتنسيق:</strong> سيتصل بك المندوب لتأكيد الموعد المناسب للتسليم.</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-5 h-5 rounded-full bg-teal-200 text-teal-900 flex items-center justify-center text-[10px] font-bold shrink-0">3</span>
              <span><strong>المعاينة والاستلام:</strong> افحص طلبك وادفع نقداً عند باب بيتك.</span>
            </div>
          </div>
        </div>

        {/* WhatsApp Action */}
        {whatsappUrl && (
          <div className="pt-2">
            <a
              href={whatsappUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full inline-flex items-center justify-center gap-2.5 bg-[#25D366] hover:bg-[#20bd5a] text-white text-xs sm:text-sm font-black py-4 px-6 rounded-2xl shadow-lg shadow-emerald-600/25 transition cursor-pointer active:scale-98"
            >
              <svg className="w-5 h-5 shrink-0" fill="currentColor" viewBox="0 0 24 24">
                <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981z" />
              </svg>
              <span>متابعة وتأكيد الطلب فوراً عبر واتساب</span>
            </a>
          </div>
        )}

        <div className="pt-2">
          <Link
            href={`/store/${slug}`}
            className="inline-flex items-center gap-1.5 text-xs font-bold text-teal-700 hover:text-teal-800 hover:underline"
          >
            <span>←</span>
            <span>العودة لمتابعة التسوق من المتجر</span>
          </Link>
        </div>
      </div>
    </div>
  );
}
