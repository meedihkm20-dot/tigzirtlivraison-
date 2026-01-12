import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, OneToMany } from 'typeorm';
import { Restaurant } from './restaurant.entity';
import { MenuCategory } from './menu-category.entity';
import { MenuItemOption } from './menu-item-option.entity';
import { OrderItem } from '../orders/order-item.entity';

@Entity('menu_items')
export class MenuItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  restaurantId: string;

  @Column({ nullable: true })
  categoryId?: string;

  @Column({ length: 150 })
  name: string;

  @Column({ nullable: true })
  description?: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  price: number;

  @Column({ nullable: true, length: 500 })
  imageUrl?: string;

  @Column({ default: true })
  isAvailable: boolean;

  @Column({ default: false })
  isFeatured: boolean;

  @Column({ nullable: true })
  preparationTime?: number;

  @Column({ default: 0 })
  totalOrders: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => Restaurant, restaurant => restaurant.menuItems)
  restaurant: Restaurant;

  @ManyToOne(() => MenuCategory, category => category.items)
  category?: MenuCategory;

  @OneToMany(() => MenuItemOption, option => option.menuItem)
  options: MenuItemOption[];

  @OneToMany(() => OrderItem, orderItem => orderItem.menuItem)
  orderItems: OrderItem[];
}
