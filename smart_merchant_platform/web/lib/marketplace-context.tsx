'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';

export type MarketplaceLang = 'ar' | 'en';
export type MarketplaceTheme = 'light' | 'dark';

export const translations = {
  ar: {
    // Navbar
    nav_brand: 'تاجركم',
    nav_badge: 'السوق الموحد',
    nav_tagline: 'تسوق مباشر من تجار اليمن عبر واتساب',
    nav_top_strip: 'تسوق مباشرة من تجار اليمن بدون وسيط أو عمولات 0% • دفع عند الاستلام',
    nav_are_you_merchant: 'هل أنت تاجر؟',
    nav_home: 'الرئيسية',
    nav_back_to_market: 'تصفح السوق',
    nav_back_to_market_full: 'العودة للسوق',
    nav_open_store: 'فتح متجر',
    nav_open_store_full: 'فتح متجرك',
    nav_verified_merchants: 'شبكة تجار موثقة 100%',
    nav_explore_products: 'استعراض المنتجات',
    nav_merchants_directory: 'دليل المتاجر',
    nav_admin_portal: 'بوابة إدارة المنصة (للمسؤولين فقط)',
    onboarding_back_home: 'العودة إلى السوق الرئيسي (تاجركم)',
    
    // Hero
    hero_badge: 'منصة تاجركم (Tajer) • بوابة التسوق الذكي والمباشر في اليمن',
    hero_title_1: 'ابحث عن أي منتج، واعرف',
    hero_title_highlight: 'عند أي تاجر يتواجد وبأفضل سعر!',
    hero_subtitle: 'شبكة موحدة تربطك بمخازن ونقاط بيع التجار المحليين مباشرة. تسوق بضمان المعاينة والدفع نقداً عند الاستلام.',
    hero_search_placeholder: 'ابحث عن منتج، متجر، أو تصنيف...',
    hero_search_btn: 'بحث في السوق',
    hero_stat_merchants: 'متجر معتمد',
    hero_stat_products: 'منتج نشط',
    hero_stat_delivery: 'توصيل مباشر وموثوق',
    hero_all_categories: 'جميع التصنيفات',
    city_sanaa: 'صنعاء',
    city_aden: 'عدن',
    city_taiz: 'تعز',
    city_hadramout: 'حضرموت',
    city_hodeidah: 'الحديدة',
    city_ibb: 'إب',

    // Stories Bar
    stories_title: 'قصص المتاجر المباشرة (Live Stories)',
    stories_hint: 'اضغط على المتجر لمشاهدة العروض الحية وساعات العمل',
    story_verified: 'قصة متجر معتمد • نشط الآن',
    story_ready_products: 'المنتجات الجاهزة للطلب:',
    story_products_unit: 'منتج متاح',
    story_visit_btn: 'زيارة المتجر والتسوق الآن',

    // Featured Merchants
    merchants_badge: 'متاجر موثقة',
    merchants_title: 'أبرز المتاجر المعتمدة في منطقتك',
    merchants_sub: 'تصفح كتالوج كل تاجر مباشرة واطلب ما تحتاجه مع خيارات التوصيل السريع.',
    merchants_active_count: 'متاجر نشطة تستقبل الطلبات الآن',
    merchants_view_store: 'زيارة المتجر والتسوق',
    merchants_open_orders: 'مفتوح للطلبات',
    merchants_products_available: 'منتج متاح',
    merchants_default_type: 'متجر تجزئة معتمد',

    // Products Grid
    products_badge: 'منتجات السوق',
    products_title_default: 'أحدث المنتجات والعروض المتوفرة',
    products_title_search: 'نتائج البحث عن',
    products_sub: 'تسوق مباشرة من المتاجر مع معرفة السعر والمصدر بدقة وشفافية.',
    products_count: 'منتج متوفر',
    products_empty_title: 'لم يتم العثور على منتجات مطابقة',
    products_empty_sub: 'جرب البحث بكلمة أخرى أو تصفح المتاجر المعتمدة في القسم أعلاه.',
    products_view_buy: 'عرض والشراء',
    products_unavailable: 'غير متوفر حالياً',

    // Onboarding Banner
    banner_badge: 'انضم إلى شبكة تجار تاجركم (Tajer)',
    banner_title: 'هل تمتلك متجراً أو نقطة بيع؟',
    banner_title_highlight: 'افتح متجرك الإلكتروني في أقل من 5 دقائق!',
    banner_desc: 'اربط نظام الكاشير والمخازن بالسوق المركزي الموحد. استقبل طلبات زبائنك أونلاين بمزامنة فورية ودقيقة للمخزون بدون أي وسيط وبعمولة 0%.',
    banner_feat_slug: 'رابط خاص بمتجرك (Slug)',
    banner_feat_sync: 'مزامنة لحظية مع نظام ERP',
    banner_feat_whatsapp: 'استلام الطلبات عبر واتساب',
    banner_cta_open: 'فتح متجر جديد / دليل الانضمام',
    banner_cta_support: 'تحدث مع فريق الدعم',

    // Footer
    footer_brand_title: 'منصة تاجركم (Tajer)',
    footer_brand_sub: 'السوق الموحد للمتاجر المستقلة في اليمن',
    footer_brand_desc: 'المنصة اليمنية الرائدة للتسوق المباشر من المتاجر المحلية بدون أي وسيط وبعمولة 0%. مدعومة بنظام «التاجر الذكي ERP» لإدارة نقاط البيع والمخازن السحابية والمزامنة اللحظية.',
    footer_badge_verified: 'شبكة متاجر موثقة',
    footer_badge_cod: 'دفع عند الاستلام',
    footer_badge_whatsapp: 'دعم واتساب مباشر',
    footer_shoppers_title: 'روابط المتسوقين',
    footer_link_products: 'تصفح المنتجات والعروض',
    footer_link_merchants: 'دليل المتاجر المعتمدة',
    footer_link_categories: 'التصنيفات والماركات',
    footer_link_search: 'محرك البحث الذكي',
    footer_merchants_title: 'خدمات وحلول التجار',
    footer_merchants_desc: 'اربط فرعك ومخزنك بمتجر إلكتروني احترافي يستقبل الطلبات تلقائياً.',
    footer_merchants_btn: 'دليل التاجر وتحميل التطبيق',
    footer_rights: 'منصة تاجركم (Tajer Marketplace) • مدعومة بتقنية التاجر الذكي (Smart Merchant ERP). جميع الحقوق محفوظة.',
    footer_made_in: 'صُنع بشغف واحترافية للتجارة الحديثة 🇾🇪',

    // States & Common
    loading: 'جاري تحميل بيانات السوق المركزي...',
    error_loading: 'تعذر تحميل بيانات السوق المركزي. يرجى التأكد من تشغيل السيرفر والمحاولة مجدداً.',
    retry: 'إعادة المحاولة',
  },
  en: {
    // Navbar
    nav_brand: 'Tajer',
    nav_badge: 'Central Market',
    nav_tagline: 'Direct local merchant shopping in Yemen via WhatsApp',
    nav_top_strip: 'Shop directly from local Yemen merchants with 0% fees • Cash on Delivery',
    nav_are_you_merchant: 'Are you a merchant?',
    nav_home: 'Home',
    nav_back_to_market: 'Browse Market',
    nav_back_to_market_full: 'Back to Market',
    nav_open_store: 'Open Store',
    nav_open_store_full: 'Open Your Store',
    nav_verified_merchants: '100% Verified Merchants',
    nav_explore_products: 'Explore Products',
    nav_merchants_directory: 'Stores Directory',
    nav_admin_portal: 'Platform Admin Portal (Admins Only)',
    onboarding_back_home: 'Back to Central Marketplace (Tajer)',

    // Hero
    hero_badge: 'Tajer Platform • Direct & Smart Shopping Portal in Yemen',
    hero_title_1: 'Find any product, and know',
    hero_title_highlight: 'Which merchant has it at the best price!',
    hero_subtitle: 'A unified network connecting you directly to local merchants\' inventory & stores. Shop with inspection guarantee and Cash on Delivery.',
    hero_search_placeholder: 'Search for a product, store, or category...',
    hero_search_btn: 'Search Market',
    hero_stat_merchants: 'Verified Stores',
    hero_stat_products: 'Active Products',
    hero_stat_delivery: 'Direct & Reliable Delivery',
    hero_all_categories: 'All Categories',
    city_sanaa: 'Sanaa',
    city_aden: 'Aden',
    city_taiz: 'Taiz',
    city_hadramout: 'Hadramout',
    city_hodeidah: 'Hodeidah',
    city_ibb: 'Ibb',

    // Stories Bar
    stories_title: 'Live Store Stories',
    stories_hint: 'Click a store to view live offers and opening hours',
    story_verified: 'Verified Store Story • Active Now',
    story_ready_products: 'Products ready to order:',
    story_products_unit: 'products available',
    story_visit_btn: 'Visit Store & Shop Now',

    // Featured Merchants
    merchants_badge: 'Verified Stores',
    merchants_title: 'Top Verified Stores in Your Area',
    merchants_sub: 'Browse each merchant\'s catalog directly and order with fast delivery.',
    merchants_active_count: 'Active stores taking orders now',
    merchants_view_store: 'Visit Store & Shop',
    merchants_open_orders: 'Open for Orders',
    merchants_products_available: 'products available',
    merchants_default_type: 'Verified Retail Store',

    // Products Grid
    products_badge: 'Market Products',
    products_title_default: 'Latest Products & Available Offers',
    products_title_search: 'Search results for',
    products_sub: 'Shop directly from stores with clear and transparent pricing.',
    products_count: 'products available',
    products_empty_title: 'No matching products found',
    products_empty_sub: 'Try searching with another keyword or explore verified stores above.',
    products_view_buy: 'View & Buy',
    products_unavailable: 'Currently Unavailable',

    // Onboarding Banner
    banner_badge: 'Join Tajer Merchants Network',
    banner_title: 'Do you own a shop or retail store?',
    banner_title_highlight: 'Launch your online store in under 5 minutes!',
    banner_desc: 'Link your POS and inventory to the central marketplace. Receive customer orders online with real-time stock sync, 0% commissions, and zero middlemen.',
    banner_feat_slug: 'Dedicated store link (Slug)',
    banner_feat_sync: 'Instant ERP inventory sync',
    banner_feat_whatsapp: 'Receive orders via WhatsApp',
    banner_cta_open: 'Open New Store / Onboarding Guide',
    banner_cta_support: 'Chat with Support Team',

    // Footer
    footer_brand_title: 'Tajer Platform',
    footer_brand_sub: 'Unified Marketplace for Independent Stores in Yemen',
    footer_brand_desc: 'The leading Yemeni platform for direct shopping from local merchants with 0% commissions. Powered by Smart Merchant ERP for cloud inventory, POS, and instant synchronization.',
    footer_badge_verified: 'Verified Stores Network',
    footer_badge_cod: 'Cash on Delivery',
    footer_badge_whatsapp: 'Direct WhatsApp Support',
    footer_shoppers_title: 'Shopper Links',
    footer_link_products: 'Browse Products & Deals',
    footer_link_merchants: 'Verified Stores Directory',
    footer_link_categories: 'Categories & Brands',
    footer_link_search: 'Smart Search Engine',
    footer_merchants_title: 'Merchant Solutions',
    footer_merchants_desc: 'Connect your store and warehouse to a professional online storefront taking orders 24/7.',
    footer_merchants_btn: 'Merchant Guide & App Download',
    footer_rights: 'Tajer Marketplace • Powered by Smart Merchant ERP. All rights reserved.',
    footer_made_in: 'Built with passion for modern commerce 🇾🇪',

    // States & Common
    loading: 'Loading central marketplace data...',
    error_loading: 'Failed to load central marketplace data. Please ensure the server is running and try again.',
    retry: 'Retry',
  },
} as const;

export type TranslationKey = keyof typeof translations.ar;

interface MarketplaceContextType {
  lang: MarketplaceLang;
  theme: MarketplaceTheme;
  isAr: boolean;
  toggleLang: () => void;
  toggleTheme: () => void;
  t: (key: TranslationKey) => string;
}

const MarketplaceContext = createContext<MarketplaceContextType | null>(null);

export function MarketplaceProvider({ children }: { children: React.ReactNode }) {
  const [lang, setLang] = useState<MarketplaceLang>('ar');
  const [theme, setTheme] = useState<MarketplaceTheme>('light');

  useEffect(() => {
    // 1. Theme sync
    const savedTheme = localStorage.getItem('tajer_theme') as MarketplaceTheme | null;
    if (savedTheme) {
      setTheme(savedTheme);
      if (savedTheme === 'dark') {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    }

    // 2. Lang sync
    const savedLang = localStorage.getItem('tajer_lang') as MarketplaceLang | null;
    if (savedLang) {
      setLang(savedLang);
      document.documentElement.dir = savedLang === 'ar' ? 'rtl' : 'ltr';
      document.documentElement.lang = savedLang;
    }
  }, []);

  const toggleTheme = () => {
    const nextTheme: MarketplaceTheme = theme === 'dark' ? 'light' : 'dark';
    setTheme(nextTheme);
    localStorage.setItem('tajer_theme', nextTheme);
    if (nextTheme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  const toggleLang = () => {
    const nextLang: MarketplaceLang = lang === 'ar' ? 'en' : 'ar';
    setLang(nextLang);
    localStorage.setItem('tajer_lang', nextLang);
    document.documentElement.dir = nextLang === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.lang = nextLang;
  };

  const isAr = lang === 'ar';

  const t = (key: TranslationKey): string => {
    const dict = translations[lang] || translations.ar;
    return (dict as Record<string, string>)[key] || (translations.ar as Record<string, string>)[key] || key;
  };

  return (
    <MarketplaceContext.Provider
      value={{
        lang,
        theme,
        isAr,
        toggleLang,
        toggleTheme,
        t,
      }}
    >
      {children}
    </MarketplaceContext.Provider>
  );
}

export function useMarketplace(): MarketplaceContextType {
  const ctx = useContext(MarketplaceContext);
  if (!ctx) {
    return {
      lang: 'ar',
      theme: 'light',
      isAr: true,
      toggleLang: () => {},
      toggleTheme: () => {},
      t: (key: TranslationKey) => (translations.ar as Record<string, string>)[key] || key,
    };
  }
  return ctx;
}
