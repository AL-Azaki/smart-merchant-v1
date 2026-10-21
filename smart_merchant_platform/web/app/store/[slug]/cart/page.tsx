'use client';

import React from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useCart } from '@/lib/cart-context';
import { formatCurrency } from '@/lib/utils';
import { ProductImage } from '@/components/ProductImage';

export default function CartPage() {
  const params = useParams();
  const slug = params.slug as string;

  const { items, updateQuantity, removeItem, clearCart, estimatedTotal, isLoaded } = useCart();

  if (!isLoaded) {
    return (
      <div className="py-20 text-center text-slate-400 text-sm animate-pulse">
        جاري تحميل محتويات سلة مشترياتك...
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="py-20 text-center bg-white rounded-3xl border border-slate-200/80 p-8 sm:p-12 shadow-xs max-w-lg mx-auto">
        <div className="w-20 h-20 rounded-full bg-teal-50 text-teal-700 flex items-center justify-center mx-auto mb-4 text-3xl font-black shadow-sm">
          🛒
        </div>
        <h1 className="text-xl sm:text-2xl font-black text-slate-900 mb-2">سلة مشترياتك فارغة حالياً</h1>
        <p className="text-xs sm:text-sm text-slate-500 mb-6 leading-relaxed max-w-sm mx-auto">
          لم تقم بإضافة أي منتجات بعد. استكشف تشكيلة منتجات المتجر المعتمدة وأضف ما يعجبك.
        </p>
        <Link
          href={`/store/${slug}`}
          className="inline-flex items-center gap-2 px-6 py-3.5 bg-teal-600 hover:bg-teal-700 text-white text-xs sm:text-sm font-black rounded-2xl transition shadow-lg shadow-teal-600/20 cursor-pointer"
        >
          <span>تصفح أحدث المنتجات والعروض</span>
          <span>←</span>
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Page Title & Controls */}
      <div className="flex items-center justify-between pb-3 border-b border-slate-200/80">
        <div className="space-y-0.5">
          <div className="flex items-center gap-2">
            <span className="text-2xl">🛒</span>
            <h1 className="text-xl sm:text-2xl font-black text-slate-900">سلة المشتريات</h1>
            <span className="text-xs font-bold bg-teal-50 text-teal-800 px-2.5 py-0.5 rounded-full border border-teal-200/60">
              {items.length} منتجات
            </span>
          </div>
          <p className="text-xs text-slate-500">
            راجع الكميات والمنتجات قبل الانتقال لخطوة تحديد عنوان التوصيل.
          </p>
        </div>

        <button
          type="button"
          onClick={clearCart}
          className="text-xs text-rose-600 hover:text-rose-700 font-bold cursor-pointer hover:underline"
        >
          تفريغ السلة بالكامل
        </button>
      </div>

      {/* Trust Signal Banner */}
      <div className="p-3.5 sm:p-4 rounded-2xl bg-teal-50/70 border border-teal-100 flex items-center gap-3 text-xs text-teal-900">
        <span className="text-xl shrink-0">🛡️</span>
        <div>
          <strong className="font-bold block">تسوق بأمان تام:</strong>
          <span className="text-teal-800/80 text-[11px]">
            جميع الطلبات مدفوعة نقداً عند الاستلام بعد المعاينة والتأكد من مطابقة المنتجات.
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        {/* Cart Items List */}
        <div className="lg:col-span-2 space-y-3">
          {items.map((item) => (
            <div
              key={item.productUnitId}
              className="flex items-center gap-3 sm:gap-4 bg-white p-3.5 sm:p-4 rounded-2xl border border-slate-200/80 shadow-xs hover:border-teal-500/30 transition"
            >
              <div className="w-20 h-20 bg-slate-50 rounded-xl overflow-hidden shrink-0 border border-slate-100">
                <ProductImage
                  src={item.image}
                  alt={item.productName}
                  className="w-full h-full object-cover"
                />
              </div>

              <div className="flex-1 min-w-0">
                <h3 className="font-bold text-slate-900 text-sm truncate">
                  {item.productName}
                </h3>
                <span className="text-xs text-slate-400 block mt-0.5">
                  الوحدة: <strong className="text-slate-700">{item.unitName}</strong>
                </span>
                <span className="text-xs font-black text-slate-900 block mt-1" dir="ltr">
                  {formatCurrency(item.displayedPrice)}
                </span>
              </div>

              {/* Quantity Controls */}
              <div className="flex items-center gap-2">
                <div className="flex items-center border border-slate-200 rounded-xl bg-slate-50 p-0.5">
                  <button
                    type="button"
                    onClick={() => updateQuantity(item.productUnitId, item.quantity - 1)}
                    className="w-7 h-7 rounded-lg bg-white border border-slate-200 hover:bg-slate-100 flex items-center justify-center font-bold text-xs text-slate-700 cursor-pointer transition active:scale-90"
                    aria-label="تقليل"
                  >
                    -
                  </button>
                  <span className="w-8 text-center text-xs font-black text-slate-900">
                    {item.quantity}
                  </span>
                  <button
                    type="button"
                    onClick={() => updateQuantity(item.productUnitId, item.quantity + 1)}
                    className="w-7 h-7 rounded-lg bg-white border border-slate-200 hover:bg-slate-100 flex items-center justify-center font-bold text-xs text-slate-700 cursor-pointer transition active:scale-90"
                    aria-label="زيادة"
                  >
                    +
                  </button>
                </div>

                <button
                  type="button"
                  onClick={() => removeItem(item.productUnitId)}
                  className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg transition cursor-pointer"
                  title="حذف من السلة"
                  aria-label="حذف"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                    />
                  </svg>
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Order Summary Card */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-xs space-y-4">
          <h2 className="font-black text-slate-900 text-base">ملخص الطلب</h2>

          <div className="flex items-center justify-between text-sm pt-2 border-t border-slate-100">
            <span className="text-slate-500 font-medium">إجمالي المنتجات التقديري</span>
            <span className="font-black text-slate-900 text-lg" dir="ltr">
              {formatCurrency(estimatedTotal)}
            </span>
          </div>

          <div className="bg-slate-50 border border-slate-200/70 rounded-2xl p-3 text-[11px] text-slate-600 leading-relaxed">
            ✓ لا توجد رسوم خفية. يتم اعتماد السعر النهائي من المتجر فور إرسال الطلب.
          </div>

          <Link
            href={`/store/${slug}/checkout`}
            className="w-full flex items-center justify-center gap-2 bg-teal-600 hover:bg-teal-700 active:scale-98 text-white font-black py-4 px-6 rounded-2xl shadow-lg shadow-teal-600/20 transition cursor-pointer text-sm"
          >
            <span>متابعة الشراء (الدفع عند الاستلام)</span>
            <svg className="w-4 h-4 rotate-180" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.2} d="M14 5l7 7m0 0l-7 7m7-7H3" />
            </svg>
          </Link>

          <Link
            href={`/store/${slug}`}
            className="block text-center text-xs font-bold text-slate-400 hover:text-teal-700 pt-1 transition"
          >
            ← متابعة تصفح منتجات المتجر
          </Link>
        </div>
      </div>
    </div>
  );
}
