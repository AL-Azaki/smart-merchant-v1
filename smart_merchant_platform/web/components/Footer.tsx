'use client';

import React from 'react';
import type { StoreBootstrap } from '@/lib/types';
import { buildWhatsAppUrl } from '@/lib/utils';

interface FooterProps {
  store: StoreBootstrap;
}

export function Footer({ store }: FooterProps) {
  const storeTitle = store.display_name || store.business_name || 'المتجر الإلكتروني';
  const whatsappUrl = buildWhatsAppUrl(store.whatsapp || store.phone, storeTitle);

  return (
    <footer id="store-footer" className="mt-auto bg-slate-900 text-slate-300 text-sm border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 lg:py-16">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 lg:gap-12">
          {/* Store Info & Verification */}
          <div className="space-y-3.5">
            <div className="flex items-center gap-2.5">
              <span className="w-9 h-9 rounded-xl bg-teal-600 text-white flex items-center justify-center font-black text-base shadow-sm">
                {storeTitle.charAt(0)}
              </span>
              <div>
                <h3 className="font-black text-white text-base sm:text-lg">{storeTitle}</h3>
                <span className="text-[11px] text-teal-400 font-medium">المتجر الإلكتروني الرسمي المعتمد</span>
              </div>
            </div>

            {store.address_text && (
              <p className="text-slate-400 text-xs leading-relaxed flex items-center gap-1.5">
                <span>📍</span>
                <span>{store.address_text}</span>
              </p>
            )}

            <p className="text-xs text-slate-400 leading-relaxed">
              نوفر لعملائنا الكرام تجربة تسوق مباشرة وآمنة، مع التزامنا بأعلى معايير المصداقية وسرعة التوصيل وخدمة ما بعد البيع.
            </p>

            <div className="pt-1 flex items-center gap-2">
              <span className="inline-flex items-center gap-1 text-[11px] font-bold text-teal-300 bg-teal-950/90 border border-teal-800/80 px-3 py-1 rounded-full">
                <span>✓</span> متجر معتمد وموثق
              </span>
            </div>
          </div>

          {/* Contact Details & Direct WhatsApp */}
          <div className="space-y-3.5">
            <h4 className="font-black text-white text-sm">خدمة العملاء والتواصل المباشر</h4>
            <p className="text-xs text-slate-400">
              يسعدنا استقبال استفساراتك وطلباتك الخاصة يومياً طوال ساعات العمل.
            </p>

            <div className="space-y-2 text-xs text-slate-400">
              {store.phone && (
                <p className="flex items-center gap-2">
                  <span className="text-slate-500">رقم الهاتف:</span>
                  <a href={`tel:${store.phone}`} className="text-white hover:text-teal-400 font-bold" dir="ltr">
                    {store.phone}
                  </a>
                </p>
              )}

              {whatsappUrl && (
                <div className="pt-1">
                  <a
                    href={whatsappUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#25D366] hover:bg-[#20bd5a] text-white font-bold text-xs shadow-md transition active:scale-95"
                  >
                    <svg className="w-4 h-4 text-white shrink-0" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981z" />
                    </svg>
                    <span>محادثة فورية مع خدمة العملاء</span>
                  </a>
                </div>
              )}
            </div>
          </div>

          {/* Platform Trust & Guarantees */}
          <div className="space-y-3.5">
            <h4 className="font-black text-white text-sm">ضمان وموثوقية منصة التاجر الذكي</h4>
            <p className="text-xs text-slate-400 leading-relaxed">
              هذا المتجر مدعوم رسمياً بمنظومة «التاجر الذكي» لإدارة نقاط البيع والمخازن السحابية. نضمن لك دقة الأسعار وتوفر المنتجات بالمخزون وسلامة إجراءات التسليم.
            </p>
            <div className="pt-1 flex items-center gap-3 text-xs text-slate-400">
              <span className="flex items-center gap-1 text-teal-400 font-semibold">
                <span>🛡️</span> فحص ومعاينة
              </span>
              <span>•</span>
              <span className="flex items-center gap-1 text-teal-400 font-semibold">
                <span>💵</span> دفع عند الاستلام
              </span>
              <span>•</span>
              <span className="flex items-center gap-1 text-teal-400 font-semibold">
                <span>⚡</span> توصيل سريع
              </span>
            </div>
          </div>
        </div>

        <div className="mt-12 pt-6 border-t border-slate-800 text-center text-xs text-slate-500">
          © {new Date().getFullYear()} {storeTitle}. جميع الحقوق محفوظة • مدعوم تقنياً عبر منصة التاجر الذكي (Smart Merchant ERP).
        </div>
      </div>
    </footer>
  );
}
