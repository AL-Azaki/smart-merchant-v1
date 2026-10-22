/** Centralized environment configuration */

const rawApiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://127.0.0.1:8000';
const rawStorefrontUrl = process.env.NEXT_PUBLIC_STOREFRONT_URL ?? 'http://localhost:3000';

/** Laravel API base URL (no trailing slash) */
export const API_BASE_URL = rawApiUrl.replace(/\/+$/, '');

/** Next.js storefront public URL for canonical/SEO (no trailing slash) */
export const STOREFRONT_URL = rawStorefrontUrl.replace(/\/+$/, '');

/** Storefront API prefix */
export const STOREFRONT_API_PREFIX = `${API_BASE_URL}/api/storefront/v1`;

/** Central Marketplace API prefix */
export const MARKETPLACE_API_PREFIX = `${API_BASE_URL}/api/marketplace/v1`;

