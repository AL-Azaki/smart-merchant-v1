import React from 'react';
import Link from 'next/link';

export default function GlobalNotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50/50 p-4">
      <div className="py-16 px-8 text-center bg-white rounded-3xl border border-gray-100 shadow-sm max-w-lg w-full">
        <div className="w-16 h-16 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center mx-auto mb-4 text-2xl font-bold">
          404
        </div>
        <h1 className="text-xl font-bold text-gray-900 mb-2">المتجر غير موجود</h1>
        <p className="text-xs text-gray-500 mb-6 leading-relaxed">
          المتجر غير موجود أو الرابط غير صحيح.
        </p>
        <Link
          href="/"
          className="inline-block px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-xl transition shadow-sm"
        >
          العودة للرئيسية
        </Link>
      </div>
    </div>
  );
}
