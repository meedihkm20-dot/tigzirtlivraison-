import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('/api/health (GET)', () => {
    it('should return 200 and health status', () => {
      return request(app.getHttpServer())
        .get('/api/health')
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('status', 'ok');
          expect(res.body).toHaveProperty('timestamp');
          expect(res.body).toHaveProperty('service');
        });
    });
  });

  describe('/api/delivery/calculate-price (GET)', () => {
    it('should calculate delivery price', () => {
      return request(app.getHttpServer())
        .get('/api/delivery/calculate-price?distance=5&zone=tigzirt')
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('price');
          expect(res.body).toHaveProperty('currency', 'DA');
          expect(res.body.price).toBeGreaterThan(0);
        });
    });

    it('should return 400 for missing parameters', () => {
      return request(app.getHttpServer())
        .get('/api/delivery/calculate-price')
        .expect(400);
    });
  });

  describe('/api/delivery/estimate-time (GET)', () => {
    it('should estimate delivery time', () => {
      return request(app.getHttpServer())
        .get('/api/delivery/estimate-time?distance=5&preparation_time=20')
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('estimated_minutes');
          expect(res.body.estimated_minutes).toBeGreaterThan(0);
        });
    });
  });
});
