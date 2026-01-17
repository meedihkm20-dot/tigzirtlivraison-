import { IsNumber, IsString, IsOptional, IsEnum, IsBoolean } from 'class-validator';

export enum WeatherCondition {
  CLEAR = 'clear',
  CLOUDY = 'cloudy',
  LIGHT_RAIN = 'light_rain',
  HEAVY_RAIN = 'heavy_rain',
  STORM = 'storm',
  FOG = 'fog',
  WIND = 'wind',
  EXTREME = 'extreme',
}

export enum VehicleType {
  MOTO = 'moto',
  VELO = 'velo',
  VOITURE = 'voiture',
}

export class CalculatePriceDto {
  @IsNumber()
  distance: number;

  @IsNumber()
  restaurantLatitude: number;

  @IsNumber()
  restaurantLongitude: number;

  @IsNumber()
  deliveryLatitude: number;

  @IsNumber()
  deliveryLongitude: number;

  @IsOptional()
  @IsString()
  orderId?: string;

  @IsOptional()
  @IsString()
  livreurId?: string;

  @IsOptional()
  @IsEnum(VehicleType)
  vehicleType?: VehicleType = VehicleType.MOTO;

  @IsOptional()
  @IsBoolean()
  hasRainGear?: boolean = false;

  @IsOptional()
  @IsEnum(WeatherCondition)
  weatherOverride?: WeatherCondition;
}

export class PricingResult {
  finalPrice: number;
  basePrice: number;
  multipliers: {
    zone: number;
    time: number;
    weather: number;
    demand: number;
    vehicle: number;
  };
  bonuses: {
    nightSafety: number;
    equipment: number;
  };
  breakdown: string;
  warnings: string[];
  calculationId?: string;
}

export class UpdatePricingConfigDto {
  @IsString()
  name: string;

  @IsNumber()
  value: number;

  @IsOptional()
  @IsString()
  description?: string;
}

export class CreateDeliveryZoneDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNumber()
  multiplier: number;

  @IsOptional()
  polygon?: any; // GeoJSON polygon
}

export class CreatePricingRuleDto {
  @IsEnum(['base', 'distance', 'time', 'weather', 'demand', 'zone'])
  ruleType: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  conditionKey?: string;

  @IsOptional()
  @IsString()
  conditionOperator?: string;

  @IsOptional()
  conditionValue?: any;

  @IsOptional()
  @IsNumber()
  multiplier?: number;

  @IsOptional()
  @IsNumber()
  bonusAmount?: number;

  @IsOptional()
  @IsNumber()
  priority?: number;
}