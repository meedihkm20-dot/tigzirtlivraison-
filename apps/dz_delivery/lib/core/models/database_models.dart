/// ============================================================
/// MODÈLES DART - GÉNÉRÉS DEPUIS LE SCHÉMA SQL
/// ============================================================
///
/// ⚠️  NE PAS MODIFIER MANUELLEMENT
/// Ces modèles doivent correspondre EXACTEMENT au schéma SQL
/// Source: supabase/migrations/000_complete_schema.sql
///
/// RÈGLES:
/// 1. Tout changement commence par le SQL
/// 2. Puis on met à jour backend/src/types/database.types.ts
/// 3. Puis on met à jour ce fichier
/// ============================================================

// ============================================
// ENUMS (correspondent aux types SQL)
// ============================================

enum UserRole {
  customer,
  restaurant,
  livreur,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.customer,
    );
  }
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  picked_up,
  delivering,
  delivered,
  cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.picked_up:
        return 'Récupérée';
      case OrderStatus.delivering:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }
}

enum PaymentMethod {
  cash,
  card,
  edahabia,
  cib;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

enum VehicleType {
  moto,
  velo,
  voiture;

  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VehicleType.moto,
    );
  }
}

enum LivreurTier {
  bronze,
  silver,
  gold,
  diamond;

  static LivreurTier fromString(String value) {
    return LivreurTier.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LivreurTier.bronze,
    );
  }
}

// ============================================
// TABLE: profiles
// ============================================
class ProfileModel {
  final String id;
  final UserRole role;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final String? fcmToken;
  final int loyaltyPoints;
  final int totalOrders;
  final double totalSpent;
  final String? referralCode;
  final String? referredBy;
  final double referralEarnings;
  final bool phoneVerified;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.role,
    this.phone,
    this.fullName,
    this.avatarUrl,
    this.address,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.fcmToken,
    this.loyaltyPoints = 0,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.referralCode,
    this.referredBy,
    this.referralEarnings = 0,
    this.phoneVerified = false,
    this.emailVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'customer'),
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      fcmToken: json['fcm_token'] as String?,
      loyaltyPoints: json['loyalty_points'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      referralEarnings: (json['referral_earnings'] as num?)?.toDouble() ?? 0,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'phone': phone,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'is_active': isActive,
        'fcm_token': fcmToken,
        'loyalty_points': loyaltyPoints,
        'total_orders': totalOrders,
        'total_spent': totalSpent,
        'referral_code': referralCode,
        'referred_by': referredBy,
        'referral_earnings': referralEarnings,
        'phone_verified': phoneVerified,
        'email_verified': emailVerified,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}


// ============================================
// TABLE: restaurants
// ============================================
class RestaurantModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;
  final String? phone;
  final String address;
  final double latitude;
  final double longitude;
  final String? cuisineType;
  final String openingTime;
  final String closingTime;
  final double minOrderAmount;
  final double deliveryFee;
  final int avgPrepTime;
  final double rating;
  final int totalReviews;
  final bool isOpen;
  final bool isVerified;
  final List<String>? coverImages;
  final List<String>? tags;
  final bool acceptsPreorders;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  RestaurantModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.logoUrl,
    this.coverUrl,
    this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.cuisineType,
    this.openingTime = '08:00',
    this.closingTime = '23:00',
    this.minOrderAmount = 0,
    this.deliveryFee = 0,
    this.avgPrepTime = 30,
    this.rating = 0,
    this.totalReviews = 0,
    this.isOpen = true,
    this.isVerified = false,
    this.coverImages,
    this.tags,
    this.acceptsPreorders = false,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      cuisineType: json['cuisine_type'] as String?,
      openingTime: json['opening_time'] as String? ?? '08:00',
      closingTime: json['closing_time'] as String? ?? '23:00',
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      avgPrepTime: json['avg_prep_time'] as int? ?? 30,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      isOpen: json['is_open'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      coverImages: (json['cover_images'] as List?)?.cast<String>(),
      tags: (json['tags'] as List?)?.cast<String>(),
      acceptsPreorders: json['accepts_preorders'] as bool? ?? false,
      fcmToken: json['fcm_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'logo_url': logoUrl,
        'cover_url': coverUrl,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'cuisine_type': cuisineType,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'min_order_amount': minOrderAmount,
        'delivery_fee': deliveryFee,
        'avg_prep_time': avgPrepTime,
        'rating': rating,
        'total_reviews': totalReviews,
        'is_open': isOpen,
        'is_verified': isVerified,
        'cover_images': coverImages,
        'tags': tags,
        'accepts_preorders': acceptsPreorders,
        'fcm_token': fcmToken,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

// ============================================
// TABLE: livreurs
// ============================================
class LivreurModel {
  final String id;
  final String userId;
  final VehicleType vehicleType;
  final String? vehicleNumber;
  final String? licenseNumber;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isAvailable;
  final bool isOnline;
  final bool isVerified;
  final double rating;
  final int totalDeliveries;
  final double totalEarnings;
  final double totalDistanceKm;
  final int? avgDeliveryTime;
  final double acceptanceRate;
  final LivreurTier tier;
  final int tierProgress;
  final int weeklyDeliveries;
  final int monthlyDeliveries;
  final double cancellationRate;
  final int streakDays;
  final DateTime? lastActiveDate;
  final double bonusEarned;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  LivreurModel({
    required this.id,
    required this.userId,
    this.vehicleType = VehicleType.moto,
    this.vehicleNumber,
    this.licenseNumber,
    this.currentLatitude,
    this.currentLongitude,
    this.isAvailable = false,
    this.isOnline = false,
    this.isVerified = false,
    this.rating = 5.0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0,
    this.totalDistanceKm = 0,
    this.avgDeliveryTime,
    this.acceptanceRate = 100,
    this.tier = LivreurTier.bronze,
    this.tierProgress = 0,
    this.weeklyDeliveries = 0,
    this.monthlyDeliveries = 0,
    this.cancellationRate = 0,
    this.streakDays = 0,
    this.lastActiveDate,
    this.bonusEarned = 0,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LivreurModel.fromJson(Map<String, dynamic> json) {
    return LivreurModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleType: VehicleType.fromString(json['vehicle_type'] as String? ?? 'moto'),
      vehicleNumber: json['vehicle_number'] as String?,
      licenseNumber: json['license_number'] as String?,
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
      isAvailable: json['is_available'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0,
      avgDeliveryTime: json['avg_delivery_time'] as int?,
      acceptanceRate: (json['acceptance_rate'] as num?)?.toDouble() ?? 100,
      tier: LivreurTier.fromString(json['tier'] as String? ?? 'bronze'),
      tierProgress: json['tier_progress'] as int? ?? 0,
      weeklyDeliveries: json['weekly_deliveries'] as int? ?? 0,
      monthlyDeliveries: json['monthly_deliveries'] as int? ?? 0,
      cancellationRate: (json['cancellation_rate'] as num?)?.toDouble() ?? 0,
      streakDays: json['streak_days'] as int? ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.parse(json['last_active_date'] as String)
          : null,
      bonusEarned: (json['bonus_earned'] as num?)?.toDouble() ?? 0,
      fcmToken: json['fcm_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'vehicle_type': vehicleType.name,
        'vehicle_number': vehicleNumber,
        'license_number': licenseNumber,
        'current_latitude': currentLatitude,
        'current_longitude': currentLongitude,
        'is_available': isAvailable,
        'is_online': isOnline,
        'is_verified': isVerified,
        'rating': rating,
        'total_deliveries': totalDeliveries,
        'total_earnings': totalEarnings,
        'total_distance_km': totalDistanceKm,
        'avg_delivery_time': avgDeliveryTime,
        'acceptance_rate': acceptanceRate,
        'tier': tier.name,
        'tier_progress': tierProgress,
        'weekly_deliveries': weeklyDeliveries,
        'monthly_deliveries': monthlyDeliveries,
        'cancellation_rate': cancellationRate,
        'streak_days': streakDays,
        'last_active_date': lastActiveDate?.toIso8601String(),
        'bonus_earned': bonusEarned,
        'fcm_token': fcmToken,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}


// ============================================
// TABLE: orders
// ⚠️ COLONNES CRITIQUES - NOMS EXACTS DU SQL
// ============================================
class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String restaurantId;
  final String? livreurId; // ⚠️ SQL: "livreur_id" (PAS "driver_id")
  final OrderStatus status;

  // Adresse de livraison
  final String deliveryAddress;
  final double deliveryLatitude; // ⚠️ SQL: "delivery_latitude" (PAS "delivery_lat")
  final double deliveryLongitude; // ⚠️ SQL: "delivery_longitude" (PAS "delivery_lng")
  final String? deliveryInstructions;

  // Montants
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total; // ⚠️ SQL: "total" (PAS "total_amount")

  // Paiement
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;

  // Timestamps
  final DateTime? estimatedDeliveryTime;
  final DateTime? confirmedAt;
  final DateTime? preparedAt; // ⚠️ SQL: "prepared_at" (PAS "preparing_at")
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  // Colonnes additionnelles
  final String? confirmationCode;
  final double livreurCommission;
  final double adminCommission;
  final double restaurantAmount;
  final DateTime? livreurAcceptedAt;
  final DateTime? codeVerifiedAt;
  final String? promotionId;
  final String? promoCode;
  final double promoDiscount;
  final int? currentEtaMinutes;
  final double? distanceRemainingKm;
  final double tipAmount;
  final DateTime? tipPaidAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations (optionnelles, pour les jointures)
  final RestaurantModel? restaurant;
  final LivreurModel? livreur;
  final List<OrderItemModel>? items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.restaurantId,
    this.livreurId,
    required this.status,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.deliveryInstructions,
    required this.subtotal,
    this.deliveryFee = 0,
    this.serviceFee = 0,
    this.discount = 0,
    required this.total,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.pending,
    this.estimatedDeliveryTime,
    this.confirmedAt,
    this.preparedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    this.confirmationCode,
    this.livreurCommission = 0,
    this.adminCommission = 0,
    this.restaurantAmount = 0,
    this.livreurAcceptedAt,
    this.codeVerifiedAt,
    this.promotionId,
    this.promoCode,
    this.promoDiscount = 0,
    this.currentEtaMinutes,
    this.distanceRemainingKm,
    this.tipAmount = 0,
    this.tipPaidAt,
    required this.createdAt,
    required this.updatedAt,
    this.restaurant,
    this.livreur,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerId: json['customer_id'] as String,
      restaurantId: json['restaurant_id'] as String,
      livreurId: json['livreur_id'] as String?, // ⚠️ Nom SQL correct
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      deliveryAddress: json['delivery_address'] as String,
      deliveryLatitude: (json['delivery_latitude'] as num).toDouble(), // ⚠️ Nom SQL correct
      deliveryLongitude: (json['delivery_longitude'] as num).toDouble(), // ⚠️ Nom SQL correct
      deliveryInstructions: json['delivery_instructions'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(), // ⚠️ Nom SQL correct
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String? ?? 'cash'),
      paymentStatus: PaymentStatus.fromString(json['payment_status'] as String? ?? 'pending'),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'] as String)
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      preparedAt: json['prepared_at'] != null // ⚠️ Nom SQL correct
          ? DateTime.parse(json['prepared_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      confirmationCode: json['confirmation_code'] as String?,
      livreurCommission: (json['livreur_commission'] as num?)?.toDouble() ?? 0,
      adminCommission: (json['admin_commission'] as num?)?.toDouble() ?? 0,
      restaurantAmount: (json['restaurant_amount'] as num?)?.toDouble() ?? 0,
      livreurAcceptedAt: json['livreur_accepted_at'] != null
          ? DateTime.parse(json['livreur_accepted_at'] as String)
          : null,
      codeVerifiedAt: json['code_verified_at'] != null
          ? DateTime.parse(json['code_verified_at'] as String)
          : null,
      promotionId: json['promotion_id'] as String?,
      promoCode: json['promo_code'] as String?,
      promoDiscount: (json['promo_discount'] as num?)?.toDouble() ?? 0,
      currentEtaMinutes: json['current_eta_minutes'] as int?,
      distanceRemainingKm: (json['distance_remaining_km'] as num?)?.toDouble(),
      tipAmount: (json['tip_amount'] as num?)?.toDouble() ?? 0,
      tipPaidAt: json['tip_paid_at'] != null
          ? DateTime.parse(json['tip_paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // Relations
      restaurant: json['restaurant'] != null
          ? RestaurantModel.fromJson(json['restaurant'] as Map<String, dynamic>)
          : null,
      livreur: json['livreur'] != null
          ? LivreurModel.fromJson(json['livreur'] as Map<String, dynamic>)
          : null,
      items: json['order_items'] != null
          ? (json['order_items'] as List)
              .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
        'customer_id': customerId,
        'restaurant_id': restaurantId,
        'livreur_id': livreurId,
        'status': status.name,
        'delivery_address': deliveryAddress,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
        'delivery_instructions': deliveryInstructions,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'service_fee': serviceFee,
        'discount': discount,
        'total': total,
        'payment_method': paymentMethod.name,
        'payment_status': paymentStatus.name,
        'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
        'prepared_at': preparedAt?.toIso8601String(),
        'picked_up_at': pickedUpAt?.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
        'cancelled_at': cancelledAt?.toIso8601String(),
        'cancellation_reason': cancellationReason,
        'confirmation_code': confirmationCode,
        'livreur_commission': livreurCommission,
        'admin_commission': adminCommission,
        'restaurant_amount': restaurantAmount,
        'livreur_accepted_at': livreurAcceptedAt?.toIso8601String(),
        'code_verified_at': codeVerifiedAt?.toIso8601String(),
        'promotion_id': promotionId,
        'promo_code': promoCode,
        'promo_discount': promoDiscount,
        'current_eta_minutes': currentEtaMinutes,
        'distance_remaining_km': distanceRemainingKm,
        'tip_amount': tipAmount,
        'tip_paid_at': tipPaidAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Créer une copie avec des modifications
  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? restaurantId,
    String? livreurId,
    OrderStatus? status,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryInstructions,
    double? subtotal,
    double? deliveryFee,
    double? serviceFee,
    double? discount,
    double? total,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    DateTime? estimatedDeliveryTime,
    DateTime? confirmedAt,
    DateTime? preparedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? confirmationCode,
    double? livreurCommission,
    double? adminCommission,
    double? restaurantAmount,
    DateTime? livreurAcceptedAt,
    DateTime? codeVerifiedAt,
    String? promotionId,
    String? promoCode,
    double? promoDiscount,
    int? currentEtaMinutes,
    double? distanceRemainingKm,
    double? tipAmount,
    DateTime? tipPaidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    RestaurantModel? restaurant,
    LivreurModel? livreur,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      livreurId: livreurId ?? this.livreurId,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      preparedAt: preparedAt ?? this.preparedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      livreurCommission: livreurCommission ?? this.livreurCommission,
      adminCommission: adminCommission ?? this.adminCommission,
      restaurantAmount: restaurantAmount ?? this.restaurantAmount,
      livreurAcceptedAt: livreurAcceptedAt ?? this.livreurAcceptedAt,
      codeVerifiedAt: codeVerifiedAt ?? this.codeVerifiedAt,
      promotionId: promotionId ?? this.promotionId,
      promoCode: promoCode ?? this.promoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      currentEtaMinutes: currentEtaMinutes ?? this.currentEtaMinutes,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      tipAmount: tipAmount ?? this.tipAmount,
      tipPaidAt: tipPaidAt ?? this.tipPaidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      restaurant: restaurant ?? this.restaurant,
      livreur: livreur ?? this.livreur,
      items: items ?? this.items,
    );
  }
}

// ============================================
// TABLE: order_items
// ============================================
class OrderItemModel {
  final String id;
  final String orderId;
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;
  final DateTime createdAt;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
    required this.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      menuItemId: json['menu_item_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      specialInstructions: json['special_instructions'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'menu_item_id': menuItemId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'special_instructions': specialInstructions,
        'created_at': createdAt.toIso8601String(),
      };

  double get totalPrice => price * quantity;
}

// ============================================
// TABLE: menu_items
// ============================================
class MenuItemModel {
  final String id;
  final String restaurantId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isPopular;
  final int prepTime;
  final int? calories;
  final bool isVegetarian;
  final bool isSpicy;
  final List<String>? allergens;
  final int orderCount;
  final int imageWidth;
  final int imageHeight;
  final List<String>? ingredients;
  final Map<String, dynamic>? nutritionInfo;
  final bool isDailySpecial;
  final double? dailySpecialPrice;
  final double avgRating;
  final int totalReviews;
  final DateTime? lastOrderedAt;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.isPopular = false,
    this.prepTime = 15,
    this.calories,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.allergens,
    this.orderCount = 0,
    this.imageWidth = 500,
    this.imageHeight = 500,
    this.ingredients,
    this.nutritionInfo,
    this.isDailySpecial = false,
    this.dailySpecialPrice,
    this.avgRating = 0,
    this.totalReviews = 0,
    this.lastOrderedAt,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      isPopular: json['is_popular'] as bool? ?? false,
      prepTime: json['prep_time'] as int? ?? 15,
      calories: json['calories'] as int?,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isSpicy: json['is_spicy'] as bool? ?? false,
      allergens: (json['allergens'] as List?)?.cast<String>(),
      orderCount: json['order_count'] as int? ?? 0,
      imageWidth: json['image_width'] as int? ?? 500,
      imageHeight: json['image_height'] as int? ?? 500,
      ingredients: (json['ingredients'] as List?)?.cast<String>(),
      nutritionInfo: json['nutrition_info'] as Map<String, dynamic>?,
      isDailySpecial: json['is_daily_special'] as bool? ?? false,
      dailySpecialPrice: (json['daily_special_price'] as num?)?.toDouble(),
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      lastOrderedAt: json['last_ordered_at'] != null
          ? DateTime.parse(json['last_ordered_at'] as String)
          : null,
      tags: (json['tags'] as List?)?.cast<String>(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurant_id': restaurantId,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'is_available': isAvailable,
        'is_popular': isPopular,
        'prep_time': prepTime,
        'calories': calories,
        'is_vegetarian': isVegetarian,
        'is_spicy': isSpicy,
        'allergens': allergens,
        'order_count': orderCount,
        'image_width': imageWidth,
        'image_height': imageHeight,
        'ingredients': ingredients,
        'nutrition_info': nutritionInfo,
        'is_daily_special': isDailySpecial,
        'daily_special_price': dailySpecialPrice,
        'avg_rating': avgRating,
        'total_reviews': totalReviews,
        'last_ordered_at': lastOrderedAt?.toIso8601String(),
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Prix effectif (prend en compte le prix spécial du jour)
  double get effectivePrice => isDailySpecial && dailySpecialPrice != null
      ? dailySpecialPrice!
      : price;
}

// ============================================
// TABLE: transactions
// ============================================
class TransactionModel {
  final String id;
  final String orderId;
  final String type; // 'livreur_earning' | 'admin_commission' | 'restaurant_payment'
  final double amount;
  final String? recipientId;
  final String status; // 'pending' | 'completed' | 'cancelled'
  final String? description;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.orderId,
    required this.type,
    required this.amount,
    this.recipientId,
    this.status = 'pending',
    this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      recipientId: json['recipient_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'type': type,
        'amount': amount,
        'recipient_id': recipientId,
        'status': status,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}


// ============================================
// TABLE: livreur_locations
// ============================================
class LivreurLocationModel {
  final String id;
  final String livreurId;
  final String? orderId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;

  LivreurLocationModel({
    required this.id,
    required this.livreurId,
    this.orderId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.recordedAt,
  });

  factory LivreurLocationModel.fromJson(Map<String, dynamic> json) {
    return LivreurLocationModel(
      id: json['id'] as String,
      livreurId: json['livreur_id'] as String,
      orderId: json['order_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'livreur_id': livreurId,
        'order_id': orderId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
        'recorded_at': recordedAt.toIso8601String(),
      };
}

// ============================================
// TABLE: order_messages
// ============================================
class OrderMessageModel {
  final String id;
  final String orderId;
  final String senderId;
  final String senderType; // 'customer' | 'livreur' | 'restaurant' | 'system'
  final String message;
  final bool isRead;
  final DateTime createdAt;

  OrderMessageModel({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderType,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory OrderMessageModel.fromJson(Map<String, dynamic> json) {
    return OrderMessageModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      senderId: json['sender_id'] as String,
      senderType: json['sender_type'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'sender_id': senderId,
        'sender_type': senderType,
        'message': message,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };
}

// ============================================
// TABLE: saved_addresses
// ============================================
class SavedAddressModel {
  final String id;
  final String customerId;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final String? instructions;
  final bool isDefault;
  final DateTime createdAt;

  SavedAddressModel({
    required this.id,
    required this.customerId,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.instructions,
    this.isDefault = false,
    required this.createdAt,
  });

  factory SavedAddressModel.fromJson(Map<String, dynamic> json) {
    return SavedAddressModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      label: json['label'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      instructions: json['instructions'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'instructions': instructions,
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
      };
}

// ============================================
// TABLE: promotions
// ============================================
class PromotionModel {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final String discountType; // 'percentage' | 'fixed'
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final String? code;
  final bool isActive;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int? usageLimit;
  final int usageCount;
  final DateTime createdAt;

  PromotionModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.code,
    this.isActive = true,
    required this.startsAt,
    this.endsAt,
    this.usageLimit,
    this.usageCount = 0,
    required this.createdAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      discountType: json['discount_type'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      code: json['code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurant_id': restaurantId,
        'name': name,
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_order_amount': minOrderAmount,
        'max_discount': maxDiscount,
        'code': code,
        'is_active': isActive,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'usage_limit': usageLimit,
        'usage_count': usageCount,
        'created_at': createdAt.toIso8601String(),
      };

  /// Vérifie si la promotion est valide
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startsAt) &&
        (endsAt == null || now.isBefore(endsAt!)) &&
        (usageLimit == null || usageCount < usageLimit!);
  }

  /// Calcule la réduction pour un montant donné
  double calculateDiscount(double orderAmount) {
    if (orderAmount < minOrderAmount) return 0;
    
    double discount;
    if (discountType == 'percentage') {
      discount = orderAmount * discountValue / 100;
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = discountValue;
    }
    
    return discount;
  }
}

// ============================================
// TABLE: notifications
// ============================================
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String notificationType;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.data,
    this.isRead = false,
    this.notificationType = 'system',
    required this.sentAt,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      notificationType: json['notification_type'] as String? ?? 'system',
      sentAt: DateTime.parse(json['sent_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'is_read': isRead,
        'notification_type': notificationType,
        'sent_at': sentAt.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

// ============================================
// TABLE: reviews
// ============================================
class ReviewModel {
  final String id;
  final String orderId;
  final String customerId;
  final String restaurantId;
  final String? livreurId;
  final int? restaurantRating;
  final int? livreurRating;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.restaurantId,
    this.livreurId,
    this.restaurantRating,
    this.livreurRating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      customerId: json['customer_id'] as String,
      restaurantId: json['restaurant_id'] as String,
      livreurId: json['livreur_id'] as String?,
      restaurantRating: json['restaurant_rating'] as int?,
      livreurRating: json['livreur_rating'] as int?,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'customer_id': customerId,
        'restaurant_id': restaurantId,
        'livreur_id': livreurId,
        'restaurant_rating': restaurantRating,
        'livreur_rating': livreurRating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };
}

// ============================================
// TABLE: livreur_badges
// ============================================
class LivreurBadgeModel {
  final String id;
  final String livreurId;
  final String badgeType;
  final DateTime earnedAt;

  LivreurBadgeModel({
    required this.id,
    required this.livreurId,
    required this.badgeType,
    required this.earnedAt,
  });

  factory LivreurBadgeModel.fromJson(Map<String, dynamic> json) {
    return LivreurBadgeModel(
      id: json['id'] as String,
      livreurId: json['livreur_id'] as String,
      badgeType: json['badge_type'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'livreur_id': livreurId,
        'badge_type': badgeType,
        'earned_at': earnedAt.toIso8601String(),
      };
}

// ============================================
// TABLE: livreur_bonuses
// ============================================
class LivreurBonusModel {
  final String id;
  final String livreurId;
  final String bonusType;
  final double amount;
  final String? description;
  final String? orderId;
  final DateTime earnedAt;

  LivreurBonusModel({
    required this.id,
    required this.livreurId,
    required this.bonusType,
    required this.amount,
    this.description,
    this.orderId,
    required this.earnedAt,
  });

  factory LivreurBonusModel.fromJson(Map<String, dynamic> json) {
    return LivreurBonusModel(
      id: json['id'] as String,
      livreurId: json['livreur_id'] as String,
      bonusType: json['bonus_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      orderId: json['order_id'] as String?,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'livreur_id': livreurId,
        'bonus_type': bonusType,
        'amount': amount,
        'description': description,
        'order_id': orderId,
        'earned_at': earnedAt.toIso8601String(),
      };
}
