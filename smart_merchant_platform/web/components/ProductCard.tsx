'use client';

import React from 'react';
import Link from 'next/link';
import type { StoreProductListItem } from '@/lib/types';
import { formatCurrency } from '@/lib/utils';
import { useCart } from '@/lib/cart-context';
import { ProductImage } from './ProductImage';

interface ProductCardProps {
  slug: string;
  product: StoreProductListItem;
}

export function ProductCard({ slug, product }: ProductCardProps) {
  const { addItem } = useCart();

  // Find lowest price and active units
  const activeUnits = (product.units || []).filter((u) => u.is_active);
  const singleUnit = activeUnits.length === 1 ? activeUnits[0] : null;

  const displayPrice = product.selling_price ?? singleUnit?.selling_price ?? 0;

  const handleQuickAdd = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (!singleUnit) return;

    addItem({
      productId: product.id,
      productUnitId: singleUnit.id,
      productName: product.product_name,
      unitName: singleUnit.unit_name || singleUnit.unit_symbol || 'وحدة',
      displayedPrice: singleUnit.selling_price,
      image: product.primary_image,
    });
  };

  return (
    <div className="group relative flex flex-col bg-white rounded-2xl border border-slate-200/80 shadow-[0_1px_3px_rgba(15,23,42,0.03)] hover:shadow-[0_10px_25px_-5px_rgba(15,23,42,0.08),0_4px_10px_-2px_rgba(13,148,136,0.08)] hover:border-teal-500/50 hover:-translate-y-1 transition-all duration-200 overflow-hidden">
      {/* Product Image Box */}
      <Link
        href={`/store/${slug}/product/${product.id}`}
        className="relative block w-full aspect-square bg-slate-50/80 overflow-hidden"
      >
        <ProductImage
          src={product.primary_image}
          alt={product.product_name}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300 ease-out"
        />

        {/* Category Pill Tag */}
        {product.category_name && (
          <span className="absolute top-2.5 right-2.5 bg-white/95 backdrop-blur-md text-[11px] font-bold text-slate-800 px-2.5 py-1 rounded-full shadow-xs border border-slate-100">
            {product.category_name}
          </span>
        )}

        {/* Stock / Authenticity Pill */}
        <span
          className="absolute bottom-2.5 right-2.5 inline-flex items-center gap-1 bg-white/95 backdrop-blur-xs text-[10px] font-bold text-teal-800 px-2 py-0.5 rounded-full shadow-xs border border-teal-100"
          title="منتج أصلي متوفر بالمخزون"
        >
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
          <span>متوفر فوراً</span>
        </span>
      </Link>

      {/* Details & Actions */}
      <div className="flex flex-col flex-1 p-3.5 sm:p-4 justify-between gap-3">
        <div>
          <Link href={`/store/${slug}/product/${product.id}`}>
            <h3 className="font-bold text-slate-900 text-sm sm:text-base leading-snug line-clamp-2 group-hover:text-teal-700 transition-colors">
              {product.product_name}
            </h3>
          </Link>

          {product.description && (
            <p className="mt-1 text-xs text-slate-500 line-clamp-1 leading-relaxed">
              {product.description}
            </p>
          )}
        </div>

        {/* Price & Action Row */}
        <div className="pt-2.5 border-t border-slate-100 flex items-center justify-between gap-2">
          <div className="flex flex-col">
            <span className="text-[10px] text-slate-400 font-medium">السعر</span>
            <span className="text-base sm:text-lg font-black text-slate-900 tracking-tight" dir="ltr">
              {formatCurrency(displayPrice)}
            </span>
          </div>

          {singleUnit ? (
            <button
              onClick={handleQuickAdd}
              type="button"
              className="inline-flex items-center justify-center py-2 px-3 sm:px-3.5 rounded-xl bg-teal-600 hover:bg-teal-700 active:scale-95 text-white text-xs font-bold transition shadow-xs cursor-pointer gap-1.5"
              title="إضافة سريعة إلى السلة"
              aria-label={`إضافة ${product.product_name} إلى السلة`}
            >
              <svg
                className="w-4 h-4 shrink-0"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.2} d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
              </svg>
              <span>أضف للسلة</span>
            </button>
          ) : (
            <Link
              href={`/store/${slug}/product/${product.id}`}
              className="inline-flex items-center text-xs font-bold text-teal-800 hover:text-teal-900 bg-teal-50 hover:bg-teal-100/90 border border-teal-200/60 px-3 py-1.5 rounded-xl transition"
            >
              عرض الخيارات ({activeUnits.length})
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}
