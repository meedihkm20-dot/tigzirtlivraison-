import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  private supabase: SupabaseClient;
  private readonly logger = new Logger(SupabaseService.name);

  constructor(private configService: ConfigService) {
    const url = this.configService.get<string>('SUPABASE_URL') || '';
    const key = this.configService.get<string>('SUPABASE_SERVICE_KEY') || '';

    if (!url || !key) {
      this.logger.warn('⚠️ Supabase credentials not configured');
    }

    this.supabase = createClient(url, key);
  }

  getClient(): SupabaseClient {
    return this.supabase;
  }

  async getOrderById(orderId: string) {
    const { data, error } = await this.supabase
      .from('orders')
      .select('*, order_items(*), restaurant:restaurants(*)')
      .eq('id', orderId)
      .single();

    if (error) throw error;
    return data;
  }

  async updateOrderStatus(orderId: string, status: string) {
    const { data, error } = await this.supabase
      .from('orders')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', orderId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getRestaurantById(restaurantId: string) {
    const { data, error } = await this.supabase
      .from('restaurants')
      .select('*')
      .eq('id', restaurantId)
      .single();

    if (error) throw error;
    return data;
  }

  async getUserById(userId: string) {
    const { data, error } = await this.supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) throw error;
    return data;
  }
}
