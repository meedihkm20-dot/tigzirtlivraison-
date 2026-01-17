import { 
  Controller, 
  Post, 
  Get, 
  Put, 
  Body, 
  Query, 
  Param, 
  UseGuards,
  Logger 
} from '@nestjs/common';
import { PricingService } from './pricing.service';
import { WeatherService } from './weather.service';
import { DemandAnalyticsService } from './demand-analytics.service';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { 
  CalculatePriceDto, 
  UpdatePricingConfigDto,
  CreateDeliveryZoneDto,
  CreatePricingRuleDto 
} from './dto/calculate-price.dto';

@Controller('pricing')
@UseGuards(SupabaseAuthGuard)
export class PricingController {
  private readonly logger = new Logger(PricingController.name);

  constructor(
    private readonly pricingService: PricingService,
    private readonly weatherService: WeatherService,
    private readonly demandService: DemandAnalyticsService,
  ) {}

  // ============================================
  // ENDPOINTS PUBLICS (Tous utilisateurs)
  // ============================================

  @Post('calculate')
  async calculatePrice(@Body() dto: CalculatePriceDto) {
    this.logger.log(`Calculating price for ${dto.distance}km delivery`);
    return await this.pricingService.calculatePrice(dto);
  }

  @Get('config')
  async getPricingConfig() {
    return await this.pricingService.getPricingConfig();
  }

  @Get('zones')
  async getDeliveryZones() {
    return await this.pricingService.getDeliveryZones();
  }

  @Get('rules')
  async getPricingRules() {
    return await this.pricingService.getPricingRules();
  }

  @Get('demand/current')
  async getCurrentDemand(@Query('zoneId') zoneId?: string) {
    return await this.demandService.getCurrentDemand(zoneId);
  }

  @Get('weather/current')
  async getCurrentWeather(
    @Query('lat') lat: number,
    @Query('lng') lng: number,
  ) {
    return await this.weatherService.getCurrentWeather(lat, lng);
  }

  // ============================================
  // ENDPOINTS LIVREUR (Analytics personnelles)
  // ============================================

  @Get('analytics/livreur')
  async getLivreurPricingAnalytics(
    @CurrentUser() user: any,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    // Vérifier que l'utilisateur est un livreur
    if (user.role !== 'livreur') {
      throw new Error('Access denied: Livreur role required');
    }

    const start = new Date(startDate);
    const end = new Date(endDate);
    
    return await this.pricingService.getPricingAnalytics(start, end);
  }

  @Get('predictions/earnings')
  async getEarningsPredictions(
    @CurrentUser() user: any,
    @Query('hour') hour: number,
    @Query('dayOfWeek') dayOfWeek: number,
    @Query('zoneId') zoneId?: string,
  ) {
    if (user.role !== 'livreur') {
      throw new Error('Access denied: Livreur role required');
    }

    const predictedDemand = await this.demandService.predictDemand(
      hour, 
      dayOfWeek, 
      zoneId
    );

    // Estimation des gains basée sur la demande prédite
    const baseEarnings = 300; // Gain moyen par heure
    const estimatedEarnings = baseEarnings * Math.min(predictedDemand, 2.0);

    return {
      hour,
      dayOfWeek,
      zoneId,
      predictedDemand,
      estimatedEarnings: Math.round(estimatedEarnings),
      confidence: predictedDemand > 0 ? 'high' : 'low',
    };
  }

  // ============================================
  // ENDPOINTS ADMIN (Configuration)
  // ============================================

  @Put('config/:name')
  async updatePricingConfig(
    @CurrentUser() user: any,
    @Param('name') name: string,
    @Body() dto: UpdatePricingConfigDto,
  ) {
    if (user.role !== 'admin') {
      throw new Error('Access denied: Admin role required');
    }

    await this.pricingService.updatePricingConfig(
      name, 
      dto.value, 
      dto.description
    );

    this.logger.log(`Admin ${user.id} updated pricing config: ${name} = ${dto.value}`);
    return { success: true, message: 'Configuration updated' };
  }

  @Post('zones')
  async createDeliveryZone(
    @CurrentUser() user: any,
    @Body() dto: CreateDeliveryZoneDto,
  ) {
    if (user.role !== 'admin') {
      throw new Error('Access denied: Admin role required');
    }

    // TODO: Implémenter la création de zone
    this.logger.log(`Admin ${user.id} created delivery zone: ${dto.name}`);
    return { success: true, message: 'Zone created' };
  }

  @Post('rules')
  async createPricingRule(
    @CurrentUser() user: any,
    @Body() dto: CreatePricingRuleDto,
  ) {
    if (user.role !== 'admin') {
      throw new Error('Access denied: Admin role required');
    }

    // TODO: Implémenter la création de règle
    this.logger.log(`Admin ${user.id} created pricing rule: ${dto.name}`);
    return { success: true, message: 'Rule created' };
  }

  @Get('analytics/admin')
  async getAdminAnalytics(
    @CurrentUser() user: any,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    if (user.role !== 'admin') {
      throw new Error('Access denied: Admin role required');
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    const [
      pricingAnalytics,
      demandTrends,
      weatherStats,
      peakHours,
      zoneStats,
    ] = await Promise.all([
      this.pricingService.getPricingAnalytics(start, end),
      this.demandService.getDemandTrends(),
      this.weatherService.getWeatherStats(),
      this.demandService.getPeakHours(),
      this.demandService.getZoneStats(),
    ]);

    return {
      pricing: pricingAnalytics,
      demand: {
        trends: demandTrends,
        peakHours,
        zoneStats,
      },
      weather: weatherStats,
      period: { startDate, endDate },
    };
  }

  @Get('demand/trends')
  async getDemandTrends(@CurrentUser() user: any) {
    if (user.role !== 'admin') {
      throw new Error('Access denied: Admin role required');
    }

    return await this.demandService.getDemandTrends();
  }

  @Get('weather/history')
  async getWeatherHistory(
    @CurrentUser() user: any,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    if (user.role !== 'admin') {
      throw new Error('Access denied: Admin role required');
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    return await this.weatherService.getWeatherHistory(start, end);
  }

  // ============================================
  // ENDPOINTS UTILITAIRES
  // ============================================

  @Get('health')
  async healthCheck() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      services: {
        pricing: 'operational',
        weather: 'operational',
        demand: 'operational',
      },
    };
  }

  @Post('simulate')
  async simulatePricing(
    @Body() scenarios: CalculatePriceDto[],
  ) {
    // Endpoint pour tester différents scénarios de pricing
    const results = await Promise.all(
      scenarios.map(scenario => this.pricingService.calculatePrice(scenario))
    );

    return {
      scenarios: scenarios.length,
      results,
      summary: {
        minPrice: Math.min(...results.map(r => r.finalPrice)),
        maxPrice: Math.max(...results.map(r => r.finalPrice)),
        avgPrice: Math.round(
          results.reduce((sum, r) => sum + r.finalPrice, 0) / results.length
        ),
      },
    };
  }
}