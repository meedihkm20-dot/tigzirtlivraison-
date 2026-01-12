// Order statuses
export const ORDER_STATUSES = {
  PENDING: 'pending',
  ACCEPTED: 'accepted',
  PREPARING: 'preparing',
  READY: 'ready',
  PICKED_UP: 'picked_up',
  DELIVERING: 'delivering',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
} as const;

// User roles
export const USER_ROLES = {
  USER: 'user',
  RESTAURANT: 'restaurant',
  LIVREUR: 'livreur',
  ADMIN: 'admin',
} as const;

// Vehicle types
export const VEHICLE_TYPES = {
  MOTO: 'moto',
  VELO: 'velo',
  VOITURE: 'voiture',
} as const;

// Payment methods
export const PAYMENT_METHODS = {
  CASH: 'cash',
  CARD: 'card',
  WALLET: 'wallet',
} as const;

// Payment statuses
export const PAYMENT_STATUSES = {
  PENDING: 'pending',
  COMPLETED: 'completed',
  FAILED: 'failed',
  REFUNDED: 'refunded',
} as const;

// Notification types
export const NOTIFICATION_TYPES = {
  NEW_ORDER: 'new_order',
  ORDER_STATUS: 'order_status',
  NEW_DELIVERY: 'new_delivery',
  PAYMENT: 'payment',
  PROMOTION: 'promotion',
  SYSTEM: 'system',
} as const;

// Default values
export const DEFAULTS = {
  COMMISSION_RATE: 10, // 10%
  MIN_ORDER_AMOUNT: 500, // 500 DA
  DELIVERY_RADIUS_KM: 5,
  AVG_PREPARATION_TIME: 30, // minutes
  BASE_DELIVERY_FEE: 100, // DA
  PRICE_PER_KM: 30, // DA
} as const;

// Algerian wilayas
export const WILAYAS = [
  'Adrar', 'Chlef', 'Laghouat', 'Oum El Bouaghi', 'Batna', 'Béjaïa', 'Biskra',
  'Béchar', 'Blida', 'Bouira', 'Tamanrasset', 'Tébessa', 'Tlemcen', 'Tiaret',
  'Tizi Ouzou', 'Alger', 'Djelfa', 'Jijel', 'Sétif', 'Saïda', 'Skikda',
  'Sidi Bel Abbès', 'Annaba', 'Guelma', 'Constantine', 'Médéa', 'Mostaganem',
  'M\'Sila', 'Mascara', 'Ouargla', 'Oran', 'El Bayadh', 'Illizi', 'Bordj Bou Arréridj',
  'Boumerdès', 'El Tarf', 'Tindouf', 'Tissemsilt', 'El Oued', 'Khenchela',
  'Souk Ahras', 'Tipaza', 'Mila', 'Aïn Defla', 'Naâma', 'Aïn Témouchent',
  'Ghardaïa', 'Relizane', 'Timimoun', 'Bordj Badji Mokhtar', 'Ouled Djellal',
  'Béni Abbès', 'In Salah', 'In Guezzam', 'Touggourt', 'Djanet', 'El M\'Ghair', 'El Meniaa',
] as const;
