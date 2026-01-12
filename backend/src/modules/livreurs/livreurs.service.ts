import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Livreur } from './entities/livreur.entity';
import { LivreurZone } from './entities/livreur-zone.entity';

@Injectable()
export class LivreursService {
  constructor(
    @InjectRepository(Livreur)
    private livreursRepository: Repository<Livreur>,
    @InjectRepository(LivreurZone)
    private zonesRepository: Repository<LivreurZone>,
  ) {}

  async findAll(city?: string, isOnline?: boolean): Promise<Livreur[]> {
    const query = this.livreursRepository.createQueryBuilder('livreur')
      .where('livreur.isActive = :isActive', { isActive: true })
      .andWhere('livreur.isVerified = :isVerified', { isVerified: true });
    
    if (city) {
      query.andWhere('livreur.city = :city', { city });
    }
    if (isOnline !== undefined) {
      query.andWhere('livreur.isOnline = :isOnline', { isOnline });
    }
    
    return query.getMany();
  }

  async findOne(id: string): Promise<Livreur> {
    const livreur = await this.livreursRepository.findOne({
      where: { id },
      relations: ['zones'],
    });
    if (!livreur) {
      throw new NotFoundException(`Livreur #${id} not found`);
    }
    return livreur;
  }

  async findByPhone(phone: string): Promise<Livreur | null> {
    return this.livreursRepository.findOne({ where: { phone } });
  }

  async create(data: Partial<Livreur>): Promise<Livreur> {
    const livreur = this.livreursRepository.create(data);
    return this.livreursRepository.save(livreur);
  }

  async update(id: string, data: Partial<Livreur>): Promise<Livreur> {
    await this.livreursRepository.update(id, data);
    return this.findOne(id);
  }

  async updateLocation(id: string, latitude: number, longitude: number): Promise<Livreur> {
    await this.livreursRepository.update(id, {
      currentLatitude: latitude,
      currentLongitude: longitude,
      lastLocationUpdate: new Date(),
    });
    return this.findOne(id);
  }

  async updateOnlineStatus(id: string, isOnline: boolean): Promise<Livreur> {
    await this.livreursRepository.update(id, { isOnline });
    return this.findOne(id);
  }

  async updateBusyStatus(id: string, isBusy: boolean): Promise<Livreur> {
    await this.livreursRepository.update(id, { isBusy });
    return this.findOne(id);
  }

  // Find available livreurs near a location
  async findAvailableNearby(latitude: number, longitude: number, radiusKm: number = 5): Promise<Livreur[]> {
    return this.livreursRepository
      .createQueryBuilder('livreur')
      .where('livreur.isActive = :isActive', { isActive: true })
      .andWhere('livreur.isVerified = :isVerified', { isVerified: true })
      .andWhere('livreur.isOnline = :isOnline', { isOnline: true })
      .andWhere('livreur.isBusy = :isBusy', { isBusy: false })
      .andWhere(`
        (6371 * acos(
          cos(radians(:latitude)) * cos(radians(livreur.currentLatitude)) *
          cos(radians(livreur.currentLongitude) - radians(:longitude)) +
          sin(radians(:latitude)) * sin(radians(livreur.currentLatitude))
        )) <= :radius
      `, { latitude, longitude, radius: radiusKm })
      .orderBy(`
        (6371 * acos(
          cos(radians(:latitude)) * cos(radians(livreur.currentLatitude)) *
          cos(radians(livreur.currentLongitude) - radians(:longitude)) +
          sin(radians(:latitude)) * sin(radians(livreur.currentLatitude))
        ))
      `, 'ASC')
      .getMany();
  }

  // Zones
  async addZone(livreurId: string, city: string, wilaya: string): Promise<LivreurZone> {
    const zone = this.zonesRepository.create({ livreurId, city, wilaya });
    return this.zonesRepository.save(zone);
  }

  async getZones(livreurId: string): Promise<LivreurZone[]> {
    return this.zonesRepository.find({ where: { livreurId, isActive: true } });
  }

  async removeZone(zoneId: string): Promise<void> {
    await this.zonesRepository.delete(zoneId);
  }

  // Stats
  async incrementDeliveries(id: string, earnings: number): Promise<void> {
    await this.livreursRepository
      .createQueryBuilder()
      .update(Livreur)
      .set({
        totalDeliveries: () => 'total_deliveries + 1',
        totalEarnings: () => `total_earnings + ${earnings}`,
      })
      .where('id = :id', { id })
      .execute();
  }

  async updateRating(id: string, newRating: number): Promise<void> {
    const livreur = await this.findOne(id);
    const totalRatings = livreur.totalDeliveries;
    const currentAvg = livreur.rating;
    const newAvg = ((currentAvg * totalRatings) + newRating) / (totalRatings + 1);
    
    await this.livreursRepository.update(id, { rating: Math.round(newAvg * 10) / 10 });
  }
}
