/// Configuration Supabase partagée entre les 3 apps
/// 
/// IMPORTANT: Remplacez ces valeurs par vos vraies clés Supabase
/// après avoir créé votre projet sur https://supabase.com
/// 
/// Pour obtenir ces valeurs:
/// 1. Allez sur https://supabase.com
/// 2. Ouvrez votre projet
/// 3. Settings → API
/// 4. Copiez "Project URL" et "anon public" key

class SupabaseConfig {
  // TODO: Remplacez par votre URL Supabase
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';
  
  // TODO: Remplacez par votre clé anon Supabase
  static const String anonKey = 'YOUR_ANON_KEY';
  
  // Tables
  static const String profilesTable = 'profiles';
  static const String restaurantsTable = 'restaurants';
  static const String menuCategoriesTable = 'menu_categories';
  static const String menuItemsTable = 'menu_items';
  static const String livreursTable = 'livreurs';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String reviewsTable = 'reviews';
  static const String livreurLocationsTable = 'livreur_locations';
  static const String notificationsTable = 'notifications';
  static const String fcmTokensTable = 'fcm_tokens';
  
  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String restaurantImagesBucket = 'restaurant-images';
  static const String menuImagesBucket = 'menu-images';
  
  // Order statuses
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusPreparing = 'preparing';
  static const String statusReady = 'ready';
  static const String statusPickedUp = 'picked_up';
  static const String statusDelivering = 'delivering';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';
  
  // User roles
  static const String roleCustomer = 'customer';
  static const String roleRestaurant = 'restaurant';
  static const String roleLivreur = 'livreur';
  static const String roleAdmin = 'admin';
}
