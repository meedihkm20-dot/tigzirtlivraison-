import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';
import { WeatherService } from './weather.service';
import { DemandAnalyticsService } from './demand-analytics.service';
import { 
  CalculatePriceDto, 
  PricingResult, 
  WeatherCondition, 
  VehicleType 
} from './dto/calculate-price.dto';

@Injectable()
export class PricingService {
  private readonly logger = new Logger(PricingService.name);

  constructor(
    private readonly supabase: SupabaseService,
    private readonly weatherService: WeatherService,
    private readonly demandService: DemandAnalyticsService,
  ) {}

  async calculatePrice(dto: CalculatePriceDto): Promise<PricingResult> {
    try {
      this.logger.log(`Calculating price for distance: ${dto.distance}km`);

      // 1. Récupérer la configuration de base
      const config = await this.getPricingConfig();
      
      // 2. Calculer le prix de base
      const basePrice = config.base_fee + (dto.distance * config.price_per_km);

      // 3. Déterminer la zone de livraison
      const deliveryZone = await this.getDeliveryZone(
        dto.deliveryLatitude, 
        dto.deliveryLongitude
      );

      // 4. Récupérer les conditions météo
      const weather = dto.weatherOverride || 
        await this.weatherService.getCurrentWeather(
          dto.deliveryLatitude, 
          dto.deliveryLongitude
        );

      // 5. Analyser la demande actuelle
      const demandData = await this.demandService.getCurrentDemand(deliveryZone?.id);

      // 6. Appliquer les règles de pricing
      const multipliers = await this.calculateMultipliers({
        zone: deliveryZone,
        weather,
        demandRatio: demandData.demandRatio,
        orderTime: new Date(),
        vehicleType: dto.vehicleType,
      });

      // 7. Calculer les bonus
      const bonuses = this.calculateBonuses({
        orderTime: new Date(),
        weather,
        hasRainGear: dto.hasRainGear,
        zone: deliveryZone?.name,
      });

      // 8. Prix final
      let finalPrice = basePrice * 
        multipliers.zone * 
        multipliers.time * 
        multipliers.weather * 
        multipliers.demand * 
        multipliers.vehicle;

      finalPrice += bonuses.nightSafety + bonuses.equipment;

      // 9. Appliquer les limites min/max
      finalPrice = Math.max(config.min_price, Math.min(config.max_price, finalPrice));

      // 10. Générer les avertissements
      const warnings = this.generateWarnings(weather, multipliers, demandData);

      // 11. Sauvegarder le calcul pour analytics
      const calculationId = await this.savePricingCalculation({
        orderId: dto.orderId,
        livreurId: dto.livreurId,
        basePrice,
        finalPrice,
        distance: dto.distance,
        multipliers,
        bonuses,
        weather,
        demandData,
      });

      const result: PricingResult = {
        finalPrice: Math.round(finalPrice),
        basePrice: Math.round(basePrice),
        multipliers,
        bonuses,
        breakdown: this.generateBreakdown(basePrice, multipliers, bonuses, finalPrice),
        warnings,
        calculationId,
      };

      this.logger.log(`Price calculated: ${result.finalPrice} DA`);
      return result;

    } catch (error) {
      this.logger.error('Error calculating price:', error);
      // Prix de fallback en cas d'erreur
      return this.getFallbackPrice(dto.distance);
    }
  }

  private async getPricingConfig(): Promise<any> {
    const { data } = await this.supabase.client
      .from('pricing_config')
      .select('name, value')
      .eq('is_active', true);

    const config = {};
    data?.forEach(item => {
      config[item.name] = parseFloat(item.value);
    });

    // Valeurs par défaut si config manquante
    return {
      base_fee: 150,
      price_per_km: 50,
      min_price: 100,
      max_price: 1500,
      ...config,
    };
  }

  private async getDeliveryZone(lat: number, lng: number): Promise<any> {
    const { data } = await this.supabase.client
      .rpc('get_delivery_zone', { lat, lng });

    if (data) {
      const { data: zone } = await this.supabase.client
        .from('delivery_zones')
        .select('*')
        .eq('id', data)
        .single();
      return zone;
    }

    // Zone par défaut
    return { name: 'centre_ville', multiplier: 1.0 };
  }

  private async calculateMultipliers(params: {
    zone: any;
    weather: WeatherCondition;
    demandRatio: number;
    orderTime: Date;
    vehicleType: VehicleType;
  }): Promise<any> {
    const { data: rules } = await this.supabase.client
      .from('pricing_rules')
      .select('*')
      .eq('is_active', true)
      .order('priority', { ascending: true });

    let multipliers = {
      zone: params.zone?.multiplier || 1.0,
      time: 1.0,
      weather: 1.0,
      demand: 1.0,
      vehicle: 1.0,
    };

    // Appliquer les règles
    rules?.forEach(rule => {
      const multiplier = this.evaluateRule(rule, params);
      if (multiplier > 1.0) {
        switch (rule.rule_type) {
          case 'time':
            multipliers.time = Math.max(multipliers.time, multiplier);
            break;
          case 'weather':
            multipliers.weather = Math.max(multipliers.weather, multiplier);
            break;
          case 'demand':
            multipliers.demand = Math.max(multipliers.demand, multiplier);
            break;
        }
      }
    });

    // Multiplicateur véhicule selon météo
    multipliers.vehicle = this.getVehicleMultiplier(params.vehicleType, params.weather);

    return multipliers;
  }

  private evaluateRule(rule: any, params: any): number {
    try {
      switch (rule.rule_type) {
        case 'time':
          return this.evaluateTimeRule(rule, params.orderTime);
        case 'weather':
          return this.evaluateWeatherRule(rule, params.weather);
        case 'demand':
          return this.evaluateDemandRule(rule, params.demandRatio);
        default:
          return 1.0;
      }
    } catch (error) {
      this.logger.warn(`Error evaluating rule ${rule.name}:`, error);
      return 1.0;
    }
  }

  private evaluateTimeRule(rule: any, orderTime: Date): number {
    const hour = orderTime.getHours();
    const conditionValue = rule.condition_value;

    if (Array.isArray(conditionValue) && conditionValue.length === 2) {
      const [start, end] = conditionValue;
      if (hour >= start && hour <= end) {
        return parseFloat(rule.multiplier);
      }
    }

    return 1.0;
  }

  private evaluateWeatherRule(rule: any, weather: WeatherCondition): number {
    const conditionValue = rule.condition_value;
    if (typeof conditionValue === 'string' && conditionValue.replace(/"/g, '') === weather) {
      return parseFloat(rule.multiplier);
    }
    return 1.0;
  }

  private evaluateDemandRule(rule: any, demandRatio: number): number {
    const threshold = parseFloat(rule.condition_value);
    if (rule.condition_operator === '>=' && demandRatio >= threshold) {
      return parseFloat(rule.multiplier);
    }
    return 1.0;
  }

  private getVehicleMultiplier(vehicleType: VehicleType, weather: WeatherCondition): number {
    switch (vehicleType) {
      case VehicleType.MOTO:
        if (weather === WeatherCondition.HEAVY_RAIN || weather === WeatherCondition.STORM) {
          return 1.3;
        }
        return 1.0;
      case VehicleType.VELO:
        switch (weather) {
          case WeatherCondition.LIGHT_RAIN: return 1.4;
          case WeatherCondition.HEAVY_RAIN: return 1.8;
          case WeatherCondition.WIND: return 1.3;
          default: return 1.0;
        }
      case VehicleType.VOITURE:
        return 0.95;
      default:
        return 1.0;
    }
  }

  private calculateBonuses(params: {
    orderTime: Date;
    weather: WeatherCondition;
    hasRainGear: boolean;
    zone: string;
  }): any {
    let bonuses = {
      nightSafety: 0,
      equipment: 0,
    };

    const hour = params.orderTime.getHours();
    
    // Bonus sécurité nocturne
    if (hour >= 20 || hour < 6) {
      if (params.zone === 'peripherie' || params.zone === 'villages') {
        bonuses.nightSafety = 50;
      } else if (params.zone === 'montagne') {
        bonuses.nightSafety = 80;
      }
    }

    // Bonus équipement pluie
    if ((params.weather === WeatherCondition.LIGHT_RAIN || 
         params.weather === WeatherCondition.HEAVY_RAIN) && 
        params.hasRainGear) {
      bonuses.equipment = 30;
    }

    return bonuses;
  }

  private generateWarnings(weather: WeatherCondition, multipliers: any, demandData: any): string[] {
    const warnings: string[] = [];

    if (multipliers.time > 1.0) {
      warnings.push('Livraison nocturne - Soyez prudent');
    }

    switch (weather) {
      case WeatherCondition.LIGHT_RAIN:
        warnings.push('Pluie légère - Conduite prudente');
        break;
      case WeatherCondition.HEAVY_RAIN:
        warnings.push('Pluie forte - Risques accrus');
        break;
      case WeatherCondition.STORM:
        warnings.push('Orage - Conditions dangereuses');
        break;
      case WeatherCondition.FOG:
        warnings.push('Brouillard - Visibilité réduite');
        break;
      case WeatherCondition.WIND:
        warnings.push('Vent fort - Attention aux deux-roues');
        break;
    }

    if (multipliers.demand > 1.5) {
      warnings.push('Forte demande - Opportunité de gains élevés');
    }

    return warnings;
  }

  private generateBreakdown(basePrice: number, multipliers: any, bonuses: any, finalPrice: number): string {
    let breakdown = `Prix de base: ${Math.round(basePrice)} DA\n`;

    Object.entries(multipliers).forEach(([key, value]) => {
      if (value !== 1.0) {
        breakdown += `${key}: x${(value as number).toFixed(2)}\n`;
      }
    });

    Object.entries(bonuses).forEach(([key, value]) => {
      if (value > 0) {
        breakdown += `Bonus ${key}: +${Math.round(value as number)} DA\n`;
      }
    });

    breakdown += `Total: ${Math.round(finalPrice)} DA`;
    return breakdown;
  }

  private async savePricingCalculation(data: any): Promise<string> {
    try {
      const { data: result } = await this.supabase.client
        .from('pricing_calculations')
        .insert({
          order_id: data.orderId,
          livreur_id: data.livreurId,
          base_price: data.basePrice,
          final_price: data.finalPrice,
          distance_km: data.distance,
          zone_multiplier: data.multipliers.zone,
          time_multiplier: data.multipliers.time,
          weather_multiplier: data.multipliers.weather,
          demand_multiplier: data.multipliers.demand,
          night_bonus: data.bonuses.nightSafety,
          weather_bonus: 0,
          equipment_bonus: data.bonuses.equipment,
          weather_condition: data.weather,
          available_drivers: data.demandData.availableDrivers,
          pending_orders: data.demandData.pendingOrders,
          calculation_breakdown: {
            multipliers: data.multipliers,
            bonuses: data.bonuses,
          },
        })
        .select('id')
        .single();

      return result?.id;
    } catch (error) {
      this.logger.warn('Failed to save pricing calculation:', error);
      return null;
    }
  }

  private getFallbackPrice(distance: number): PricingResult {
    const basePrice = 150 + (distance * 50);
    return {
      finalPrice: Math.round(basePrice),
      basePrice: Math.round(basePrice),
      multipliers: { zone: 1.0, time: 1.0, weather: 1.0, demand: 1.0, vehicle: 1.0 },
      bonuses: { nightSafety: 0, equipment: 0 },
      breakdown: `Prix de base: ${Math.round(basePrice)} DA\nTotal: ${Math.round(basePrice)} DA`,
      warnings: ['Calcul en mode dégradé'],
    };
  }

  // Méthodes pour l'administration
  async getPricingConfigAdmin(): Promise<any[]> {
    const { data } = await this.supabase.client
      .from('pricing_config')
      .select('*')
      .order('name');
    return data || [];
  }

  async updatePricingConfig(name: string, value: number, description?: string): Promise<void> {
    await this.supabase.client
      .from('pricing_config')
      .upsert({
        name,
        value,
        description,
        updated_at: new Date().toISOString(),
      });
  }

  async getDeliveryZones(): Promise<any[]> {
    const { data } = await this.supabase.client
      .from('delivery_zones')
      .select('*')
      .order('name');
    return data || [];
  }

  async getPricingRules(): Promise<any[]> {
    const { data } = await this.supabase.client
      .from('pricing_rules')
      .select('*')
      .order('priority', { ascending: true });
    return data || [];
  }

  async getPricingAnalytics(startDate: Date, endDate: Date): Promise<any> {
    const { data } = await this.supabase.client
      .from('pricing_calculations')
      .select('*')
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString())
      .order('created_at', { ascending: false });

    return {
      calculations: data || [],
      summary: this.calculateAnalyticsSummary(data || []),
    };
  }

  private calculateAnalyticsSummary(calculations: any[]): any {
    if (calculations.length === 0) {
      return { totalCalculations: 0, averagePrice: 0, totalRevenue: 0 };
    }

    const totalRevenue = calculations.reduce((sum, calc) => sum + calc.final_price, 0);
    const averagePrice = totalRevenue / calculations.length;

    return {
      totalCalculations: calculations.length,
      averagePrice: Math.round(averagePrice),
      totalRevenue: Math.round(totalRevenue),
      averageMultipliers: {
        zone: calculations.reduce((sum, calc) => sum + calc.zone_multiplier, 0) / calculations.length,
        time: calculations.reduce((sum, calc) => sum + calc.time_multiplier, 0) / calculations.length,
        weather: calculations.reduce((sum, calc) => sum + calc.weather_multiplier, 0) / calculations.length,
        demand: calculations.reduce((sum, calc) => sum + calc.demand_multiplier, 0) / calculations.length,
      },
    };
  }
}