import React from 'react';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getCategories, getProducts, getStoreBootstrap, isApiError } from '@/lib/api';
import type { StoreCategory } from '@/lib/types';
import { ProductCard } from '@/components/ProductCard';
import { StoreFilters } from '@/components/StoreFilters';
import { buildWhatsAppUrl } from '@/lib/utils';

interface StoreHomePageProps {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{
    search?: string;
    category_id?: string;
    page?: string;
  }>;
}

export default async function StoreHomePage({
  params,
  searchParams,
}: StoreHomePageProps) {
  const { slug } = await params;
  const { search, category_id, page } = await searchParams;

  const currentPage = page ? parseInt(page, 10) : 1;

  // Parallel fetch store info, categories, and products
  let storeRes;
  let categoriesRes;
  let productsRes;
  try {
    [storeRes, categoriesRes, productsRes] = await Promise.all([
      getStoreBootstrap(slug).catch(() => null),
      getCategories(slug, { onlyWithProducts: true }).catch(() => ({ data: [] })),
      getProducts(slug, {
        search,
        category_id,
        page: currentPage,
        per_page: 12,
      }),
    ]);
  } catch (err: unknown) {
    if (isApiError(err) && err.status === 404) {
      notFound();
    }
    throw err;
  }

  const store = storeRes?.data;
  const categories = categoriesRes.data;
  const products = productsRes.data;
  const meta = productsRes.meta;

  const displayCategories: StoreCategory[] = categories.length > 0
    ? categories
    : (store?.categories?.map((cat) => ({
        id: cat,
        category_name: cat,
        category_code: null,
        description: null,
        parent_id: null,
      })) || []);

  const storeTitle = store?.display_name || store?.business_name || 'المتجر الإلكتروني';
  const whatsappUrl = store ? buildWhatsAppUrl(store.whatsapp || store.phone, storeTitle) : null;

  const buildPageUrl = (targetPage: number) => {
    const sp = new URLSearchParams();
    if (search) sp.set('search', search);
    if (category_id) sp.set('category_id', category_id);
    sp.set('page', String(targetPage));
    return `/store/${slug}?${sp.toString()}`;
  };

  return (
    <div className="space-y-6 sm:space-y-8">
      {/* Premium Store Hero Banner */}
      <section className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-teal-950 via-teal-900 to-slate-900 text-white p-6 sm:p-8 lg:p-10 shadow-xl shadow-teal-950/15">
        {/* Soft Ambient Illumination */}
        <div className="absolute top-0 right-0 w-80 h-80 rounded-full bg-teal-500/20 blur-3xl pointer-events-none"></div>
        <div className="absolute bottom-0 left-0 w-80 h-80 rounded-full bg-amber-500/15 blur-3xl pointer-events-none"></div>

        <div className="relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="space-y-3.5 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-teal-500/20 border border-teal-400/30 text-teal-200 text-xs font-bold backdrop-blur-md">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              <span>المتجر الرسمي المعتمد • منصة التاجر الذكي</span>
            </div>

            <h1 className="text-2xl sm:text-3xl lg:text-4xl font-black tracking-tight leading-tight">
              أهلاً بكم في متجر <span className="text-teal-300">{storeTitle}</span>
            </h1>

            <p className="text-slate-200 text-xs sm:text-sm leading-relaxed max-w-xl">
              وجهتكم الموثوقة للتسوق المباشر بأعلى معايير الجودة وأفضل الأسعار، مع ضمان المعاينة والدفع نقداً عند استلام طلبك.
            </p>

            {store?.address_text && (
              <p className="text-teal-200/90 text-xs flex items-center gap-1.5 font-medium">
                <span>📍</span>
                <span>{store.address_text}</span>
              </p>
            )}
          </div>

          {/* Quick Contact Box */}
          {whatsappUrl && (
            <div className="shrink-0 w-full sm:w-auto">
              <a
                href={whatsappUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 px-6 py-3.5 rounded-2xl bg-[#25D366] hover:bg-[#20bd5a] text-white font-black text-xs sm:text-sm shadow-lg shadow-emerald-950/20 transition active:scale-95"
              >
                <svg className="w-5 h-5 shrink-0" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981z" />
                </svg>
                <span>تحدث معنا عبر واتساب الآن</span>
              </a>
            </div>
          )}
        </div>

        {/* 4 Trust Value Pillars Strip */}
        <div className="mt-8 pt-6 border-t border-teal-800/60 grid grid-cols-2 md:grid-cols-4 gap-3 text-xs">
          <div className="flex items-center gap-2 text-teal-100">
            <span className="p-1.5 rounded-xl bg-teal-800/60 text-teal-300 text-sm">🛡️</span>
            <div>
              <strong className="block text-white font-bold">منتجات أصلية</strong>
              <span className="text-[11px] text-teal-200/80">مضمونة 100% من المتجر</span>
            </div>
          </div>

          <div className="flex items-center gap-2 text-teal-100">
            <span className="p-1.5 rounded-xl bg-teal-800/60 text-teal-300 text-sm">💵</span>
            <div>
              <strong className="block text-white font-bold">دفع عند الاستلام</strong>
              <span className="text-[11px] text-teal-200/80">عاين طلبك ثم ادفع نقداً</span>
            </div>
          </div>

          <div className="flex items-center gap-2 text-teal-100">
            <span className="p-1.5 rounded-xl bg-teal-800/60 text-teal-300 text-sm">🚚</span>
            <div>
              <strong className="block text-white font-bold">توصيل سريع وموثوق</strong>
              <span className="text-[11px] text-teal-200/80">تنسيق فوري للتسليم</span>
            </div>
          </div>

          <div className="flex items-center gap-2 text-teal-100">
            <span className="p-1.5 rounded-xl bg-teal-800/60 text-teal-300 text-sm">💬</span>
            <div>
              <strong className="block text-white font-bold">دعم وخدمة عملاء</strong>
              <span className="text-[11px] text-teal-200/80">متابعة فورية ومباشرة</span>
            </div>
          </div>
        </div>
      </section>

      {/* Filter and Search Bar */}
      <StoreFilters
        slug={slug}
        categories={displayCategories}
        currentCategoryId={category_id}
        currentSearch={search}
      />

      {/* Section Header */}
      <div className="flex items-center justify-between px-1">
        <div className="flex items-center gap-2">
          <span className="text-lg">✨</span>
          <h2 className="font-black text-slate-900 text-base sm:text-lg">
            {category_id ? 'المنتجات في هذا القسم' : search ? `نتائج البحث عن "${search}"` : 'أحدث المنتجات والعروض'}
          </h2>
          {meta && (
            <span className="text-xs font-bold text-slate-500 bg-slate-100 px-2.5 py-0.5 rounded-full">
              {meta.total} منتج
            </span>
          )}
        </div>

        {(category_id || search) && (
          <Link
            href={`/store/${slug}`}
            className="text-xs font-bold text-teal-700 hover:text-teal-800 hover:underline"
          >
            إعادة تعيين الفلاتر
          </Link>
        )}
      </div>

      {/* Products Grid or Empty State */}
      {products.length === 0 ? (
        <div className="py-20 text-center bg-white rounded-3xl border border-slate-200/80 p-8 shadow-xs">
          <div className="w-16 h-16 rounded-full bg-teal-50 text-teal-700 flex items-center justify-center mx-auto mb-4 text-2xl font-bold">
            🔍
          </div>
          <h3 className="text-lg font-bold text-slate-800 mb-1">لم نتمكن من العثور على نتائج مطابقة</h3>
          <p className="text-xs text-slate-500 max-w-sm mx-auto leading-relaxed">
            {search || category_id
              ? 'جرّب البحث بكلمات أخرى أو تصفح بقية الأقسام المتاحة بالمتجر.'
              : 'لم تتم إضافة أي منتجات منشورة للمتجر حتى الآن.'}
          </p>
          {(search || category_id) && (
            <Link
              href={`/store/${slug}`}
              className="inline-block mt-4 text-xs font-bold text-white bg-teal-600 hover:bg-teal-700 px-5 py-2.5 rounded-xl transition shadow-sm"
            >
              عرض جميع منتجات المتجر
            </Link>
          )}
        </div>
      ) : (
        <>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-6">
            {products.map((product) => (
              <ProductCard key={product.id} slug={slug} product={product} />
            ))}
          </div>

          {/* Pagination Controls */}
          {meta && meta.last_page > 1 && (
            <div className="mt-12 flex items-center justify-center gap-2">
              {meta.current_page > 1 && (
                <Link
                  href={buildPageUrl(meta.current_page - 1)}
                  className="px-4 py-2 rounded-xl text-xs font-bold bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 transition shadow-xs"
                >
                  الصفحة السابقة
                </Link>
              )}

              <span className="text-xs text-slate-500 px-3 font-semibold">
                صفحة {meta.current_page} من {meta.last_page}
              </span>

              {meta.current_page < meta.last_page && (
                <Link
                  href={buildPageUrl(meta.current_page + 1)}
                  className="px-4 py-2 rounded-xl text-xs font-bold bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 transition shadow-xs"
                >
                  الصفحة التالية
                </Link>
              )}
            </div>
          )}
        </>
      )}
    </div>
  );
}
