import { Injectable, BadRequestException, ForbiddenException, Logger } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';
import { VerifyDeliveryDto } from './dto/verify-delivery.dto';

@Injectable()
export class DeliveryService {
  private readonly logger = new Logger(DeliveryService.name);

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

  /**
   * Vérifier le code de confirmation et finaliser la livraison
   * Migration de l'Edge Function verify-delivery
   */
  async verifyDelivery(userId: string, dto: VerifyDeliveryDto) {
    const supabase = this.supabaseService.getClient();
    const { order_id, verification_code } = dto;

    // Vérifier que l'utilisateur est un livreur vérifié
    const { data: livreur, error: livreurError } = await supabase
      .from('livreurs')
      .select('id, is_verified')
      .eq('user_id', userId)
      .single();

    if (livreurError || !livreur) {
      throw new BadRequestException('Livreur non trouvé');
    }

    if (!livreur.is_verified) {
      throw new ForbiddenException('Livreur non vérifié');
    }

    // Récupérer la commande
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('id, status, confirmation_code, livreur_id, livreur_commission')
      .eq('id', order_id)
      .single();

    if (orderError || !order) {
      throw new BadRequestException('Commande non trouvée');
    }

    // Vérifier que le livreur est bien assigné à cette commande
    if (order.livreur_id !== livreur.id) {
      throw new ForbiddenException("Vous n'êtes pas assigné à cette commande");
    }

    // Vérifier le statut
    if (!['picked_up', 'delivering'].includes(order.status)) {
      throw new BadRequestException(`Statut invalide pour livraison: ${order.status}`);
    }

    // VÉRIFICATION DU CODE (CRITIQUE)
    if (order.confirmation_code !== verification_code.toUpperCase()) {
      this.logger.warn(
        `[SECURITY] Code incorrect pour commande ${order_id} par livreur ${livreur.id}`,
      );
      throw new BadRequestException('Code de confirmation incorrect');
    }

    // Code correct - Finaliser la livraison
    const now = new Date().toISOString();

    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: 'delivered',
        delivered_at: now,
        code_verified_at: now,
      })
      .eq('id', order_id);

    if (updateError) {
      throw new BadRequestException(`Erreur finalisation: ${updateError.message}`);
    }

    // Libérer le livreur
    await supabase
      .from('livreurs')
      .update({ is_available: true })
      .eq('id', livreur.id);

    // Incrémenter les stats du livreur (si la fonction RPC existe)
    try {
      await supabase.rpc('increment_livreur_stats', {
        p_livreur_id: livreur.id,
        p_commission: order.livreur_commission || 0,
      });
    } catch (e) {
      this.logger.warn(`Stats update skipped: ${e.message}`);
    }

    this.logger.log(`Delivery verified: ${order_id} by livreur ${livreur.id}`);
    return {
      success: true,
      message: 'Livraison confirmée avec succès!',
      order_id,
      delivered_at: now,
      commission: order.livreur_commission,
    };
  }
}
