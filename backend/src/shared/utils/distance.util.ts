/**
 * Calculate distance between two GPS coordinates using Haversine formula
 * @param lat1 Latitude of point 1
 * @param lon1 Longitude of point 1
 * @param lat2 Latitude of point 2
 * @param lon2 Longitude of point 2
 * @returns Distance in kilometers
 */
export function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  
  return Math.round(distance * 100) / 100; // Round to 2 decimal places
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}

/**
 * Calculate estimated delivery time based on distance
 * @param distanceKm Distance in kilometers
 * @param preparationTime Restaurant preparation time in minutes
 * @returns Estimated delivery time in minutes
 */
export function calculateEstimatedDeliveryTime(
  distanceKm: number,
  preparationTime: number = 30,
): number {
  // Average speed: 25 km/h for delivery (accounting for traffic, stops, etc.)
  const averageSpeedKmH = 25;
  const deliveryTimeMinutes = (distanceKm / averageSpeedKmH) * 60;
  
  // Add buffer time (5 minutes for pickup, 5 minutes for delivery)
  const bufferTime = 10;
  
  return Math.ceil(preparationTime + deliveryTimeMinutes + bufferTime);
}

/**
 * Calculate delivery fee based on distance
 * @param distanceKm Distance in kilometers
 * @param basePrice Base delivery price
 * @param pricePerKm Price per kilometer
 * @returns Delivery fee in DA
 */
export function calculateDeliveryFee(
  distanceKm: number,
  basePrice: number = 100,
  pricePerKm: number = 30,
): number {
  const fee = basePrice + (distanceKm * pricePerKm);
  return Math.ceil(fee / 10) * 10; // Round to nearest 10 DA
}

/**
 * Check if a point is within a radius of another point
 * @param centerLat Center latitude
 * @param centerLon Center longitude
 * @param pointLat Point latitude
 * @param pointLon Point longitude
 * @param radiusKm Radius in kilometers
 * @returns True if point is within radius
 */
export function isWithinRadius(
  centerLat: number,
  centerLon: number,
  pointLat: number,
  pointLon: number,
  radiusKm: number,
): boolean {
  const distance = calculateDistance(centerLat, centerLon, pointLat, pointLon);
  return distance <= radiusKm;
}
