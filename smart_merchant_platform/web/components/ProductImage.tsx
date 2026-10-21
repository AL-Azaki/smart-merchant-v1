'use client';

import React, { useState } from 'react';
import { isValidImageUrl } from '@/lib/utils';

interface ProductImageProps {
  src: string | null | undefined;
  alt: string;
  className?: string;
  hasFallback?: boolean;
}

export function ProductImage({
  src,
  alt,
  className = 'w-full h-full object-cover',
  hasFallback = false,
}: ProductImageProps) {
  const [loadError, setLoadError] = useState(false);

  const isSafe = !hasFallback && !loadError && isValidImageUrl(src);

  if (!isSafe) {
    return (
      <div
        className={`flex flex-col items-center justify-center bg-gradient-to-b from-gray-50 to-gray-100/80 text-gray-400 select-none overflow-hidden ${className}`}
        aria-label={alt}
      >
        <svg
          className="w-10 h-10 mb-1.5 opacity-50 shrink-0"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          width="40"
          height="40"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={1.5}
            d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
          />
        </svg>
        <span className="text-[11px] font-medium text-gray-400">لا توجد صورة</span>
      </div>
    );
  }

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src!}
      alt={alt}
      className={className}
      onError={() => setLoadError(true)}
      loading="lazy"
    />
  );
}
