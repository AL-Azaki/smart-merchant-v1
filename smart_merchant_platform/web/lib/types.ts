/* ──────────────────────────────────────────────
   TypeScript contracts matching Laravel Storefront API
   ────────────────────────────────────────────── */

// ─── Bootstrap ──────────────────────────────
export interface StoreBootstrap {
  storefront_slug: string;
  business_name: string;
  display_name: string;
  logo_path: string | null;
  storefront_active: boolean;
  whatsapp: string | null;
  phone: string | null;
  address_text: string | null;
  lat: number | null;
  lng: number | null;
  theme_settings: ThemeSettings | null;
}

export interface ThemeSettings {
  primary_color?: string;
  [key: string]: unknown;
}

// ─── Categories ─────────────────────────────
export interface StoreCategory {
  id: string;
  category_name: string;
  category_code: string | null;
  description: string | null;
  parent_id: string | null;
}

// ─── Product Images ─────────────────────────
export interface ProductImage {
  id: string;
  image_path: string | null;
  is_primary: boolean;
  has_fallback: boolean;
}

// ─── Product Units ──────────────────────────
export interface StoreProductUnit {
  id: string;
  unit_id: string;
  unit_name: string | null;
  unit_symbol: string | null;
  is_base_unit: boolean;
  is_active: boolean;
  conversion_factor: number;
  barcode: string | null;
  selling_price: number;
  inventory_quantity?: number;
}

// ─── Product List Item ──────────────────────
export interface StoreProductListItem {
  id: string;
  product_name: string;
  product_code: string | null;
  description: string | null;
  category_id: string | null;
  brand_id: string | null;
  category_name: string | null;
  brand_name: string | null;
  primary_image: string | null;
  selling_price: number | null;
  images: ProductImage[];
  units: StoreProductUnit[];
}

// ─── Product Detail ─────────────────────────
export interface StoreProductDetail {
  id: string;
  product_name: string;
  product_code: string | null;
  description: string | null;
  category_id: string | null;
  brand_id: string | null;
  category: StoreCategory | null;
  brand: {
    id: string;
    brand_name: string;
    logo_path: string | null;
  } | null;
  primary_image: string | null;
  images: ProductImage[];
  units: StoreProductUnit[];
}

// ─── Pagination ─────────────────────────────
export interface PaginationMeta {
  current_page: number;
  from: number | null;
  last_page: number;
  path: string;
  per_page: number;
  to: number | null;
  total: number;
}

export interface PaginationLinks {
  first: string | null;
  last: string | null;
  prev: string | null;
  next: string | null;
}

export interface PaginatedResponse<T> {
  data: T[];
  links: PaginationLinks;
  meta: PaginationMeta;
}

// ─── Orders ─────────────────────────────────
export interface OrderItemInput {
  product_id?: string;
  product_unit_id: string;
  quantity: number;
}

export interface GuestCheckoutInput {
  customer_name: string;
  customer_phone: string;
  customer_email?: string;
  shipping_address?: string;
  shipping_city?: string;
  customer_notes?: string;
}

export interface CreateOrderPayload {
  customer_name: string;
  phone?: string;
  customer_phone?: string;
  email?: string;
  customer_email?: string;
  address?: string;
  shipping_address?: string;
  city?: string;
  shipping_city?: string;
  notes?: string;
  customer_notes?: string;
  items: OrderItemInput[];
  idempotency_key: string;
}

export interface OrderSuccessResponse {
  data: {
    id: string;
    order_number: string;
    order_date: string | null;
    status: string;
    payment_status: string | null;
    sub_total: number;
    tax_total: number | null;
    grand_total: number;
    notes: string | null;
  };
}

// ─── Errors ─────────────────────────────────
export interface ApiValidationError {
  message: string;
  errors: Record<string, string[]>;
}

export interface ApiError {
  message: string;
  status: number;
  isValidation: boolean;
  code?: string;
  validationErrors?: Record<string, string[]>;
}

// ─── Cart ───────────────────────────────────
export interface CartItem {
  storeSlug: string;
  productId: string;
  productUnitId: string;
  productName: string;
  unitName: string;
  displayedPrice: number;
  quantity: number;
  image: string | null;
}
