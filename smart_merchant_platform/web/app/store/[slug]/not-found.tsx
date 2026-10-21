import React from 'react';
import Link from 'next/link';

export default function StoreNotFound() {
  return (
    <div className="py-24 text-center bg-white rounded-3xl border border-gray-100 p-8 shadow-xs max-w-lg mx-auto">
      <div className="w-16 h-16 rounded-full bg-gray-100 text-gray-400 flex items-center justify-center mx-auto mb-4 text-2xl">
        🔍
      </div>
      <h2 className="text-xl font-bold text-gray-900 mb-2">المتجر غير موجود</h2>
      <p className="text-xs text-gray-500 mb-6 leading-relaxed">
        المتجر غير موجود أو الرابط غير صحيح.
      </p>
      <Link
        href="/"
        className="inline-block px-6 py-2.5 bg-gray-900 hover:bg-gray-800 text-white text-xs font-semibold rounded-xl transition"
      >
        العودة للرئيسية
      </Link>
    </div>
  );
}
