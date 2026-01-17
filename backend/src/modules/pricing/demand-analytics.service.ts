import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';

@Injectable()
export class DemandAnalyticsService {
  private readonly logger = new Logger(DemandAnalyticsService.name);

  constructor(private readonly supabase: SupabaseService) {}

  async getCurrentDemand(zoneId?: string): Promise<{
    availableDrivers: number;
    pendingOrders: number;
    demandRatio: number;
  }> {
    try {
      // 1. Compter les livreurs disponibles
      const availableDrivers = await this.countAvailableDrivers(zoneId);
      
      // 2. Compter les commandes en attente
      const pendingOrders = await this.countPendingOrders(zoneId);
      
      // 3. Calculer le ratio demande
      const demandRatio = availableDrivers > 0 ? pendingOrders / availableDrivers : 999;

      // 4. Sauvegarder pour analytics
      await this.saveDemandAnalytics(zoneId, availableDrivers, pendingOrders, demandRatio);

      return {
        availableDrivers,
        pendingOrders,
        demandRatio,
      };

    } catch (error) {
      this.logger.error('Error calculating demand:', error);
      return {
        availableDrivers: 1,
        pendingOrders: 1,
        demandRatio: 1.0,
      };
    }
  }

  private async countAvailableDrivers(zoneId?: string): Promise<number> {
    let query = this.supabase.client
      .from('livreurs')
      .select('id', { count: 'exact' })
      .eq('is_available', true)
      .eq('is_online', true);

    // TODO: Filtrer par zone si nécessaire
    // if (zoneId) {
    //   query = query.eq('preferred_zone_id', zoneId);
    // }

    const { count } = await query;
    return count || 0;
  }

  private async countPendingOrders(zoneId?: string): Promise<number> {
    let query = this.supabase.client
      .from('orders')
      .select('id', { count: 'exact' })
      .in('status', ['pending', 'confirmed']);

    // TODO: Filtrer par zone de livraison si nécessaire
    // if (zoneId) {
    //   query = query.eq('delivery_zone_id', zoneId);
    // }

    const { count } = await query;
    return count || 0;
  }

  private async saveDemandAnalytics(
    zoneId: string, 
    availableDrivers: number, 
    pendingOrders: number, 
    demandRatio: number
  ): Promise<void> {
    try {
      const now = new Date();
      
      await this.supabase.client
        .from('demand_analytics')
        .insert({
          zone_id: zoneId,
          pending_orders: pendingOrders,
          available_drivers: availableDrivers,
          demand_ratio: demandRatio,
          hour_of_day: now.getHours(),
          day_of_week: now.getDay() + 1, // 1-7 (Lundi-Dimanche)
        });

    } catch (error) {
      this.logger.warn('Failed to save demand analytics:', error);
    }
  }

  // Méthodes pour l'administration et analytics
  async getDemandHistory(startDate: Date, endDate: Date, zoneId?: string): Promise<any[]> {
    let query = this.supabase.client
      .from('demand_analytics')
      .select('*')
      .gte('recorded_at', startDate.toISOString())
      .lte('recorded_at', endDate.toISOString())
      .order('recorded_at', { ascending: false });

    if (zoneId) {
      query = query.eq('zone_id', zoneId);
    }

    const { data } = await query;
    return data || [];
  }

  async getDemandTrends(): Promise<any> {
    // Tendances par heure de la journée
    const { data: hourlyTrends } = await this.supabase.client
      .from('demand_analytics')
      .select('hour_of_day, demand_ratio')
      .gte('recorded_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()) // 7 jours
      .order('hour_of_day');

    // Tendances par jour de la semaine
    const { data: weeklyTrends } = await this.supabase.client
      .from('demand_analytics')
      .select('day_of_week, demand_ratio')
      .gte('recorded_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()) // 30 jours
      .order('day_of_week');

    return {
      hourlyTrends: this.aggregateTrends(hourlyTrends, 'hour_of_day'),
      weeklyTrends: this.aggregateTrends(weeklyTrends, 'day_of_week'),
    };
  }

  private aggregateTrends(data: any[], groupBy: string): any[] {
    const grouped = {};
    
    data?.forEach(item => {
      const key = item[groupBy];
      if (!grouped[key]) {
        grouped[key] = { sum: 0, count: 0 };
      }
      grouped[key].sum += item.demand_ratio;
      grouped[key].count += 1;
    });

    return Object.entries(grouped).map(([key, value]: [string, any]) => ({
      [groupBy]: parseInt(key),
      averageDemandRatio: value.sum / value.count,
      dataPoints: value.count,
    }));
  }

  async getPeakHours(): Promise<any[]> {
    const { data } = await this.supabase.client
      .from('demand_analytics')
      .select('hour_of_day, demand_ratio')
      .gte('recorded_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      .order('demand_ratio', { ascending: false })
      .limit(10);

    return data || [];
  }

  async getZoneStats(): Promise<any[]> {
    const { data } = await this.supabase.client
      .from('demand_analytics')
      .select(`
        zone_id,
        delivery_zones(name),
        demand_ratio
      `)
      .gte('recorded_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()) // 24h
      .order('demand_ratio', { ascending: false });

    // Grouper par zone
    const zoneStats = {};
    data?.forEach(item => {
      const zoneId = item.zone_id;
      if (!zoneStats[zoneId]) {
        zoneStats[zoneId] = {
          zoneId,
          zoneName: item.delivery_zones?.name || 'Zone inconnue',
          totalDemand: 0,
          count: 0,
        };
      }
      zoneStats[zoneId].totalDemand += item.demand_ratio;
      zoneStats[zoneId].count += 1;
    });

    return Object.values(zoneStats).map((zone: any) => ({
      ...zone,
      averageDemand: zone.totalDemand / zone.count,
    }));
  }

  // Prédictions de demande
  async predictDemand(hour: number, dayOfWeek: number, zoneId?: string): Promise<number> {
    let query = this.supabase.client
      .from('demand_analytics')
      .select('demand_ratio')
      .eq('hour_of_day', hour)
      .eq('day_of_week', dayOfWeek)
      .gte('recorded_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()); // 30 jours

    if (zoneId) {
      query = query.eq('zone_id', zoneId);
    }

    const { data } = await query;

    if (!data || data.length === 0) {
      return 1.0; // Demande normale par défaut
    }

    // Calculer la moyenne
    const average = data.reduce((sum, item) => sum + item.demand_ratio, 0) / data.length;
    return Math.round(average * 100) / 100; // Arrondir à 2 décimales
  }
}