import { Test, TestingModule } from '@nestjs/testing';
import { DeliveryService } from './delivery.service';
import { SupabaseService } from '../../supabase/supabase.service';

describe('DeliveryService', () => {
  let service: DeliveryService;
  let supabaseService: SupabaseService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeliveryService,
        {
          provide: SupabaseService,
          useValue: {
            getClient: jest.fn(),
            getOrderById: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<DeliveryService>(DeliveryService);
    supabaseService = module.get<SupabaseService>(SupabaseService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('calculateDeliveryPrice', () => {
    it('should calculate base price for Tigzirt zone', () => {
      const price = service.calculateDeliveryPrice(5, 'tigzirt');
      expect(price).toBe(250); // 100 + (5 * 30) = 250
    });

    it('should apply zone multiplier for Azazga', () => {
      const price = service.calculateDeliveryPrice(5, 'azazga');
      expect(price).toBe(300); // (100 + 150) * 1.2 = 300
    });

    it('should apply zone multiplier for Tizi-Ouzou', () => {
      const price = service.calculateDeliveryPrice(5, 'tizi-ouzou');
      expect(price).toBe(380); // (100 + 150) * 1.5 = 375 → arrondi à 380
    });

    it('should round to nearest 10 DA', () => {
      const price = service.calculateDeliveryPrice(3, 'tigzirt');
      expect(price).toBe(190); // 100 + 90 = 190
    });

    it('should handle minimum distance', () => {
      const price = service.calculateDeliveryPrice(0, 'tigzirt');
      expect(price).toBe(100); // Base fee only
    });
  });

  describe('calculateEstimatedTime', () => {
    it('should calculate total time with preparation and delivery', () => {
      const time = service.calculateEstimatedTime(5, 20);
      // 20 (prep) + (5/25)*60 (delivery) + 5 (buffer) = 20 + 12 + 5 = 37
      expect(time).toBe(37);
    });

    it('should handle zero distance', () => {
      const time = service.calculateEstimatedTime(0, 15);
      expect(time).toBe(20); // 15 + 0 + 5
    });

    it('should round up to nearest minute', () => {
      const time = service.calculateEstimatedTime(1, 10);
      // 10 + (1/25)*60 + 5 = 10 + 2.4 + 5 = 17.4 → 18
      expect(time).toBeGreaterThanOrEqual(17);
    });
  });
});
