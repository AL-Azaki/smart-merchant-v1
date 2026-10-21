/**
 * Utility functions for storefront
 */

/**
 * Format currency with Arabic locale and currency symbol
 * Price displayed in Next.js is strictly for estimation; Laravel is the authoritative source.
 */
export function formatCurrency(amount: number | null | undefined, currency = 'ر.س'): string {
  if (amount == null || isNaN(Number(amount))) {
    return `0 ${currency}`;
  }
  const formatted = new Intl.NumberFormat('ar-SA-u-nu-latn', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(Number(amount));

  return `${formatted} ${currency}`;
}

/**
 * Sanitize phone number for WhatsApp URL
 * Strips out spaces, dashes, +, and leading zeros if needed
 */
export function sanitizePhone(phone: string | null | undefined): string | null {
  if (!phone) return null;
  const cleaned = phone.replace(/[^\d+]/g, '');
  if (!cleaned) return null;

  let digits = cleaned.replace(/^\+/, '');
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  return digits;
}

/**
 * Build WhatsApp link safely
 */
export function buildWhatsAppUrl(
  phone: string | null | undefined,
  storeName: string,
  orderNumber?: string,
): string | null {
  const sanitized = sanitizePhone(phone);
  if (!sanitized) return null;

  let message = `مرحباً ${storeName}، أود الاستفسار عن منتجاتكم.`;
  if (orderNumber) {
    message = `مرحباً ${storeName}، قمت بطلب جديد برقم (#${orderNumber}) وأود تأكيده معكم.`;
  }

  return `https://wa.me/${sanitized}?text=${encodeURIComponent(message)}`;
}

/**
 * Validates if an image URL is safe to render in the browser.
 * Rejects local paths, file://, javascript:, data: URIs, etc.
 */
export function isValidImageUrl(url: string | null | undefined): boolean {
  if (!url || typeof url !== 'string') return false;
  const trimmed = url.trim();

  if (
    trimmed.startsWith('javascript:') ||
    trimmed.startsWith('file:') ||
    trimmed.startsWith('data:') ||
    trimmed.startsWith('/data/user/') ||
    trimmed.startsWith('C:\\') ||
    trimmed.startsWith('c:\\') ||
    /^[a-zA-Z]:\\/.test(trimmed)
  ) {
    return false;
  }

  return (
    trimmed.startsWith('http://') ||
    trimmed.startsWith('https://') ||
    trimmed.startsWith('/')
  );
}

/**
 * Validates a HEX color to prevent CSS injection
 */
export function isValidHexColor(color: string | null | undefined): boolean {
  if (!color || typeof color !== 'string') return false;
  return /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(color.trim());
}

/**
 * Returns safe theme color or fallback
 */
export function getSafeThemeColor(
  color: string | null | undefined,
  fallback = '#2563eb',
): string {
  if (isValidHexColor(color)) {
    return color!.trim();
  }
  return fallback;
}
