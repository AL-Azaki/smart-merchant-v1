'use client';

import React, { createContext, useContext, useEffect, useState, useMemo } from 'react';
import type { CartItem } from './types';

interface CartContextValue {
  items: CartItem[];
  addItem: (item: Omit<CartItem, 'quantity' | 'storeSlug'>, quantity?: number) => void;
  removeItem: (productUnitId: string) => void;
  updateQuantity: (productUnitId: string, quantity: number) => void;
  clearCart: () => void;
  itemCount: number;
  estimatedTotal: number;
  isLoaded: boolean;
}

const CartContext = createContext<CartContextValue | null>(null);

export function getCartStorageKey(slug: string): string {
  return `smart-merchant-cart:${slug}`;
}

export function CartProvider({
  slug,
  children,
}: {
  slug: string;
  children: React.ReactNode;
}) {
  const [items, setItems] = useState<CartItem[]>([]);
  const [isLoaded, setIsLoaded] = useState(false);

  const storageKey = getCartStorageKey(slug);

  // Hydrate from localStorage on client mount with migration from legacy key
  useEffect(() => {
    const timer = setTimeout(() => {
      try {
        const canonicalKey = getCartStorageKey(slug);
        const legacyKey = `cart_${slug}`;
        let stored = localStorage.getItem(canonicalKey);

        // One-time safe migration from legacy storage key if canonical not present
        if (!stored) {
          const legacyStored = localStorage.getItem(legacyKey);
          if (legacyStored) {
            try {
              const parsedLegacy = JSON.parse(legacyStored);
              if (Array.isArray(parsedLegacy) && parsedLegacy.length > 0) {
                stored = legacyStored;
                localStorage.setItem(canonicalKey, legacyStored);
                localStorage.removeItem(legacyKey);
              }
            } catch {
              // Ignore corrupt legacy cart
            }
          }
        }

        if (stored) {
          const parsed = JSON.parse(stored);
          if (Array.isArray(parsed)) {
            // Ensure every item matches the current slug
            const validItems = parsed.filter(
              (i: CartItem) => i && i.productUnitId && i.storeSlug === slug && i.quantity > 0,
            );
            setItems(validItems);
          }
        }
      } catch {
        // Corrupt storage, ignore and start fresh
        setItems([]);
      } finally {
        setIsLoaded(true);
      }
    }, 0);

    return () => clearTimeout(timer);
  }, [slug]);

  // Sync back to localStorage whenever items change after initial load
  useEffect(() => {
    if (!isLoaded) return;
    try {
      localStorage.setItem(storageKey, JSON.stringify(items));
    } catch {
      // Storage full or unavailable
    }
  }, [items, isLoaded, storageKey]);

  const addItem = (
    item: Omit<CartItem, 'quantity' | 'storeSlug'>,
    quantity = 1,
  ) => {
    if (quantity <= 0) return;
    setItems((prev) => {
      const existingIndex = prev.findIndex((i) => i.productUnitId === item.productUnitId);
      if (existingIndex > -1) {
        const updated = [...prev];
        const newQty = updated[existingIndex].quantity + quantity;
        updated[existingIndex] = { ...updated[existingIndex], quantity: newQty };
        return updated;
      }
      return [
        ...prev,
        {
          ...item,
          storeSlug: slug,
          quantity,
        },
      ];
    });
  };

  const removeItem = (productUnitId: string) => {
    setItems((prev) => prev.filter((i) => i.productUnitId !== productUnitId));
  };

  const updateQuantity = (productUnitId: string, quantity: number) => {
    if (quantity <= 0) {
      removeItem(productUnitId);
      return;
    }
    setItems((prev) =>
      prev.map((i) =>
        i.productUnitId === productUnitId ? { ...i, quantity } : i,
      ),
    );
  };

  const clearCart = () => {
    setItems([]);
    try {
      localStorage.removeItem(storageKey);
    } catch {
      // ignore
    }
  };

  const itemCount = useMemo(
    () => items.reduce((sum, item) => sum + item.quantity, 0),
    [items],
  );

  const estimatedTotal = useMemo(
    () => items.reduce((sum, item) => sum + item.displayedPrice * item.quantity, 0),
    [items],
  );

  return (
    <CartContext.Provider
      value={{
        items,
        addItem,
        removeItem,
        updateQuantity,
        clearCart,
        itemCount,
        estimatedTotal,
        isLoaded,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart(): CartContextValue {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
}
