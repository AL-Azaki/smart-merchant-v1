'use client';

import React, { useEffect } from 'react';

export default function StoreError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log non-sensitive error info
    console.error('Store error occurred:', error.message);
  }, [error]);

  const isNetwork =
    error.message?.includes('الاتصال') ||
    error.message?.includes('network') ||
    error.message?.includes('fetch failed');

  return (
    <div className="py-20 text-center bg-white rounded-3xl border border-red-100 p-8 shadow-xs max-w-lg mx-auto">
      <div className="w-16 h-16 rounded-full bg-red-50 text-red-500 flex items-center justify-center mx-auto mb-4 text-2xl">
        {isNetwork ? '📡' : '⚠️'}
      </div>
      <h2 className="text-lg font-bold text-gray-900 mb-2">
        {isNetwork ? 'تعذر الاتصال بالخادم' : 'عذراً، حدث خطأ ما'}
      </h2>
      <p className="text-xs text-gray-500 mb-6 leading-relaxed">
        {isNetwork
          ? 'تعذر الاتصال بخادم المتجر. تحقق من الاتصال بالشبكة وحاول مجدداً.'
          : 'حدث خطأ غير متوقع أثناء تحميل البيانات. يرجى إعادة المحاولة.'}
      </p>
      <button
        type="button"
        onClick={() => reset()}
        className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-xl transition cursor-pointer shadow-sm"
      >
        إعادة المحاولة
      </button>
    </div>
  );
}
