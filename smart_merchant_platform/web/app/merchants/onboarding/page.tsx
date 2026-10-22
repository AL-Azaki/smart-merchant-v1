'use client';

import React from 'react';
import Link from 'next/link';
import { MarketplaceNavbar } from '@/components/MarketplaceNavbar';
import { MarketplaceFooter } from '@/components/MarketplaceFooter';
import { MarketplaceProvider, useMarketplace } from '@/lib/marketplace-context';

function MerchantOnboardingContent() {
  const { isAr } = useMarketplace();

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 font-sans transition-colors duration-200">
      <MarketplaceNavbar />

      {/* Breadcrumb Navigation Bar */}
      <div className="bg-white/80 dark:bg-slate-900/80 border-b border-slate-200/60 dark:border-slate-800/80 py-2.5 px-3 sm:px-6 lg:px-8 text-xs font-semibold backdrop-blur-sm">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400">
            <Link href="/" className="hover:text-teal-600 dark:hover:text-teal-400 flex items-center gap-1 transition">
              <span>🏠</span>
              <span>{isAr ? 'الرئيسية' : 'Home'}</span>
            </Link>
            <span>/</span>
            <span className="text-teal-600 dark:text-teal-400 font-bold">
              {isAr ? 'بوابة التجار ورواد الأعمال' : 'Merchant Onboarding Portal'}
            </span>
          </div>

          <div className="flex items-center gap-3">
            <Link
              href="/#explore-products"
              className="text-slate-600 dark:text-slate-300 hover:text-teal-600 dark:hover:text-teal-400 font-bold text-xs transition hidden sm:inline-flex items-center gap-1"
            >
              <span>🏷️</span>
              <span>{isAr ? 'استعراض المنتجات' : 'Explore Products'}</span>
            </Link>
            <span className="text-slate-300 dark:text-slate-700 hidden sm:inline">|</span>
            <Link
              href="/"
              className="inline-flex items-center gap-1.5 text-teal-600 dark:text-teal-400 hover:text-teal-700 dark:hover:text-teal-300 font-bold text-xs transition"
            >
              <span>{isAr ? '← العودة إلى الرئيسية' : '← Back to Home'}</span>
            </Link>
          </div>
        </div>
      </div>

      <main className="flex-1">
        {/* Hero Section */}
        <section className="relative overflow-hidden bg-gradient-to-b from-slate-900 via-slate-800 to-slate-900 text-white py-12 sm:py-16 lg:py-24">
          <div className="absolute top-0 right-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl pointer-events-none"></div>
          <div className="absolute bottom-0 left-1/4 w-96 h-96 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none"></div>

          <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 text-center space-y-4 sm:space-y-6">
            <span className="inline-flex items-center gap-2 px-3.5 sm:px-4 py-1.5 rounded-full bg-teal-500/20 text-teal-300 text-[11px] sm:text-xs font-black border border-teal-500/30">
              <span>🚀</span>
              <span>{isAr ? 'بوابة تجار منصة تاجركم (Tajer)' : 'Tajer Merchant Portal'}</span>
            </span>

            <h1 className="text-2xl sm:text-4xl lg:text-5xl xl:text-6xl font-black tracking-tight leading-tight sm:leading-tight">
              {isAr ? 'امتلك متجرك الإلكتروني المرتبط بنقاط البيع' : 'Launch Your POS-Linked Online Store'} <br />
              <span className="bg-gradient-to-r from-teal-400 via-teal-200 to-indigo-300 bg-clip-text text-transparent">
                {isAr ? 'في 3 خطوات بسيطة ومباشرة!' : 'In 3 Simple & Direct Steps!'}
              </span>
            </h1>

            <p className="text-slate-300 text-xs sm:text-sm lg:text-base leading-relaxed max-w-2xl mx-auto px-2">
              {isAr
                ? 'مع منصة تاجركم (Tajer) ونظام التاجر الذكي (Smart Merchant ERP)، لا تحتاج لمواقع معقدة أو شركات برمجة. تطبيق الكاشير في هاتفك يولد لك متجرك الإلكتروني ويربط مخزونك تلقائياً وبدون أي وسيط وبعمولة 0%.'
                : 'With Tajer Platform & Smart Merchant ERP, no complex development is needed. Your mobile POS generates your online store, syncs inventory automatically, with 0% commissions and zero middlemen.'}
            </p>

            <div className="pt-3 sm:pt-4 flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4">
              <a
                href="#download-app"
                className="w-full sm:w-auto px-6 sm:px-8 py-3.5 sm:py-4 bg-gradient-to-r from-teal-500 to-teal-600 hover:from-teal-600 hover:to-teal-700 text-slate-950 font-black text-xs sm:text-sm rounded-xl sm:rounded-2xl shadow-xl shadow-teal-500/20 transition active:scale-95 flex items-center justify-center gap-2"
              >
                <span>📲</span>
                <span>{isAr ? 'تحميل تطبيق التاجر الذكي (APK)' : 'Download Smart Merchant App (APK)'}</span>
              </a>

              <Link
                href="/#explore-products"
                className="w-full sm:w-auto px-6 sm:px-8 py-3.5 sm:py-4 bg-slate-800/90 hover:bg-slate-700 text-teal-300 font-bold text-xs sm:text-sm rounded-xl sm:rounded-2xl border border-slate-700 transition flex items-center justify-center gap-2"
              >
                <span>🏷️</span>
                <span>{isAr ? 'استعراض منتجات ومتاجر السوق' : 'Explore Market & Products'}</span>
              </Link>

              <Link
                href="/"
                className="w-full sm:w-auto px-6 sm:px-8 py-3.5 sm:py-4 bg-teal-950/60 hover:bg-teal-900/60 text-white font-bold text-xs sm:text-sm rounded-xl sm:rounded-2xl border border-teal-500/40 transition flex items-center justify-center gap-2"
              >
                <span>🏠</span>
                <span>{isAr ? 'العودة للرئيسية' : 'Return to Home'}</span>
              </Link>

              <a
                href={isAr ? "https://wa.me/?text=مرحباً،+أريد+الاستفسار+عن+الانضمام+كمتجر+في+منصة+تاجركم" : "https://wa.me/?text=Hello,+I+want+to+inquire+about+joining+Tajer+as+a+merchant"}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto px-6 sm:px-8 py-3.5 sm:py-4 bg-slate-900/80 hover:bg-slate-800 text-white font-bold text-xs sm:text-sm rounded-xl sm:rounded-2xl border border-slate-800 transition flex items-center justify-center gap-2"
              >
                <span>💬</span>
                <span>{isAr ? 'تواصل مع المبيعات' : 'Chat with Sales'}</span>
              </a>
            </div>
          </div>
        </section>

        {/* 3 Simple Steps */}
        <section className="py-12 sm:py-16 bg-white dark:bg-slate-900 border-b border-slate-200/80 dark:border-slate-800 transition-colors">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-14 space-y-2">
              <h2 className="text-xl sm:text-3xl font-black text-slate-900 dark:text-white">
                {isAr ? 'كيف يعمل النظام؟ (خطوات سهلة جداً)' : 'How It Works (Super Easy Steps)'}
              </h2>
              <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400">
                {isAr ? 'من أول تحميل للتطبيق حتى إطلاق متجرك واستقبال طلبات الزبائن مباشرة.' : 'From first app installation to receiving live customer orders.'}
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8">
              {/* Step 1 */}
              <div className="bg-slate-50 dark:bg-slate-800/80 rounded-3xl p-6 sm:p-8 border border-slate-200/80 dark:border-slate-700 relative">
                <span className="w-12 h-12 rounded-2xl bg-teal-600 text-white font-black text-xl flex items-center justify-center mb-5 shadow-md shadow-teal-600/20">
                  1
                </span>
                <h3 className="text-base sm:text-lg font-black text-slate-900 dark:text-white mb-2">
                  {isAr ? 'حمّل التطبيق وسجل منشأتك' : 'Download App & Register Store'}
                </h3>
                <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                  {isAr
                    ? 'قم بتثبيت تطبيق التاجر الذكي على هاتفك أو جهاز الكاشير (Android)، ثم أنشئ حساب منشأتك وسجل بيانات نشاطك التجاري بكل سهولة.'
                    : 'Install Smart Merchant on your Android phone or POS terminal, create your account, and set up your business details in minutes.'}
                </p>
              </div>

              {/* Step 2 */}
              <div className="bg-slate-50 dark:bg-slate-800/80 rounded-3xl p-6 sm:p-8 border border-slate-200/80 dark:border-slate-700 relative">
                <span className="w-12 h-12 rounded-2xl bg-indigo-600 text-white font-black text-xl flex items-center justify-center mb-5 shadow-md shadow-indigo-600/20">
                  2
                </span>
                <h3 className="text-base sm:text-lg font-black text-slate-900 dark:text-white mb-2">
                  {isAr ? 'فعّل المتجر من الإعدادات' : 'Activate Storefront in Settings'}
                </h3>
                <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                  {isAr
                    ? 'من داخل التطبيق، توجه إلى الإعدادات ⬅️ المتجر الإلكتروني، اختر رابط متجرك المخصص واضغط تفعيل.'
                    : 'Inside the app, go to Settings ➔ Online Store, choose your custom store link slug, and hit Activate.'}
                </p>
              </div>

              {/* Step 3 */}
              <div className="bg-slate-50 dark:bg-slate-800/80 rounded-3xl p-6 sm:p-8 border border-slate-200/80 dark:border-slate-700 relative">
                <span className="w-12 h-12 rounded-2xl bg-emerald-600 text-white font-black text-xl flex items-center justify-center mb-5 shadow-md shadow-emerald-600/20">
                  3
                </span>
                <h3 className="text-base sm:text-lg font-black text-slate-900 dark:text-white mb-2">
                  {isAr ? 'استقبل الطلبات فوراً!' : 'Receive Orders Instantly!'}
                </h3>
                <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                  {isAr
                    ? 'يظهر متجرك تلقائياً في سوق تاجركم (Tajer) المركزي الموحد، ويصل زبائنك لرابطك المباشر. تظهر الطلبات الجديدة لحظياً داخل التطبيق في شاشة المبيعات!'
                    : 'Your store is automatically listed on Tajer Central Marketplace, and customers reach your direct link. Orders pop up instantly inside the app!'}
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Features Grid */}
        <section className="py-12 sm:py-16 bg-slate-50 dark:bg-slate-950 border-b border-slate-200/80 dark:border-slate-800 transition-colors">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-14 space-y-2">
              <span className="text-xs font-bold text-teal-600 dark:text-teal-400 bg-teal-50 dark:bg-teal-950/60 px-3 py-1 rounded-full border border-teal-200 dark:border-teal-800">
                {isAr ? 'مزايا حصرية للتجار' : 'Exclusive Merchant Features'}
              </span>
              <h2 className="text-xl sm:text-3xl font-black text-slate-900 dark:text-white">
                {isAr ? 'كل ما تحتاجه لإدارة وتنمية تجارتك' : 'Everything You Need to Scale Your Retail Business'}
              </h2>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
              <div className="bg-white dark:bg-slate-900 p-5 sm:p-6 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-xs space-y-2">
                <span className="text-2xl block">⚡</span>
                <h4 className="font-black text-sm text-slate-900 dark:text-white">
                  {isAr ? 'مزامنة المخزون التلقائية' : 'Instant Stock Sync'}
                </h4>
                <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                  {isAr ? 'أي منتج تبيعه في الكاشير ينقص من المتجر الإلكتروني فوراً، لمنع بيع منتجات غير متوفرة.' : 'Every POS sale immediately deducts from your online storefront stock.'}
                </p>
              </div>

              <div className="bg-white dark:bg-slate-900 p-5 sm:p-6 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-xs space-y-2">
                <span className="text-2xl block">💬</span>
                <h4 className="font-black text-sm text-slate-900 dark:text-white">
                  {isAr ? 'تأكيد فوري عبر واتساب' : 'Direct WhatsApp Orders'}
                </h4>
                <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                  {isAr ? 'يتلقى العميل تفاصيل طلبه بضغطة زر للتواصل معك مباشرة والتنسيق السريع للتوصيل.' : 'Customers confirm their cart in 1 tap for rapid dispatch and delivery.'}
                </p>
              </div>

              <div className="bg-white dark:bg-slate-900 p-5 sm:p-6 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-xs space-y-2">
                <span className="text-2xl block">📴</span>
                <h4 className="font-black text-sm text-slate-900 dark:text-white">
                  {isAr ? 'يعمل بدون إنترنت (Offline)' : 'Works Offline'}
                </h4>
                <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                  {isAr ? 'نظام الكاشير والمبيعات يعمل بكفاءة حتى عند انقطاع الإنترنت، ويتزامن تلقائياً عند عودته.' : 'POS sales run continuously even without internet and sync when back online.'}
                </p>
              </div>

              <div className="bg-white dark:bg-slate-900 p-5 sm:p-6 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-xs space-y-2">
                <span className="text-2xl block">📈</span>
                <h4 className="font-black text-sm text-slate-900 dark:text-white">
                  {isAr ? 'ظهور مجاني في السوق' : 'Free Marketplace Exposure'}
                </h4>
                <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                  {isAr ? 'متجرك ومنتجاتك تُعرض لآلاف المتسوقين في الصفحة الرئيسية للسوق المركزي الموحد مجاناً.' : 'Your store and catalog are highlighted to shoppers on the central hub at 0% fees.'}
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Download & Onboarding CTA */}
        <section id="download-app" className="py-12 sm:py-16 bg-white dark:bg-slate-900 transition-colors">
          <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-4 sm:space-y-6">
            <div className="w-14 h-14 sm:w-16 sm:h-16 rounded-2xl sm:rounded-3xl bg-teal-50 dark:bg-teal-950/60 border border-teal-200 dark:border-teal-800 text-teal-600 dark:text-teal-400 flex items-center justify-center text-2xl sm:text-3xl mx-auto">
              📲
            </div>

            <h2 className="text-xl sm:text-3xl lg:text-4xl font-black text-slate-900 dark:text-white">
              {isAr ? 'جاهز للانطلاق؟ حمّل التطبيق الآن مجاناً!' : 'Ready to Launch? Download Free Now!'}
            </h2>

            <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 max-w-xl mx-auto leading-relaxed">
              {isAr
                ? 'ابدأ تجربتك الآن وتمتع بكافة ميزات نقاط البيع، إدارة المستودعات، والمتجر الإلكتروني المتكامل بدون أي عمولات خفية.'
                : 'Start today and enjoy all POS, inventory, and storefront features without hidden fees.'}
            </p>

            <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4">
              <a
                href="/downloads/smart-merchant-latest.apk"
                className="w-full sm:w-auto px-6 sm:px-8 py-3.5 sm:py-4 bg-teal-600 hover:bg-teal-700 text-white font-black text-xs sm:text-sm rounded-xl sm:rounded-2xl shadow-lg shadow-teal-600/20 transition active:scale-95 flex items-center justify-center gap-2"
              >
                <span>📥</span>
                <span>{isAr ? 'تحميل مباشر لنظام أندرويد (APK)' : 'Direct Android APK Download'}</span>
              </a>

              <Link
                href="/store/bbg"
                className="w-full sm:w-auto px-6 sm:px-8 py-3.5 sm:py-4 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 font-bold text-xs sm:text-sm rounded-xl sm:rounded-2xl border border-slate-200 dark:border-slate-700 transition flex items-center justify-center gap-2"
              >
                <span>👀</span>
                <span>{isAr ? 'شاهد نموذج لمتجر حقيقي' : 'Preview a Live Store'}</span>
              </Link>

              <Link
                href="/#explore-products"
                className="w-full sm:w-auto px-6 sm:px-8 py-3.5 sm:py-4 bg-teal-600 hover:bg-teal-700 text-white font-black text-xs sm:text-sm rounded-xl sm:rounded-2xl shadow-lg shadow-teal-600/20 transition active:scale-95 flex items-center justify-center gap-2"
              >
                <span>🏷️</span>
                <span>{isAr ? 'استعراض منتجات السوق' : 'Explore Market Products'}</span>
              </Link>

              <Link
                href="/"
                className="w-full sm:w-auto px-6 sm:px-8 py-3.5 sm:py-4 bg-teal-50 dark:bg-teal-950/60 hover:bg-teal-100 dark:hover:bg-teal-900/60 text-teal-700 dark:text-teal-300 font-bold text-xs sm:text-sm rounded-xl sm:rounded-2xl border border-teal-200 dark:border-teal-800 transition flex items-center justify-center gap-2"
              >
                <span>🏠</span>
                <span>{isAr ? 'العودة للصفحة الرئيسية' : 'Return to Home Page'}</span>
              </Link>
            </div>
          </div>
        </section>
      </main>

      <MarketplaceFooter />
    </div>
  );
}

export default function MerchantOnboardingPage() {
  return (
    <MarketplaceProvider>
      <MerchantOnboardingContent />
    </MarketplaceProvider>
  );
}
