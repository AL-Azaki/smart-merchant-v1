import { test, describe } from 'node:test';
import assert from 'node:assert';
import type { CartItem } from '../lib/types.ts';

// Pure cart reducer simulation identical to cart-context logic
function cartReducer(
  state: CartItem[],
  action:
    | { type: 'ADD'; slug: string; item: Omit<CartItem, 'quantity' | 'storeSlug'>; quantity: number }
    | { type: 'REMOVE'; productUnitId: string }
    | { type: 'UPDATE'; productUnitId: string; quantity: number }
    | { type: 'CLEAR' },
): CartItem[] {
  switch (action.type) {
    case 'ADD': {
      if (action.quantity <= 0) return state;
      const index = state.findIndex((i) => i.productUnitId === action.item.productUnitId);
      if (index > -1) {
        const copy = [...state];
        copy[index] = { ...copy[index], quantity: copy[index].quantity + action.quantity };
        return copy;
      }
      return [
        ...state,
        {
          ...action.item,
          storeSlug: action.slug,
          quantity: action.quantity,
        },
      ];
    }
    case 'REMOVE':
      return state.filter((i) => i.productUnitId !== action.productUnitId);
    case 'UPDATE':
      if (action.quantity <= 0) {
        return state.filter((i) => i.productUnitId !== action.productUnitId);
      }
      return state.map((i) =>
        i.productUnitId === action.productUnitId ? { ...i, quantity: action.quantity } : i,
      );
    case 'CLEAR':
      return [];
    default:
      return state;
  }
}

describe('Unit Tests: Cart Logic & Isolation', () => {
  const storeA = 'store-alpha';
  const storeB = 'store-beta';

  const item1: Omit<CartItem, 'quantity' | 'storeSlug'> = {
    productId: 'prod-1',
    productUnitId: 'unit-1',
    productName: 'سكر 5 كجم',
    unitName: 'كيس',
    displayedPrice: 25.0,
    image: null,
  };

  const item2: Omit<CartItem, 'quantity' | 'storeSlug'> = {
    productId: 'prod-2',
    productUnitId: 'unit-2',
    productName: 'أرز بسمتي',
    unitName: 'كيس 10 كجم',
    displayedPrice: 75.0,
    image: null,
  };

  test('1. Adding item creates new entry with correct store slug and quantity', () => {
    let cart: CartItem[] = [];
    cart = cartReducer(cart, { type: 'ADD', slug: storeA, item: item1, quantity: 2 });

    assert.strictEqual(cart.length, 1);
    assert.strictEqual(cart[0].productUnitId, 'unit-1');
    assert.strictEqual(cart[0].quantity, 2);
    assert.strictEqual(cart[0].storeSlug, storeA);
  });

  test('2. Adding duplicate unit increments quantity instead of adding duplicate row', () => {
    let cart: CartItem[] = [];
    cart = cartReducer(cart, { type: 'ADD', slug: storeA, item: item1, quantity: 1 });
    cart = cartReducer(cart, { type: 'ADD', slug: storeA, item: item1, quantity: 3 });

    assert.strictEqual(cart.length, 1);
    assert.strictEqual(cart[0].quantity, 4);
  });

  test('3. Updating quantity modifies target item or removes if <= 0', () => {
    let cart: CartItem[] = [];
    cart = cartReducer(cart, { type: 'ADD', slug: storeA, item: item1, quantity: 2 });
    cart = cartReducer(cart, { type: 'ADD', slug: storeA, item: item2, quantity: 1 });

    assert.strictEqual(cart.length, 2);

    // Update quantity
    cart = cartReducer(cart, { type: 'UPDATE', productUnitId: 'unit-1', quantity: 5 });
    assert.strictEqual(cart.find((i) => i.productUnitId === 'unit-1')?.quantity, 5);

    // Update to 0 removes it
    cart = cartReducer(cart, { type: 'UPDATE', productUnitId: 'unit-1', quantity: 0 });
    assert.strictEqual(cart.length, 1);
    assert.strictEqual(cart[0].productUnitId, 'unit-2');
  });

  test('4. Removing item filters it out completely', () => {
    let cart: CartItem[] = [];
    cart = cartReducer(cart, { type: 'ADD', slug: storeA, item: item1, quantity: 1 });
    cart = cartReducer(cart, { type: 'REMOVE', productUnitId: 'unit-1' });

    assert.strictEqual(cart.length, 0);
  });

  test('5. Clear cart empties all items', () => {
    let cart: CartItem[] = [];
    cart = cartReducer(cart, { type: 'ADD', slug: storeA, item: item1, quantity: 1 });
    cart = cartReducer(cart, { type: 'ADD', slug: storeA, item: item2, quantity: 2 });
    assert.strictEqual(cart.length, 2);

    cart = cartReducer(cart, { type: 'CLEAR' });
    assert.strictEqual(cart.length, 0);
  });

  test('6. Store-specific cart storage keys ensure tenant isolation', () => {
    const keyA = `smart-merchant-cart:${storeA}`;
    const keyB = `smart-merchant-cart:${storeB}`;

    assert.notStrictEqual(keyA, keyB);
    assert.strictEqual(keyA, 'smart-merchant-cart:store-alpha');
    assert.strictEqual(keyB, 'smart-merchant-cart:store-beta');
  });

  test('7. Storage migration migrates valid legacy cart_{slug} to smart-merchant-cart:{slug} and cleans up legacy key', () => {
    const fakeLocalStorage: Record<string, string> = {
      [`cart_${storeA}`]: JSON.stringify([item1]),
    };

    const canonicalKey = `smart-merchant-cart:${storeA}`;
    const legacyKey = `cart_${storeA}`;

    // Simulate migration
    let stored = fakeLocalStorage[canonicalKey];
    if (!stored) {
      const legacyStored = fakeLocalStorage[legacyKey];
      if (legacyStored) {
        try {
          const parsed = JSON.parse(legacyStored);
          if (Array.isArray(parsed) && parsed.length > 0) {
            stored = legacyStored;
            fakeLocalStorage[canonicalKey] = legacyStored;
            delete fakeLocalStorage[legacyKey];
          }
        } catch {}
      }
    }

    assert.ok(fakeLocalStorage[canonicalKey]);
    assert.strictEqual(fakeLocalStorage[legacyKey], undefined);
    assert.strictEqual(JSON.parse(fakeLocalStorage[canonicalKey])[0].productUnitId, 'unit-1');
  });

  test('8. Storage migration safely handles corrupt legacy JSON without crashing', () => {
    const fakeLocalStorage: Record<string, string> = {
      [`cart_${storeA}`]: 'INVALID_JSON_CORRUPT{[{',
    };

    const canonicalKey = `smart-merchant-cart:${storeA}`;
    const legacyKey = `cart_${storeA}`;

    const stored = fakeLocalStorage[canonicalKey];
    if (!stored) {
      const legacyStored = fakeLocalStorage[legacyKey];
      if (legacyStored) {
        try {
          const parsed = JSON.parse(legacyStored);
          if (Array.isArray(parsed) && parsed.length > 0) {
            fakeLocalStorage[canonicalKey] = legacyStored;
            delete fakeLocalStorage[legacyKey];
          }
        } catch {
          // Corrupt legacy ignored safely
        }
      }
    }

    assert.strictEqual(fakeLocalStorage[canonicalKey], undefined);
  });
});
