import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany, ManyToOne } from 'typeorm';
import { MenuItem } from './menu-item.entity';
import { Restaurant } from './restaurant.entity';

@Entity('menu_categories')
export class MenuCategory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  restaurantId: string;

  @Column({ length: 100 })
  name: string;

  @Column({ nullable: true })
  description?: string;

  @Column({ default: 0 })
  displayOrder: number;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => Restaurant, restaurant => restaurant.menuCategories)
  restaurant: Restaurant;

  @OneToMany(() => MenuItem, item => item.category)
  items: MenuItem[];
}
