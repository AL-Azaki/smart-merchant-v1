import { test, describe } from 'node:test';
import assert from 'node:assert';
import {
  formatCurrency,
  sanitizePhone,
  buildWhatsAppUrl,
  isValidImageUrl,
  isValidHexColor,
  getSafeThemeColor,
} from '../lib/utils.ts';

describe('Unit Tests: Utils & Validation', () => {
  test('1. Currency formatting handles valid amounts, nulls, and custom currency', () => {
    assert.match(formatCurrency(100), /100/);
    assert.strictEqual(formatCurrency(null), '0 ر.س');
    assert.strictEqual(formatCurrency(undefined), '0 ر.س');
    assert.match(formatCurrency(50.5, '$'), /50[.,]5/);
  });

  test('2. Phone sanitization removes dashes, spaces, and international prefixes', () => {
    assert.strictEqual(sanitizePhone('+966 50 123 4567'), '966501234567');
    assert.strictEqual(sanitizePhone('00966-50-1234567'), '966501234567');
    assert.strictEqual(sanitizePhone(null), null);
    assert.strictEqual(sanitizePhone(''), null);
  });

  test('3. WhatsApp URL building encodes messages and handles order numbers safely', () => {
    const url = buildWhatsAppUrl('966501234567', 'متجر النخبة', 'ORD-12345');
    assert.ok(url);
    assert.ok(url.startsWith('https://wa.me/966501234567?text='));
    assert.ok(url.includes(encodeURIComponent('ORD-12345')));
    assert.ok(url.includes(encodeURIComponent('متجر النخبة')));

    // Missing phone returns null
    assert.strictEqual(buildWhatsAppUrl(null, 'متجر'), null);
  });

  test('4. Image validation rejects malicious, device, or invalid paths', () => {
    assert.strictEqual(isValidImageUrl('javascript:alert(1)'), false);
    assert.strictEqual(isValidImageUrl('file:///C:/secret.txt'), false);
    assert.strictEqual(isValidImageUrl('data:text/html;base64,...'), false);
    assert.strictEqual(isValidImageUrl('/data/user/0/com.app/cache/img.png'), false);
    assert.strictEqual(isValidImageUrl('C:\\Users\\test\\img.jpg'), false);
    assert.strictEqual(isValidImageUrl(''), false);
    assert.strictEqual(isValidImageUrl(null), false);

    // Valid URLs
    assert.strictEqual(isValidImageUrl('https://example.com/image.jpg'), true);
    assert.strictEqual(isValidImageUrl('http://127.0.0.1:8000/storage/p.png'), true);
    assert.strictEqual(isValidImageUrl('/uploads/product.png'), true);
  });

  test('5. Hex color validation prevents CSS injection', () => {
    assert.strictEqual(isValidHexColor('#fff'), true);
    assert.strictEqual(isValidHexColor('#2563eb'), true);
    assert.strictEqual(isValidHexColor('blue; background-image: url(...)'), false);
    assert.strictEqual(isValidHexColor('red'), false);
    assert.strictEqual(isValidHexColor('123456'), false);
    assert.strictEqual(isValidHexColor(null), false);

    assert.strictEqual(getSafeThemeColor('#10b981'), '#10b981');
    assert.strictEqual(getSafeThemeColor('javascript:alert(1)', '#2563eb'), '#2563eb');
  });
});
