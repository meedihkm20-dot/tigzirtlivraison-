import { Injectable, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';

@Injectable()
export class CacheService {
  constructor(@Inject(CACHE_MANAGER) private cacheManager: Cache) {}

  async get<T>(key: string): Promise<T | undefined> {
    return this.cacheManager.get<T>(key);
  }

  async set(key: string, value: any, ttl?: number): Promise<void> {
    await this.cacheManager.set(key, value, ttl);
  }

  async del(key: string): Promise<void> {
    await this.cacheManager.del(key);
  }

  async reset(): Promise<void> {
    // Reset is not available in all cache implementations
    // Use store-specific reset if needed
  }

  // Helper methods for common cache patterns
  async getOrSet<T>(
    key: string,
    factory: () => Promise<T>,
    ttl?: number,
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== undefined) {
      return cached;
    }

    const value = await factory();
    await this.set(key, value, ttl);
    return value;
  }

  // Cache keys helpers
  static restaurantKey(id: string): string {
    return `restaurant:${id}`;
  }

  static restaurantMenuKey(id: string): string {
    return `restaurant:${id}:menu`;
  }

  static restaurantListKey(city: string): string {
    return `restaurants:${city}`;
  }

  static userKey(id: string): string {
    return `user:${id}`;
  }

  static orderKey(id: string): string {
    return `order:${id}`;
  }

  // Invalidation helpers
  async invalidateRestaurant(id: string): Promise<void> {
    await this.del(CacheService.restaurantKey(id));
    await this.del(CacheService.restaurantMenuKey(id));
  }

  async invalidateRestaurantList(city: string): Promise<void> {
    await this.del(CacheService.restaurantListKey(city));
  }
}
