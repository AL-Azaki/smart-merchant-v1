'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function HomePage() {
  const [slug, setSlug] = useState('integration-test-store');
  const router = useRouter();

  const handleOpenStore = (e: React.FormEvent) => {
    e.preventDefault();
    const cleanSlug = slug.trim();
    if (cleanSlug) {
      router.push(`/store/${cleanSlug}`);
    }
  };

  return (
    <div className="flex flex-col flex-1 items-center justify-center p-6 text-center min-h-[80vh]">
      <div className="max-w-md w-full bg-white p-8 rounded-3xl border border-gray-100 shadow-xl shadow-gray-200/50">
        <div className="w-16 h-16 rounded-2xl bg-gradient-to-tr from-blue-700 to-blue-500 text-white flex items-center justify-center mx-auto mb-4 text-2xl font-bold shadow-md shadow-blue-500/20">
          🏪
        </div>
        
        <h1 className="text-2xl font-extrabold text-gray-900 mb-1">منصة التاجر الذكي</h1>
        <h2 className="text-base font-semibold text-blue-600 mb-3">بوابة المتاجر الإلكترونية</h2>
        
        <p className="text-gray-500 text-sm mb-6 leading-relaxed">
          منظومة متكاملة لربط نقاط البيع والمخازن بمتاجر العملاء الرقمية ومزامنة الطلبات لحظياً.
        </p>

        <form onSubmit={handleOpenStore} className="space-y-4 mb-6">
          <div className="text-right">
            <label htmlFor="store-slug" className="block text-xs font-medium text-gray-700 mb-1.5">
              معرّف المتجر (Slug):
            </label>
            <input
              id="store-slug"
              type="text"
              value={slug}
              onChange={(e) => setSlug(e.target.value)}
              placeholder="مثال: integration-test-store"
              className="w-full px-4 py-3 border border-gray-200 rounded-xl text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
              dir="ltr"
            />
          </div>

          <button
            type="submit"
            className="w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 text-white font-medium text-sm rounded-xl shadow-md shadow-blue-600/20 hover:shadow-lg transition-all active:scale-[0.99]"
          >
            فتح المتجر
          </button>
        </form>

        <div className="bg-gray-50 border border-gray-100 rounded-2xl p-3 text-xs text-gray-500 mb-4">
          <span className="block text-gray-400 mb-1">مثال للرابط المباشر:</span>
          <span className="font-mono text-blue-600 font-medium" dir="ltr">/store/{slug || 'store-name'}</span>
        </div>

        <div className="pt-2 border-t border-gray-100 flex items-center justify-center gap-3 text-xs">
          <a
            href="/admin/login"
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg font-medium transition"
          >
            <span>🔐</span>
            <span>لوحة تحكم المسؤول (Admin Dashboard)</span>
          </a>
        </div>
      </div>
    </div>
  );
}
