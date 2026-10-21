'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import type { StoreProductDetail } from '@/lib/types';
import { formatCurrency, buildWhatsAppUrl } from '@/lib/utils';
import { useCart } from '@/lib/cart-context';
import { ProductImage } from './ProductImage';

interface ProductDetailViewProps {
  slug: string;
  product: StoreProductDetail;
}

export function ProductDetailView({ slug, product }: ProductDetailViewProps) {
  const { addItem } = useCart();

  // Active units
  const activeUnits = (product.units || []).filter((u) => u.is_active);

  const [selectedUnitId, setSelectedUnitId] = useState<string>(
    activeUnits.length > 0 ? activeUnits[0].id : '',
  );
  const [quantity, setQuantity] = useState<number>(1);
  const [addedToast, setAddedToast] = useState(false);

  const selectedUnit = activeUnits.find((u) => u.id === selectedUnitId) || activeUnits[0];

  const handleAddToCart = () => {
    if (!selectedUnit) return;

    addItem(
      {
        productId: product.id,
        productUnitId: selectedUnit.id,
        productName: product.product_name,
        unitName: selectedUnit.unit_name || selectedUnit.unit_symbol || 'وحدة',
        displayedPrice: selectedUnit.selling_price,
        image: product.primary_image,
      },
      quantity,
    );

    setAddedToast(true);
    setTimeout(() => setAddedToast(false), 2500);
  };

  const currentPrice = selectedUnit ? selectedUnit.selling_price : 0;
  const whatsappInquiryUrl = buildWhatsAppUrl(
    undefined,
    'المتجر',
    undefined,
  );

  return (
    <div className="bg-white rounded-3xl border border-slate-200/80 shadow-[0_4px_24px_rgba(15,23,42,0.04)] overflow-hidden p-6 sm:p-10">
      {/* Breadcrumb / Back Link */}
      <div className="mb-6">
        <Link
          href={`/store/${slug}`}
          className="inline-flex items-center gap-2 text-xs font-bold text-slate-600 hover:text-teal-700 transition group"
        >
          <span className="p-1 rounded-lg bg-slate-100 group-hover:bg-teal-50 text-slate-700 group-hover:text-teal-700 transition">
            <svg
              className="w-4 h-4 rotate-180 shrink-0"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.2} d="M14 5l7 7m0 0l-7 7m7-7H3" />
            </svg>
          </span>
          <span>العودة لجميع منتجات المتجر</span>
        </Link>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 lg:gap-12 items-start">
        {/* Product Visual Gallery */}
        <div className="space-y-4">
          <div className="aspect-square bg-slate-50 rounded-2xl overflow-hidden border border-slate-200/80 shadow-xs relative">
            <ProductImage
              src={product.primary_image}
              alt={product.product_name}
              className="w-full h-full object-cover"
            />
            {product.category?.category_name && (
              <span className="absolute top-3 right-3 bg-white/95 backdrop-blur-md text-xs font-bold text-slate-800 px-3 py-1 rounded-full shadow-xs border border-slate-100">
                {product.category.category_name}
              </span>
            )}
            <span className="absolute bottom-3 right-3 inline-flex items-center gap-1.5 bg-white/95 backdrop-blur-md text-xs font-bold text-teal-800 px-3 py-1 rounded-full shadow-xs border border-teal-100">
              <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
              <span>أصلي ومضمون</span>
            </span>
          </div>

          {/* Gallery Thumbnails */}
          {product.images && product.images.length > 1 && (
            <div className="flex gap-2.5 overflow-x-auto pb-2 scrollbar-none">
              {product.images.map((img) => (
                <div
                  key={img.id}
                  className="w-18 h-18 rounded-2xl border border-slate-200 overflow-hidden shrink-0 shadow-xs bg-slate-50"
                >
                  <ProductImage
                    src={img.image_path}
                    alt={product.product_name}
                    hasFallback={img.has_fallback}
                    className="w-full h-full object-cover"
                  />
                </div>
              ))}
            </div>
          )}

          {/* Customer Trust Guarantees Box */}
          <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200/70 space-y-2.5 text-xs">
            <div className="flex items-center gap-2.5 text-slate-700">
              <span className="text-teal-600 font-bold text-base">🛡️</span>
              <div>
                <strong className="text-slate-900 block font-bold">ضمان المعاينة والمطابقة:</strong>
                <span className="text-slate-500 text-[11px]">يحق لك فحص المنتج ومعاينته عند الاستلام قبل دفع أي مبلغ.</span>
              </div>
            </div>

            <div className="flex items-center gap-2.5 text-slate-700 pt-2 border-t border-slate-200/50">
              <span className="text-teal-600 font-bold text-base">💵</span>
              <div>
                <strong className="text-slate-900 block font-bold">الدفع الآمن عند الاستلام:</strong>
                <span className="text-slate-500 text-[11px]">سداد المبلغ نقداً وبأمان للمندوب بعد التأكد من طلبك.</span>
              </div>
            </div>

            <div className="flex items-center gap-2.5 text-slate-700 pt-2 border-t border-slate-200/50">
              <span className="text-teal-600 font-bold text-base">🚚</span>
              <div>
                <strong className="text-slate-900 block font-bold">تجهيز سريع وشحن بعناية:</strong>
                <span className="text-slate-500 text-[11px]">يتم تجهيز المنتجات من المخزن مباشرة وتغليفها بأمان.</span>
              </div>
            </div>
          </div>
        </div>

        {/* Product Information & Purchasing Column */}
        <div className="flex flex-col h-full justify-between space-y-6">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <span className="inline-flex items-center gap-1 text-[11px] font-bold text-teal-800 bg-teal-50 border border-teal-200/80 px-2.5 py-0.5 rounded-full">
                <span>✓</span> منتج متوفر بالمخزن
              </span>
              {product.brand?.brand_name && (
                <span className="text-xs text-slate-500 font-medium">
                  الماركة: <strong className="text-slate-800">{product.brand.brand_name}</strong>
                </span>
              )}
            </div>

            <h1 className="text-2xl sm:text-3xl font-black text-slate-900 leading-tight">
              {product.product_name}
            </h1>

            {/* Price Block */}
            <div className="mt-4 p-4 rounded-2xl bg-teal-50/50 border border-teal-100">
              <span className="text-[11px] text-teal-700 font-bold block mb-0.5">السعر الرسمي المعتمد</span>
              <div className="text-3xl font-black text-slate-900 tracking-tight" dir="ltr">
                {formatCurrency(currentPrice)}
              </div>
              <p className="text-[11px] text-slate-500 mt-1">
                * السعر شامل وقابل للتأكيد النهائي عند إرسال الطلب، بدون أي عمولات إضافية.
              </p>
            </div>

            {/* Product Description */}
            {product.description && (
              <div className="mt-5">
                <h2 className="text-xs font-bold text-slate-800 mb-1.5">مواصفات وتفاصيل المنتج</h2>
                <p className="text-xs sm:text-sm text-slate-600 leading-relaxed whitespace-pre-line bg-slate-50/70 p-4 rounded-2xl border border-slate-100">
                  {product.description}
                </p>
              </div>
            )}

            {/* Units Selection Grid */}
            {activeUnits.length > 0 ? (
              <div className="mt-6">
                <label className="block text-xs font-bold text-slate-800 mb-2">
                  اختر الحجم أو الوحدة المطلوبة:
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                  {activeUnits.map((unit) => {
                    const isSelected = unit.id === selectedUnitId;
                    return (
                      <button
                        key={unit.id}
                        type="button"
                        onClick={() => setSelectedUnitId(unit.id)}
                        className={`p-3 rounded-2xl border text-right transition cursor-pointer ${
                          isSelected
                            ? 'border-teal-600 bg-teal-50/90 text-teal-950 ring-2 ring-teal-500/20 shadow-xs'
                            : 'border-slate-200 hover:border-slate-300 text-slate-700 bg-white'
                        }`}
                      >
                        <span className="block text-xs font-bold">
                          {unit.unit_name || unit.unit_symbol || 'وحدة'}
                        </span>
                        <span className="block text-xs text-slate-600 mt-1 font-extrabold" dir="ltr">
                          {formatCurrency(unit.selling_price)}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            ) : (
              <div className="mt-6 p-4 rounded-2xl bg-amber-50 text-amber-800 text-xs font-semibold">
                لا توجد وحدات بيع متاحة لهذا المنتج حالياً.
              </div>
            )}

            {/* Quantity Selector */}
            {activeUnits.length > 0 && (
              <div className="mt-6">
                <label className="block text-xs font-bold text-slate-800 mb-2">
                  الكمية المطلوبة:
                </label>
                <div className="flex items-center gap-3">
                  <div className="flex items-center border border-slate-200 rounded-2xl bg-slate-50/80 p-1">
                    <button
                      type="button"
                      onClick={() => setQuantity((q) => Math.max(1, q - 1))}
                      className="w-9 h-9 rounded-xl bg-white border border-slate-200 hover:bg-slate-100 flex items-center justify-center font-bold text-slate-800 transition active:scale-95 cursor-pointer"
                      aria-label="تقليل الكمية"
                    >
                      -
                    </button>
                    <span className="w-12 text-center font-black text-sm text-slate-900">
                      {quantity}
                    </span>
                    <button
                      type="button"
                      onClick={() => setQuantity((q) => q + 1)}
                      className="w-9 h-9 rounded-xl bg-white border border-slate-200 hover:bg-slate-100 flex items-center justify-center font-bold text-slate-800 transition active:scale-95 cursor-pointer"
                      aria-label="زيادة الكمية"
                    >
                      +
                    </button>
                  </div>
                  <span className="text-xs text-slate-500 font-medium">
                    {selectedUnit?.unit_name || selectedUnit?.unit_symbol}
                  </span>
                </div>
              </div>
            )}
          </div>

          {/* Add to Cart Button */}
          {activeUnits.length > 0 && (
            <div className="pt-6 border-t border-slate-100 space-y-3">
              <button
                type="button"
                onClick={handleAddToCart}
                className="w-full flex items-center justify-center gap-2.5 bg-teal-600 hover:bg-teal-700 active:scale-98 text-white font-black py-4 px-6 rounded-2xl shadow-lg shadow-teal-600/25 transition cursor-pointer text-sm sm:text-base"
              >
                <svg
                  className="w-5 h-5 shrink-0"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2.2}
                    d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
                  />
                </svg>
                <span>أضف إلى سلة المشتريات ({formatCurrency(currentPrice * quantity)})</span>
              </button>

              {addedToast && (
                <div className="p-3.5 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-900 text-xs text-center font-bold animate-in fade-in flex items-center justify-center gap-2">
                  <span className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-xs">✓</span>
                  <span>رائع! تمت إضافة المنتج إلى سلتك بنجاح. يمكنك متابعة التسوق أو إتمام الطلب الآن.</span>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
