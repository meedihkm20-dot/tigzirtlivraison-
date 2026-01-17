import { Module } from '@nestjs/common';
import { PricingController } from './pricing.controller';
import { PricingService } from './pricing.service';
import { WeatherService } from './weather.service';
import { DemandAnalyticsService } from './demand-analytics.service';
import { SupabaseModule } from '../../supabase/supabase.module';

@Module({
  imports: [SupabaseModule],
  controllers: [PricingController],
  providers: [PricingService, WeatherService, DemandAnalyticsService],
  exports: [PricingService],
})
export class PricingModule {}