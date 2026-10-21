import React from 'react';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getProductDetail } from '@/lib/api';
import { STOREFRONT_URL } from '@/lib/config';
import { ProductDetailView } from '@/components/ProductDetailView';

interface ProductPageProps {
  params: Promise<{
    slug: string;
    productId: string;
  }>;
}

export async function generateMetadata({
  params,
}: ProductPageProps): Promise<Metadata> {
  const { slug, productId } = await params;
  try {
    const res = await getProductDetail(slug, productId);
    const product = res.data;
    const title = product.product_name;
    const description = product.description || `اشتري ${product.product_name} أونلاين`;
    const canonical = `${STOREFRONT_URL}/store/${slug}/product/${productId}`;

    return {
      title,
      description,
      alternates: {
        canonical,
      },
      openGraph: {
        title,
        description,
        url: canonical,
        type: 'article',
      },
    };
  } catch {
    return {
      title: 'تفاصيل المنتج',
    };
  }
}

export default async function ProductDetailPage({ params }: ProductPageProps) {
  const { slug, productId } = await params;

  let product;
  try {
    const res = await getProductDetail(slug, productId);
    product = res.data;
  } catch (err: unknown) {
    if (
      typeof err === 'object' &&
      err !== null &&
      'status' in err &&
      (err as { status: number }).status === 404
    ) {
      notFound();
    }
    throw err;
  }

  return <ProductDetailView slug={slug} product={product} />;
}
