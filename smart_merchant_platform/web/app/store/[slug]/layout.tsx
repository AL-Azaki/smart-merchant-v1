import React from 'react';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getStoreBootstrap } from '@/lib/api';
import { STOREFRONT_URL } from '@/lib/config';
import { CartProvider } from '@/lib/cart-context';
import { Navbar } from '@/components/Navbar';
import { Footer } from '@/components/Footer';
import { ClosedStoreBanner } from '@/components/ClosedStoreBanner';
import { MobileBottomNav } from '@/components/MobileBottomNav';

interface StoreLayoutProps {
  children: React.ReactNode;
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  try {
    const { data: store } = await getStoreBootstrap(slug);
    const title = store.display_name || store.business_name || 'المتجر الإلكتروني';
    const description = store.address_text
      ? `تسوق من ${title} - ${store.address_text}`
      : `تسوق أونلاين من ${title}`;

    const canonicalUrl = `${STOREFRONT_URL}/store/${slug}`;

    return {
      title: `${title} | المتجر الإلكتروني`,
      description,
      alternates: {
        canonical: canonicalUrl,
      },
      openGraph: {
        title,
        description,
        url: canonicalUrl,
        siteName: title,
        type: 'website',
        locale: 'ar_SA',
      },
    };
  } catch {
    return {
      title: 'متجر إلكتروني',
      description: 'متجر إلكتروني عبر منصة التاجر الذكي',
    };
  }
}

export default async function StoreLayout({ children, params }: StoreLayoutProps) {
  const { slug } = await params;

  let store;
  try {
    const res = await getStoreBootstrap(slug);
    store = res.data;
  } catch (err: unknown) {
    if (typeof err === 'object' && err !== null && 'status' in err && (err as { status: number }).status === 404) {
      notFound();
    }
    throw err;
  }

  if (!store.storefront_active) {
    return (
      <div className="min-h-screen flex flex-col bg-[#F8FAFC]">
        <Navbar slug={slug} store={store} />
        <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <ClosedStoreBanner store={store} />
        </main>
        <Footer store={store} />
      </div>
    );
  }

  return (
    <CartProvider slug={slug}>
      <div className="min-h-screen flex flex-col bg-[#F8FAFC]">
        <Navbar slug={slug} store={store} />
        <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 pb-24 md:pb-8">
          {children}
        </main>
        <Footer store={store} />
        <MobileBottomNav slug={slug} store={store} />
      </div>
    </CartProvider>
  );
}
