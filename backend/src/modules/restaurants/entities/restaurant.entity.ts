import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany, ManyToMany, JoinTable } from 'typeorm';
import { Exclude } from 'class-transformer';
import { MenuCategory } from './menu-category.entity';
import { MenuItem } from './menu-item.entity';
import { RestaurantCategory } from './restaurant-category.entity';

@Entity('restaurants')
export class Restaurant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 150 })
  name: string;

  @Column({ unique: true, length: 150 })
  slug: string;

  @Column({ nullable: true })
  description?: string;

  @Column({ length: 15 })
  phone: string;

  @Column({ nullable: true, length: 255 })
  email?: string;

  @Column()
  @Exclude()
  passwordHash: string;

  @Column({ length: 255 })
  address: string;

  @Column({ length: 100 })
  city: string;

  @Column({ length: 100 })
  wilaya: string;

  @Column({ type: 'decimal', precision: 10, scale: 8 })
  latitude: number;

  @Column({ type: 'decimal', precision: 11, scale: 8 })
  longitude: number;

  @Column({ type: 'decimal', precision: 4, scale: 2, default: 5.00 })
  deliveryRadiusKm: number;

  @Column({ nullable: true, length: 500 })
  logoUrl?: string;

  @Column({ nullable: true, length: 500 })
  coverImageUrl?: string;

  @Column({ type: 'decimal', precision: 4, scale: 2, default: 10.00 })
  commissionRate: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 500 })
  minOrderAmount: number;

  @Column({ default: 30 })
  avgPreparationTime: number;

  @Column({ type: 'jsonb', default: '{"monday": {"open": "08:00", "close": "23:00"}, "tuesday": {"open": "08:00", "close": "23:00"}, "wednesday": {"open": "08:00", "close": "23:00"}, "thursday": {"open": "08:00", "close": "23:00"}, "friday": {"open": "08:00", "close": "23:00"}, "saturday": {"open": "08:00", "close": "23:00"}, "sunday": {"open": "08:00", "close": "23:00"}}' })
  openingHours: Record<string, { open: string; close: string }>;

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: false })
  isVerified: boolean;

  @Column({ default: true })
  isOpen: boolean;

  @Column({ type: 'decimal', precision: 2, scale: 1, default: 0 })
  rating: number;

  @Column({ default: 0 })
  totalOrders: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @OneToMany(() => MenuCategory, category => category.restaurant)
  menuCategories: MenuCategory[];

  @OneToMany(() => MenuItem, item => item.restaurant)
  menuItems: MenuItem[];

  @ManyToMany(() => RestaurantCategory)
  @JoinTable({
    name: 'restaurant_category_associations',
    joinColumn: { name: 'restaurant_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'category_id', referencedColumnName: 'id' },
  })
  categories: RestaurantCategory[];

  // Orders relation - lazy loaded to avoid circular dependency
  orders?: any[];
}
