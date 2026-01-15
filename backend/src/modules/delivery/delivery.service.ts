import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';

@Injectable()
export class DeliveryService {
  constructor(private supabaseService: SupabaseService) {}

  /**
   * Calculer le prix de livraison (côté serveur = anti-triche)
   */
  calculateDeliveryPrice(distanceKm: number, zone: string): number {
    const baseFee = 100; // 100 DA minimum
    const perKmRate = 30; // 30 DA par km

    const zoneMultipliers: Record<string, number> = {
      tigzirt: 1.0,
      azazga: 1.2,
      'tizi-ouzou': 1.5,
      autres: 2.0,
    };

    const multiplier = zoneMultipliers[zone] || zoneMultipliers['autres'];
    const price = (baseFee + distanceKm * perKmRate) * multiplier;

    return Math.ceil(price / 10) * 10; // Arrondir à 10 DA
  }

  /**
   * Estimer le temps de livraison
   */
  calculateEstimatedTime(distanceKm: number, preparationTime: number): number {
    const avgSpeedKmH = 25;
    const deliveryTimeMin = (distanceKm / avgSpeedKmH) * 60;
    const bufferMin = 5;

    return Math.ceil(preparationTime + deliveryTimeMin + bufferMin);
  }

  /**
   * Trouver et assigner un livreur disponible
   */
  async assignDriver(orderId: string) {
    const supabase = this.supabaseService.getClient();
    const order = await this.supabaseService.getOrderById(orderId);

    // Trouver les livreurs disponibles
    const { data: drivers, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'livreur')
      .eq('is_available', true)
      .eq('is_active', true);

    if (error || !drivers?.length) {
      return null;
    }

    // Prendre le premier disponible (TODO: proximité)
    const driver = drivers[0];

    // Assigner
    await supabase
      .from('orders')
      .update({
        driver_id: driver.id,
        status: 'driver_assigned',
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId);

    return driver;
  }
}
