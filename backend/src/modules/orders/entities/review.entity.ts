import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('reviews')
export class Review {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  orderId: string;

  @Column()
  userId: string;

  @Column()
  restaurantId: string;

  @Column({ nullable: true })
  livreurId?: string;

  @Column({ nullable: true })
  restaurantRating?: number;

  @Column({ nullable: true })
  livreurRating?: number;

  @Column({ nullable: true })
  restaurantComment?: string;

  @Column({ nullable: true })
  livreurComment?: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
