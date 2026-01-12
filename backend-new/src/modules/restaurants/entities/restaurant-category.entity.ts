import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('restaurant_categories')
export class RestaurantCategory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100 })
  name: string;

  @Column({ nullable: true, length: 50 })
  icon?: string;

  @Column({ default: 0 })
  displayOrder: number;
}
