import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';
import { WeatherCondition } from './dto/calculate-price.dto';

@Injectable()
export class WeatherService {
  private readonly logger = new Logger(WeatherService.name);

  constructor(private readonly supabase: SupabaseService) {}

  async getCurrentWeather(lat: number, lng: number): Promise<WeatherCondition> {
    try {
      // 1. Vérifier si on a des données récentes en cache
      const cachedWeather = await this.getCachedWeather(lat, lng);
      if (cachedWeather) {
        return cachedWeather.condition;
      }

      // 2. Récupérer depuis l'API météo (OpenWeatherMap ou autre)
      const weatherData = await this.fetchWeatherFromAPI(lat, lng);
      
      // 3. Sauvegarder en cache
      await this.cacheWeatherData(lat, lng, weatherData);

      return weatherData.condition;

    } catch (error) {
      this.logger.warn('Failed to get weather data, using default:', error);
      return WeatherCondition.CLEAR; // Valeur par défaut
    }
  }

  private async getCachedWeather(lat: number, lng: number): Promise<any> {
    const { data } = await this.supabase.client
      .from('weather_data')
      .select('*')
      .gte('expires_at', new Date().toISOString())
      .order('recorded_at', { ascending: false })
      .limit(1);

    // Vérifier si les coordonnées sont proches (rayon de 5km)
    if (data && data.length > 0) {
      const weather = data[0];
      const distance = this.calculateDistance(
        lat, lng, 
        weather.latitude, weather.longitude
      );
      
      if (distance <= 5) { // 5km de rayon
        return weather;
      }
    }

    return null;
  }

  private async fetchWeatherFromAPI(lat: number, lng: number): Promise<any> {
    // Simulation d'API météo - À remplacer par vraie API
    // Exemple avec OpenWeatherMap:
    // const apiKey = process.env.OPENWEATHER_API_KEY;
    // const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lng}&appid=${apiKey}`;
    
    try {
      // Pour la démo, on simule selon l'heure et la saison
      const condition = this.simulateWeatherCondition();
      
      return {
        condition,
        temperature: 20 + Math.random() * 15, // 20-35°C
        humidity: 40 + Math.random() * 40,    // 40-80%
        windSpeed: Math.random() * 20,        // 0-20 km/h
        visibility: 8 + Math.random() * 2,    // 8-10 km
      };

    } catch (error) {
      this.logger.error('Weather API error:', error);
      throw error;
    }
  }

  private simulateWeatherCondition(): WeatherCondition {
    const hour = new Date().getHours();
    const random = Math.random();

    // Simulation basée sur l'heure et probabilités
    if (hour >= 6 && hour <= 18) { // Jour
      if (random < 0.7) return WeatherCondition.CLEAR;
      if (random < 0.85) return WeatherCondition.CLOUDY;
      if (random < 0.95) return WeatherCondition.LIGHT_RAIN;
      return WeatherCondition.HEAVY_RAIN;
    } else { // Nuit
      if (random < 0.6) return WeatherCondition.CLEAR;
      if (random < 0.8) return WeatherCondition.CLOUDY;
      if (random < 0.9) return WeatherCondition.FOG;
      return WeatherCondition.LIGHT_RAIN;
    }
  }

  private async cacheWeatherData(lat: number, lng: number, weatherData: any): Promise<void> {
    try {
      await this.supabase.client
        .from('weather_data')
        .insert({
          location_name: `${lat.toFixed(4)},${lng.toFixed(4)}`,
          latitude: lat,
          longitude: lng,
          condition: weatherData.condition,
          temperature: weatherData.temperature,
          humidity: weatherData.humidity,
          wind_speed: weatherData.windSpeed,
          visibility: weatherData.visibility,
          raw_data: weatherData,
          expires_at: new Date(Date.now() + 60 * 60 * 1000).toISOString(), // 1 heure
        });
    } catch (error) {
      this.logger.warn('Failed to cache weather data:', error);
    }
  }

  private calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371; // Rayon de la Terre en km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLng = this.deg2rad(lng2 - lng1);
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) * 
      Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI/180);
  }

  // Méthodes pour l'administration
  async getWeatherHistory(startDate: Date, endDate: Date): Promise<any[]> {
    const { data } = await this.supabase.client
      .from('weather_data')
      .select('*')
      .gte('recorded_at', startDate.toISOString())
      .lte('recorded_at', endDate.toISOString())
      .order('recorded_at', { ascending: false });

    return data || [];
  }

  async getWeatherStats(): Promise<any> {
    const { data } = await this.supabase.client
      .from('weather_data')
      .select('condition')
      .gte('recorded_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()); // 24h

    const stats = {};
    data?.forEach(item => {
      stats[item.condition] = (stats[item.condition] || 0) + 1;
    });

    return {
      last24Hours: stats,
      totalRecords: data?.length || 0,
    };
  }
}