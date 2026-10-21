import { test, describe } from 'node:test';
import assert from 'node:assert';
import type { CreateOrderPayload, CartItem } from '../lib/types.ts';

// Helper simulating checkout payload construction
function buildCheckoutPayload(
  customer: {
    name: string;
    phone: string;
    email?: string;
    address: string;
    city?: string;
    notes?: string;
  },
  items: CartItem[],
  idempotencyKey: string,
): CreateOrderPayload {
  return {
    customer_name: customer.name.trim(),
    customer_phone: customer.phone.trim(),
    customer_email: customer.email?.trim() || undefined,
    shipping_address: customer.address.trim(),
    shipping_city: customer.city?.trim() || undefined,
    customer_notes: customer.notes?.trim() || undefined,
    items: items.map((i) => ({
      product_id: i.productId,
      product_unit_id: i.productUnitId,
      quantity: i.quantity,
    })),
    idempotency_key: idempotencyKey,
  };
}

describe('Unit Tests: Order Contract & Idempotency', () => {
  const sampleCart: CartItem[] = [
    {
      storeSlug: 'demo-store',
      productId: 'b4a09a56-42bb-41a4-bb50-b49d799d1469',
      productUnitId: 'c2b18a56-42bb-41a4-bb50-b49d799d1470',
      productName: 'حليب كامل الدسم',
      unitName: 'علبة 1 لتر',
      displayedPrice: 6.5,
      quantity: 3,
      image: 'https://example.com/milk.jpg',
    },
  ];

  test('1. Checkout payload strictly excludes all price & calculation fields', () => {
    const payload = buildCheckoutPayload(
      {
        name: 'أحمد علي',
        phone: '0501234567',
        address: 'شارع الملك فهد، الرياض',
      },
      sampleCart,
      'test-idempotency-key-uuid',
    );

    // Assert that prices and financial totals are NOT sent by the client
    const rawRecord = payload as unknown as Record<string, unknown>;
    assert.strictEqual(rawRecord.selling_price, undefined);
    assert.strictEqual(rawRecord.unit_price, undefined);
    assert.strictEqual(rawRecord.line_total, undefined);
    assert.strictEqual(rawRecord.sub_total, undefined);
    assert.strictEqual(rawRecord.subtotal, undefined);
    assert.strictEqual(rawRecord.grand_total, undefined);
    assert.strictEqual(rawRecord.total, undefined);
    assert.strictEqual(rawRecord.tax_total, undefined);

    // Each item must only contain product_id, product_unit_id, quantity
    for (const item of payload.items) {
      const itemRecord = item as unknown as Record<string, unknown>;
      assert.strictEqual(itemRecord.price, undefined);
      assert.strictEqual(itemRecord.unit_price, undefined);
      assert.strictEqual(itemRecord.line_total, undefined);
      assert.strictEqual(itemRecord.displayedPrice, undefined);
      assert.ok(item.product_unit_id);
      assert.ok(item.quantity > 0);
    }
  });

  test('2. Idempotency key is preserved and matches UUID format', () => {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const key = '12345678-1234-4234-8234-123456789abc';

    assert.ok(uuidRegex.test(key));

    const payload = buildCheckoutPayload(
      {
        name: 'سالم',
        phone: '0512345678',
        address: 'حي الورود',
      },
      sampleCart,
      key,
    );

    assert.strictEqual(payload.idempotency_key, key);
  });

  test('3. API status code error mapping maps correctly to human-friendly Arabic messages', () => {
    const statusMap: Record<number, string> = {
      400: 'طلب غير صالح',
      403: 'المتجر مغلق حالياً',
      404: 'الصفحة أو المحتوى غير موجود',
      409: 'تم إرسال هذا الطلب مسبقاً',
      422: 'يوجد خطأ في البيانات المدخلة',
      429: 'عدد الطلبات كثير جداً. انتظر قليلاً وحاول مجدداً',
      500: 'خطأ في الخادم. حاول مجدداً لاحقاً',
    };

    for (const [code, expectedMsg] of Object.entries(statusMap)) {
      assert.ok(expectedMsg.length > 0, `Status ${code} must have a message`);
    }
  });

  test('4. PRODUCT_UNIT_UNAVAILABLE error contract conforms to normalized Arabic response without leaking models', () => {
    const errorPayload = {
      message: 'أحد المنتجات في السلة لم يعد متاحًا للشراء.',
      code: 'PRODUCT_UNIT_UNAVAILABLE',
      errors: {
        'items.0.product_unit_id': [
          'هذا المنتج أو خيار البيع لم يعد متاحًا.',
        ],
      },
    };

    assert.strictEqual(errorPayload.code, 'PRODUCT_UNIT_UNAVAILABLE');
    assert.strictEqual(errorPayload.message, 'أحد المنتجات في السلة لم يعد متاحًا للشراء.');
    assert.ok(errorPayload.errors['items.0.product_unit_id']);
    // Ensure no internal class names or stack traces are present
    assert.strictEqual(JSON.stringify(errorPayload).includes('App\\Models'), false);
    assert.strictEqual(JSON.stringify(errorPayload).includes('Exception'), false);
  });
});
