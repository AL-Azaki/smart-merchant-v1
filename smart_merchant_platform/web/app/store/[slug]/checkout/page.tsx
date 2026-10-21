'use client';

import React, { useState, useRef } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useCart } from '@/lib/cart-context';
import { createOrder, isApiError } from '@/lib/api';
import { formatCurrency } from '@/lib/utils';
import type { CreateOrderPayload } from '@/lib/types';

export default function CheckoutPage() {
  const params = useParams();
  const slug = params.slug as string;
  const router = useRouter();

  const { items, estimatedTotal, clearCart, isLoaded } = useCart();

  // Form State
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [customerEmail, setCustomerEmail] = useState('');
  const [shippingAddress, setShippingAddress] = useState('');
  const [shippingCity, setShippingCity] = useState('');
  const [customerNotes, setCustomerNotes] = useState('');

  // Status & Validation
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string[]>>({});

  // Idempotency Key: preserved across retries for the same order attempt
  const idempotencyKeyRef = useRef<string | null>(null);

  if (!isLoaded) {
    return (
      <div className="py-20 text-center text-slate-400 text-sm animate-pulse">
        جاري تجهيز شاشة إتمام الطلب...
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="py-20 text-center bg-white rounded-3xl border border-slate-200/80 p-8 shadow-xs max-w-lg mx-auto">
        <div className="w-16 h-16 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center mx-auto mb-4 text-2xl font-bold">
          ⚠️
        </div>
        <h1 className="text-xl font-black text-slate-900 mb-2">سلة المشتريات فارغة</h1>
        <p className="text-xs text-slate-500 mb-6 leading-relaxed">
          لا يمكن المتابعة وسلة مشترياتك لا تحتوي على أي منتجات بعد.
        </p>
        <Link
          href={`/store/${slug}`}
          className="inline-block px-6 py-3 bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold rounded-2xl transition shadow-md shadow-teal-600/20 cursor-pointer"
        >
          العودة لتصفح منتجات المتجر
        </Link>
      </div>
    );
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isSubmitting) return;

    // Reset error state
    setServerError(null);
    setFieldErrors({});

    // Client-side quick validation
    const errors: Record<string, string[]> = {};
    if (!customerName.trim()) {
      errors.customer_name = ['يرجى كتابة الاسم الكريم'];
    }
    if (!customerPhone.trim()) {
      errors.customer_phone = ['يرجى كتابة رقم الهاتف لتنسيق التوصيل'];
    }
    if (!shippingAddress.trim()) {
      errors.shipping_address = ['يرجى تحديد عنوان التوصيل'];
    }

    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      return;
    }

    // Ensure idempotency key exists for this attempt
    if (!idempotencyKeyRef.current) {
      idempotencyKeyRef.current = typeof crypto !== 'undefined' && crypto.randomUUID
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random().toString(36).substring(2, 15)}`;
    }

    // Payload: STRICTLY NO PRICES SENT! Server is the single source of truth for pricing.
    const payload: CreateOrderPayload = {
      customer_name: customerName.trim(),
      customer_phone: customerPhone.trim(),
      customer_email: customerEmail.trim() || undefined,
      shipping_address: shippingAddress.trim() || undefined,
      shipping_city: shippingCity.trim() || undefined,
      customer_notes: customerNotes.trim() || undefined,
      items: items.map((i) => ({
        product_id: i.productId,
        product_unit_id: i.productUnitId,
        quantity: i.quantity,
      })),
      idempotency_key: idempotencyKeyRef.current,
    };

    setIsSubmitting(true);

    try {
      const response = await createOrder(slug, payload);
      const order = response.data;

      // Safe temporary storage for order success display
      try {
        sessionStorage.setItem(
          `smart-merchant-order-success:${order.order_number}`,
          JSON.stringify({
            orderNumber: order.order_number,
            grandTotal: order.grand_total,
            date: order.order_date,
            customerName: customerName.trim(),
            slug,
          }),
        );
      } catch {
        // ignore sessionStorage error
      }

      // ONLY clear cart after verified success response from Laravel
      clearCart();

      // Navigate to order success page
      router.push(`/store/${slug}/order-success/${order.order_number}`);
    } catch (err: unknown) {
      setIsSubmitting(false);

      if (isApiError(err)) {
        if (err.code === 'PRODUCT_UNIT_UNAVAILABLE') {
          if (err.validationErrors) {
            setFieldErrors(err.validationErrors);
          }
          setServerError(err.message || 'أحد المنتجات في السلة لم يعد متاحًا للشراء حالياً.');
        } else if (err.isValidation && err.validationErrors) {
          setFieldErrors(err.validationErrors);
          setServerError(err.message || 'يرجى مراجعة وتصحيح الحقول الموضحة أدناه');
        } else if (err.status === 403) {
          setServerError('المتجر مغلق حالياً ولا يستقبل طلبات جديدة في الوقت الراهن.');
        } else if (err.status === 404) {
          setServerError('أحد المنتجات المطلوبة لم يعد متوفراً في المتجر.');
        } else if (err.status === 409) {
          setServerError('تم إرسال هذا الطلب مسبقاً بنجاح.');
        } else if (err.status === 429) {
          setServerError('تم إرسال عدد كبير من الطلبات. يرجى الانتظار قليلاً والمحاولة مجدداً.');
        } else {
          setServerError(err.message || 'حدث خطأ غير متوقع أثناء إرسال الطلب.');
        }
      } else {
        setServerError('تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت ثم إعادة المحاولة.');
      }
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <Link
          href={`/store/${slug}/cart`}
          className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-teal-700 transition mb-3 group"
        >
          <span className="p-1 rounded-lg bg-slate-100 group-hover:bg-teal-50 text-slate-600 group-hover:text-teal-700 transition">
            <svg className="w-4 h-4 rotate-180" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.2} d="M14 5l7 7m0 0l-7 7m7-7H3" />
            </svg>
          </span>
          <span>العودة لمراجعة السلة</span>
        </Link>
        <h1 className="text-xl sm:text-2xl font-black text-slate-900">إتمام الطلب المباشر</h1>
        <p className="text-xs text-slate-500 mt-1">
          خطوة واحدة فقط: أدخل بيانات التوصيل وسيتولى فريق المتجر تجهيز طلبك وتسليمه لباب منزلك.
        </p>
      </div>

      {serverError && (
        <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-800 text-xs flex items-center justify-between gap-3 animate-in fade-in">
          <div className="flex items-center gap-2">
            <svg className="w-5 h-5 text-rose-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span className="font-semibold">{serverError}</span>
          </div>
          <button
            type="button"
            onClick={handleSubmit}
            className="shrink-0 font-black underline cursor-pointer text-rose-900"
          >
            إعادة المحاولة
          </button>
        </div>
      )}

      <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        {/* Form Fields */}
        <div className="lg:col-span-2 bg-white p-6 sm:p-8 rounded-3xl border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center gap-2 pb-3 border-b border-slate-100 mb-2">
            <span className="text-teal-600 font-bold text-lg">📍</span>
            <div>
              <h2 className="font-black text-slate-900 text-base">بيانات المستلم وعنوان التوصيل</h2>
              <span className="text-[11px] text-slate-400">تُستخدم هذه البيانات فقط لضمان وصول طلبك بدقة وسرعة</span>
            </div>
          </div>

          {/* Name */}
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1.5">
              الاسم الكريم للمستلم <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              placeholder="مثال: محمد عبدالله الأحمدي"
              className={`w-full bg-slate-50 border rounded-xl px-3.5 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-teal-600 focus:bg-white transition ${
                fieldErrors.customer_name ? 'border-rose-300 bg-rose-50/20' : 'border-slate-200'
              }`}
            />
            {fieldErrors.customer_name && (
              <p className="text-[11px] text-rose-600 mt-1 font-semibold">{fieldErrors.customer_name[0]}</p>
            )}
          </div>

          {/* Phone */}
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1.5">
              رقم الجوال لتنسيق موعد الاستلام <span className="text-rose-500">*</span>
            </label>
            <input
              type="tel"
              required
              dir="ltr"
              value={customerPhone}
              onChange={(e) => setCustomerPhone(e.target.value)}
              placeholder="05XXXXXXXX"
              className={`w-full bg-slate-50 border rounded-xl px-3.5 py-3 text-sm text-right focus:outline-none focus:ring-2 focus:ring-teal-600 focus:bg-white transition ${
                fieldErrors.customer_phone || fieldErrors.phone ? 'border-rose-300 bg-rose-50/20' : 'border-slate-200'
              }`}
            />
            {(fieldErrors.customer_phone || fieldErrors.phone) && (
              <p className="text-[11px] text-rose-600 mt-1 font-semibold">
                {(fieldErrors.customer_phone || fieldErrors.phone)![0]}
              </p>
            )}
            <span className="text-[11px] text-slate-400 mt-1 block">
              سيقوم مندوب المتجر بالتواصل معك عبر هذا الرقم قبل التوجه إلى موقعك.
            </span>
          </div>

          {/* Email (Optional) */}
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1.5">
              البريد الإلكتروني (اختياري - لاستلام الفاتورة وتفاصيل الطلب)
            </label>
            <input
              type="email"
              dir="ltr"
              value={customerEmail}
              onChange={(e) => setCustomerEmail(e.target.value)}
              placeholder="name@example.com"
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-3 text-sm text-right focus:outline-none focus:ring-2 focus:ring-teal-600 focus:bg-white transition"
            />
          </div>

          {/* Shipping Address */}
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1.5">
              عنوان التوصيل بالتفصيل <span className="text-rose-500">*</span>
            </label>
            <textarea
              required
              rows={2}
              value={shippingAddress}
              onChange={(e) => setShippingAddress(e.target.value)}
              placeholder="الشارع، الحي، بجوار معلم معروف أو رقم العمارة..."
              className={`w-full bg-slate-50 border rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-teal-600 focus:bg-white transition ${
                fieldErrors.shipping_address || fieldErrors.address ? 'border-rose-300 bg-rose-50/20' : 'border-slate-200'
              }`}
            />
            {(fieldErrors.shipping_address || fieldErrors.address) && (
              <p className="text-[11px] text-rose-600 mt-1 font-semibold">
                {(fieldErrors.shipping_address || fieldErrors.address)![0]}
              </p>
            )}
          </div>

          {/* Shipping City */}
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1.5">
              المدينة (اختياري)
            </label>
            <input
              type="text"
              value={shippingCity}
              onChange={(e) => setShippingCity(e.target.value)}
              placeholder="مثال: صنعاء / الرياض"
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-teal-600 focus:bg-white transition"
            />
          </div>

          {/* Notes */}
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1.5">
              ملاحظات أو توجيهات إضافية (اختياري)
            </label>
            <textarea
              rows={2}
              value={customerNotes}
              onChange={(e) => setCustomerNotes(e.target.value)}
              placeholder="مثال: يرجى التوصيل بعد العصر، أو الاتصال قبل الوصول بـ 15 دقيقة..."
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-teal-600 focus:bg-white transition"
            />
          </div>

          {/* Payment Method Notice */}
          <div className="pt-2">
            <label className="block text-xs font-bold text-slate-700 mb-2">طريقة الدفع المعتمدة:</label>
            <div className="flex items-center gap-3.5 p-4 rounded-2xl bg-teal-50/80 border border-teal-200/80 text-teal-950 text-xs">
              <span className="text-2xl shrink-0">💵</span>
              <div>
                <strong className="text-teal-900 block font-black text-sm">الدفع نقداً عند الاستلام (COD)</strong>
                <p className="text-[11px] text-teal-800/90 mt-0.5 leading-relaxed">
                  لن تدفع أي مبالغ الآن. استلم طلبك وافحصه أولاً، ثم ادفع القيمة للمندوب نقداً.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Order Summary & Submit */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-xs space-y-4">
          <div className="flex items-center justify-between pb-2 border-b border-slate-100">
            <h2 className="font-black text-slate-900 text-base">محتويات طلبك</h2>
            <span className="text-xs font-bold text-slate-500">{items.length} منتجات</span>
          </div>

          <div className="divide-y divide-slate-100 max-h-60 overflow-y-auto pr-1">
            {items.map((i) => (
              <div key={i.productUnitId} className="py-2.5 flex items-center justify-between text-xs">
                <div>
                  <span className="font-bold text-slate-900 block truncate max-w-[170px]">
                    {i.productName}
                  </span>
                  <span className="text-slate-400">
                    {i.quantity} × {i.unitName}
                  </span>
                </div>
                <span className="font-extrabold text-slate-800" dir="ltr">
                  {formatCurrency(i.displayedPrice * i.quantity)}
                </span>
              </div>
            ))}
          </div>

          <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-sm">
            <span className="text-slate-500 font-bold">المجموع الكلي التقديري</span>
            <span className="font-black text-slate-900 text-lg" dir="ltr">
              {formatCurrency(estimatedTotal)}
            </span>
          </div>

          <div className="p-3 rounded-xl bg-slate-50 border border-slate-100 text-[11px] text-slate-500 leading-relaxed">
            🔒 معاملة شراء مباشرة ومحمية عبر منصة التاجر الذكي الرسمية.
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full flex items-center justify-center gap-2 bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white font-black py-4 px-6 rounded-2xl shadow-lg shadow-teal-600/25 transition cursor-pointer text-sm sm:text-base active:scale-98"
          >
            {isSubmitting ? (
              <>
                <svg className="animate-spin -ml-1 mr-3 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                <span>جاري إرسال وتأكيد الطلب...</span>
              </>
            ) : (
              <span>تأكيد الطلب والدفع عند الاستلام 🚚</span>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
