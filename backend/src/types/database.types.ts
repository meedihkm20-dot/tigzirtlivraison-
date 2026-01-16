/**
 * ============================================================
 * TYPES GÉNÉRÉS DEPUIS LE SCHÉMA SQL - SOURCE DE VÉRITÉ UNIQUE
 * ============================================================
 * 
 * ⚠️  NE PAS MODIFIER MANUELLEMENT
 * Ces types doivent correspondre EXACTEMENT au schéma SQL
 * Fichier source: supabase/migrations/000_complete_schema.sql
 * 
 * RÈGLES:
 * 1. Tout changement commence par le SQL
 * 2. Puis on met à jour ce fichier
 * 3. Puis on met à jour les modèles Dart
 * ============================================================
 */

// ============================================
// ENUMS (correspondent aux types SQL)
// ============================================

export type UserRole = 'customer' | 'restaurant' | 'livreur' | 'admin';

export type OrderStatus = 
  | 'pending'
  | 'confirmed'
  | 'preparing'
  | 'ready'
  | 'picked_up'
  | 'delivering'
  | 'delivered'
  | 'cancelled';

export type PaymentMethod = 'cash' | 'card' | 'edahabia' | 'cib';

export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'refunded';

export type VehicleType = 'moto' | 'velo' | 'voiture';

export type LivreurTier = 'bronze' | 'silver' | 'gold' | 'diamond';

export type TransactionType = 'livreur_earning' | 'admin_commission' | 'restaurant_payment';

export type TransactionStatus = 'pending' | 'completed' | 'cancelled';

// ============================================
// TABLE: profiles
// ============================================
export interface Profile {
  id: string; // UUID, PK, FK auth.users
  role: UserRole;
  phone: string | null;
  full_name: string | null;
  avatar_url: string | null;
  address: string | null;
  latitude: number | null; // DECIMAL(10, 8)
  longitude: number | null; // DECIMAL(11, 8)
  is_active: boolean;
  is_available: boolean; // Pour livreurs via profiles
  fcm_token: string | null;
  onesignal_player_id: string | null; // OneSignal notifications
  loyalty_points: number;
  total_orders: number;
  total_spent: number; // DECIMAL(12, 2)
  referral_code: string | null;
  referred_by: string | null; // UUID
  referral_earnings: number; // DECIMAL(10, 2)
  phone_verified: boolean;
  email_verified: boolean;
  created_at: string; // TIMESTAMPTZ
  updated_at: string; // TIMESTAMPTZ
}

// ============================================
// TABLE: restaurants
// ============================================
export interface Restaurant {
  id: string; // UUID, PK
  owner_id: string; // UUID, FK profiles
  name: string;
  description: string | null;
  logo_url: string | null;
  cover_url: string | null;
  phone: string | null;
  address: string;
  latitude: number; // DECIMAL(10, 8)
  longitude: number; // DECIMAL(11, 8)
  cuisine_type: string | null;
  opening_time: string; // TIME
  closing_time: string; // TIME
  min_order_amount: number; // DECIMAL(10, 2)
  delivery_fee: number; // DECIMAL(10, 2)
  avg_prep_time: number; // INTEGER
  rating: number; // DECIMAL(2, 1)
  total_reviews: number;
  is_open: boolean;
  is_verified: boolean;
  cover_images: string[] | null;
  tags: string[] | null;
  accepts_preorders: boolean;
  fcm_token: string | null;
  created_at: string;
  updated_at: string;
}

// ============================================
// TABLE: menu_categories
// ============================================
export interface MenuCategory {
  id: string;
  restaurant_id: string;
  name: string;
  description: string | null;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

// ============================================
// TABLE: menu_items
// ============================================
export interface MenuItem {
  id: string;
  restaurant_id: string;
  category_id: string | null;
  name: string;
  description: string | null;
  price: number; // DECIMAL(10, 2)
  image_url: string | null;
  is_available: boolean;
  is_popular: boolean;
  prep_time: number;
  calories: number | null;
  is_vegetarian: boolean;
  is_spicy: boolean;
  allergens: string[] | null;
  order_count: number;
  image_width: number;
  image_height: number;
  ingredients: string[] | null;
  nutrition_info: Record<string, any> | null; // JSONB
  is_daily_special: boolean;
  daily_special_price: number | null;
  avg_rating: number;
  total_reviews: number;
  last_ordered_at: string | null;
  tags: string[] | null;
  created_at: string;
  updated_at: string;
}

// ============================================
// TABLE: livreurs
// ============================================
export interface Livreur {
  id: string; // UUID, PK
  user_id: string; // UUID, FK profiles, UNIQUE
  vehicle_type: VehicleType;
  vehicle_number: string | null;
  license_number: string | null;
  current_latitude: number | null; // DECIMAL(10, 8)
  current_longitude: number | null; // DECIMAL(11, 8)
  is_available: boolean;
  is_online: boolean;
  is_verified: boolean;
  rating: number; // DECIMAL(2, 1)
  total_deliveries: number;
  total_earnings: number; // DECIMAL(12, 2)
  total_distance_km: number;
  avg_delivery_time: number | null;
  acceptance_rate: number; // DECIMAL(5, 2)
  tier: LivreurTier;
  tier_progress: number;
  weekly_deliveries: number;
  monthly_deliveries: number;
  cancellation_rate: number;
  streak_days: number;
  last_active_date: string | null; // DATE
  bonus_earned: number;
  fcm_token: string | null;
  created_at: string;
  updated_at: string;
}

// ============================================
// TABLE: orders
// ⚠️  COLONNES CRITIQUES - NE PAS RENOMMER
// ============================================
export interface Order {
  id: string; // UUID, PK
  order_number: string; // VARCHAR(20), UNIQUE
  customer_id: string; // UUID, FK profiles
  restaurant_id: string; // UUID, FK restaurants
  livreur_id: string | null; // UUID, FK livreurs ⚠️ PAS "driver_id"
  status: OrderStatus;
  
  // Adresse de livraison
  delivery_address: string;
  delivery_latitude: number; // ⚠️ PAS "delivery_lat"
  delivery_longitude: number; // ⚠️ PAS "delivery_lng"
  delivery_instructions: string | null;
  
  // Montants
  subtotal: number;
  delivery_fee: number;
  service_fee: number;
  discount: number;
  total: number; // ⚠️ PAS "total_amount"
  
  // Paiement
  payment_method: PaymentMethod;
  payment_status: PaymentStatus;
  
  // Timestamps de suivi
  estimated_delivery_time: string | null;
  confirmed_at: string | null;
  prepared_at: string | null; // ⚠️ PAS "preparing_at"
  picked_up_at: string | null;
  delivered_at: string | null;
  cancelled_at: string | null;
  cancellation_reason: string | null;
  
  // Colonnes additionnelles
  confirmation_code: string | null; // VARCHAR(4)
  livreur_commission: number;
  admin_commission: number;
  restaurant_amount: number;
  livreur_accepted_at: string | null;
  code_verified_at: string | null;
  promotion_id: string | null;
  promo_code: string | null;
  promo_discount: number;
  current_eta_minutes: number | null;
  distance_remaining_km: number | null;
  tip_amount: number;
  tip_paid_at: string | null;
  
  // Annulation
  cancelled_by: string | null; // 'customer' | 'restaurant' | 'livreur' | 'admin' | 'system'
  
  created_at: string;
  updated_at: string;
}

// ============================================
// TABLE: order_items
// ============================================
export interface OrderItem {
  id: string;
  order_id: string;
  menu_item_id: string;
  name: string;
  price: number;
  quantity: number;
  special_instructions: string | null;
  created_at: string;
}

// ============================================
// TABLE: reviews
// ============================================
export interface Review {
  id: string;
  order_id: string;
  customer_id: string;
  restaurant_id: string;
  livreur_id: string | null;
  restaurant_rating: number | null; // 1-5
  livreur_rating: number | null; // 1-5
  comment: string | null;
  created_at: string;
}

// ============================================
// TABLE: transactions
// ============================================
export interface Transaction {
  id: string;
  order_id: string;
  type: string; // 'livreur_earning' | 'admin_commission' | 'restaurant_payment'
  amount: number;
  recipient_id: string | null;
  status: string; // 'pending' | 'completed' | 'cancelled'
  description: string | null;
  created_at: string;
}

// ============================================
// TABLE: commission_settings
// ============================================
export interface CommissionSettings {
  id: string;
  livreur_commission_percent: number;
  admin_commission_percent: number;
  min_delivery_fee: number;
  updated_at: string;
}

// ============================================
// TABLE: notifications
// ============================================
export interface Notification {
  id: string;
  user_id: string;
  title: string;
  body: string | null;
  data: Record<string, any> | null;
  is_read: boolean;
  notification_type: string;
  sent_at: string;
  read_at: string | null;
  created_at: string;
}

// ============================================
// TABLE: delivery_zones
// ============================================
export interface DeliveryZone {
  id: string;
  name: string;
  polygon: Record<string, any>; // JSONB
  fee_adjustment: number;
  is_active: boolean;
}

// ============================================
// TABLE: delivery_pricing
// ============================================
export interface DeliveryPricing {
  id: string;
  name: string;
  base_fee: number;
  per_km_fee: number;
  min_fee: number;
  max_fee: number;
  surge_multiplier: number;
  is_active: boolean;
}

// ============================================
// TABLE: promotions
// ============================================
export interface Promotion {
  id: string;
  restaurant_id: string;
  name: string;
  description: string | null;
  discount_type: 'percentage' | 'fixed';
  discount_value: number;
  min_order_amount: number;
  max_discount: number | null;
  code: string | null;
  is_active: boolean;
  starts_at: string;
  ends_at: string | null;
  usage_limit: number | null;
  usage_count: number;
  created_at: string;
}

// ============================================
// TABLE: saved_addresses
// ============================================
export interface SavedAddress {
  id: string;
  customer_id: string;
  label: string;
  address: string;
  latitude: number;
  longitude: number;
  instructions: string | null;
  is_default: boolean;
  created_at: string;
}

// ============================================
// TABLE: order_messages
// ============================================
export interface OrderMessage {
  id: string;
  order_id: string;
  sender_id: string;
  sender_type: 'customer' | 'livreur' | 'restaurant' | 'system';
  message: string;
  is_read: boolean;
  created_at: string;
}

// ============================================
// TABLE: livreur_locations
// ============================================
export interface LivreurLocation {
  id: string;
  livreur_id: string;
  order_id: string | null;
  latitude: number;
  longitude: number;
  speed: number | null;
  heading: number | null;
  recorded_at: string;
}

// ============================================
// TABLE: favorites
// ============================================
export interface Favorite {
  id: string;
  customer_id: string;
  restaurant_id: string;
  created_at: string;
}

// ============================================
// TABLE: favorite_items
// ============================================
export interface FavoriteItem {
  id: string;
  customer_id: string;
  menu_item_id: string;
  created_at: string;
}

// ============================================
// TABLE: menu_item_variants
// ============================================
export interface MenuItemVariant {
  id: string;
  menu_item_id: string;
  name: string;
  price_adjustment: number;
  is_default: boolean;
  sort_order: number;
  created_at: string;
}

// ============================================
// TABLE: menu_item_extras
// ============================================
export interface MenuItemExtra {
  id: string;
  menu_item_id: string;
  name: string;
  price: number;
  is_available: boolean;
  created_at: string;
}

// ============================================
// TABLE: livreur_badges
// ============================================
export interface LivreurBadge {
  id: string;
  livreur_id: string;
  badge_type: string;
  earned_at: string;
}

// ============================================
// TABLE: livreur_bonuses
// ============================================
export interface LivreurBonus {
  id: string;
  livreur_id: string;
  bonus_type: string;
  amount: number;
  description: string | null;
  order_id: string | null;
  earned_at: string;
}

// ============================================
// TABLE: tier_config
// ============================================
export interface TierConfig {
  tier: LivreurTier;
  commission_rate: number;
  min_deliveries: number;
  min_rating: number;
  max_cancellation_rate: number;
  priority_level: number;
  weekend_bonus: number;
  description: string | null;
}

// ============================================
// TABLE: referrals
// ============================================
export interface Referral {
  id: string;
  referrer_id: string;
  referred_id: string;
  referral_code: string;
  status: 'pending' | 'completed' | 'rewarded';
  referrer_reward: number;
  referred_reward: number;
  created_at: string;
  completed_at: string | null;
}

// ============================================
// TYPES UTILITAIRES POUR LES INSERTS
// ============================================

export type OrderInsert = Omit<Order, 'id' | 'created_at' | 'updated_at'> & {
  id?: string;
  created_at?: string;
  updated_at?: string;
};

export type ProfileInsert = Omit<Profile, 'created_at' | 'updated_at'> & {
  created_at?: string;
  updated_at?: string;
};

// ============================================
// MAPPING DES NOMS DE COLONNES
// Pour éviter les erreurs de nommage
// ============================================
export const COLUMN_NAMES = {
  orders: {
    // ⚠️ NOMS CORRECTS (SQL)
    livreur_id: 'livreur_id', // PAS driver_id
    total: 'total', // PAS total_amount
    delivery_latitude: 'delivery_latitude', // PAS delivery_lat
    delivery_longitude: 'delivery_longitude', // PAS delivery_lng
    prepared_at: 'prepared_at', // PAS preparing_at
  },
} as const;
