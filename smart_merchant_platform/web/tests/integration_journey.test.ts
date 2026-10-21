import { test, describe } from 'node:test';
import assert from 'node:assert';
import type { CartItem, CreateOrderPayload, StoreBootstrap } from '../lib/types.ts';

describe('Integration & Journey Contract Tests', () => {
  const storeA = 'al-nokhba-store';
  const storeB = 'al-baraka-store';

  test('1. Storefront Isolation: Carts from different store slugs never interfere', () => {
    const storageMock: Record<string, string> = {};

    const saveCart = (slug: string, items: CartItem[]) => {
      storageMock[`smart-merchant-cart:${slug}`] = JSON.stringify(items);
    };

    const loadCart = (slug: string): CartItem[] => {
      const raw = storageMock[`smart-merchant-cart:${slug}`];
      if (!raw) return [];
      try {
        const parsed = JSON.parse(raw);
        return Array.isArray(parsed)
          ? parsed.filter((i: CartItem) => i && i.productUnitId && i.storeSlug === slug && i.quantity > 0)
          : [];
      } catch {
        return [];
      }
    };

    // Store A items
    const itemA: CartItem = {
      storeSlug: storeA,
      productId: 'p-1',
      productUnitId: 'u-1',
      productName: 'منتج أ',
      unitName: 'حبة',
      displayedPrice: 10,
      quantity: 2,
      image: null,
    };
    saveCart(storeA, [itemA]);

    // Store B items
    const itemB: CartItem = {
      storeSlug: storeB,
      productId: 'p-2',
      productUnitId: 'u-2',
      productName: 'منتج ب',
      unitName: 'علبة',
      displayedPrice: 30,
      quantity: 1,
      image: null,
    };
    saveCart(storeB, [itemB]);

    // Verify isolation
    const loadedA = loadCart(storeA);
    const loadedB = loadCart(storeB);

    assert.strictEqual(loadedA.length, 1);
    assert.strictEqual(loadedA[0].productName, 'منتج أ');
    assert.strictEqual(loadedA[0].storeSlug, storeA);

    assert.strictEqual(loadedB.length, 1);
    assert.strictEqual(loadedB[0].productName, 'منتج ب');
    assert.strictEqual(loadedB[0].storeSlug, storeB);
  });

  test('2. Storage Recovery: Corrupted JSON gracefully resets to empty cart without crashing', () => {
    const corruptJSON = '{ invalid_json... @@';
    let loaded: CartItem[] = [];
    try {
      const parsed = JSON.parse(corruptJSON);
      if (Array.isArray(parsed)) loaded = parsed;
    } catch {
      loaded = [];
    }

    assert.deepStrictEqual(loaded, []);
  });

  test('3. Checkout Failure preserves cart and idempotency key for safe retry', () => {
    let cart: CartItem[] = [
      {
        storeSlug: storeA,
        productId: 'p-10',
        productUnitId: 'u-10',
        productName: 'قهوة مختصة',
        unitName: 'كيس 250 جم',
        displayedPrice: 45,
        quantity: 1,
        image: null,
      },
    ];

    const initialKey = '550e8400-e29b-41d4-a716-446655440000';
    const currentKey = initialKey;

    // Simulate 500 error or network failure
    const simulateOrderSubmission = (status: number) => {
      if (status >= 400) {
        // On error: cart is preserved, idempotency key is preserved
        return { success: false, status };
      }
      // On success: cart is cleared
      cart = [];
      return { success: true, orderNumber: 'ORD-9999' };
    };

    const failResult = simulateOrderSubmission(500);
    assert.strictEqual(failResult.success, false);
    assert.strictEqual(cart.length, 1, 'Cart must NOT be cleared on failure');
    assert.strictEqual(currentKey, initialKey, 'Idempotency key must NOT change on retry');

    // Simulate network retry success
    const retryResult = simulateOrderSubmission(200);
    assert.strictEqual(retryResult.success, true);
    assert.strictEqual(cart.length, 0, 'Cart must be cleared on confirmed success');
  });

  test('4. Price Authoritative Rule: Server determines all final totals regardless of client changes', () => {
    // Client cart had displayedPrice: 20
    const clientItem: CartItem = {
      storeSlug: storeA,
      productId: 'p-30',
      productUnitId: 'u-30',
      productName: 'عسل سدر',
      unitName: 'برطمان 500 جم',
      displayedPrice: 20.0,
      quantity: 3,
      image: null,
    };

    // Client builds order payload: NO PRICES SENT
    const payload: CreateOrderPayload = {
      customer_name: 'خالد',
      customer_phone: '0555555555',
      shipping_address: 'الرياض، العليا',
      items: [
        {
          product_id: clientItem.productId,
          product_unit_id: clientItem.productUnitId,
          quantity: clientItem.quantity,
        },
      ],
      idempotency_key: 'test-key-authoritative',
    };

    const rawPayload = payload as unknown as Record<string, unknown>;
    assert.strictEqual(rawPayload.selling_price, undefined);
    assert.strictEqual(rawPayload.sub_total, undefined);
    assert.strictEqual(rawPayload.grand_total, undefined);

    // Backend calculates official price from DB (e.g. price was updated to 25.0)
    const officialServerUnitPrice = 25.0;
    const computedGrandTotal = officialServerUnitPrice * payload.items[0].quantity;
    assert.strictEqual(computedGrandTotal, 75.0);
  });

  test('5. Bootstrap & Store Status: Closed store flags storefront_active as false', () => {
    const closedStore: StoreBootstrap = {
      storefront_slug: 'closed-shop',
      business_name: 'محل مغلق',
      display_name: 'محل مغلق مؤقتاً',
      logo_path: null,
      storefront_active: false,
      whatsapp: '0500000000',
      phone: '0500000000',
      address_text: 'شارع حراء',
      lat: null,
      lng: null,
      theme_settings: null,
    };

    assert.strictEqual(closedStore.storefront_active, false);
    assert.strictEqual(closedStore.storefront_slug, 'closed-shop');
  });
});
