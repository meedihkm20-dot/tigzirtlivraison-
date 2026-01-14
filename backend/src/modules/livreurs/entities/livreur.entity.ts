import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { Exclude } from 'class-transformer';
import { LivreurZone } from './livreur-zone.entity';

@Entity('livreurs')
export class Livreur {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100 })
  fullName: string;

  @Column({ unique: true, length: 15 })
  phone: string;

  @Column({ nullable: true, unique: true, length: 255 })
  email?: string;

  @Column()
  @Exclude()
  passwordHash: string;

  @Column({ nullable: true, length: 50 })
  idCardNumber?: string;

  @Column({ nullable: true, length: 500 })
  idCardImageUrl?: string;

  @Column({ nullable: true, length: 500 })
  driverLicenseUrl?: string;

  @Column({ length: 20 })
  vehicleType: string;

  @Column({ nullable: true, length: 20 })
  vehiclePlate?: string;

  @Column({ length: 100 })
  city: string;

  @Column({ length: 100 })
  wilaya: string;

  @Column({ type: 'decimal', precision: 10, scale: 8, nullable: true })
  currentLatitude?: number;

  @Column({ type: 'decimal', precision: 11, scale: 8, nullable: true })
  currentLongitude?: number;

  @Column({ nullable: true })
  lastLocationUpdate?: Date;

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: false })
  isVerified: boolean;

  @Column({ default: false })
  isOnline: boolean;

  @Column({ default: false })
  isBusy: boolean;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  walletBalance: number;

  @Column({ type: 'decimal', precision: 2, scale: 1, default: 5.0 })
  rating: number;

  @Column({ default: 0 })
  totalDeliveries: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  totalEarnings: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @OneToMany(() => LivreurZone, zone => zone.livreur)
  zones: LivreurZone[];

  // Orders relation - lazy loaded to avoid circular dependency
  orders?: any[];
}
