import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  userId?: string;

  @Column({ nullable: true })
  restaurantId?: string;

  @Column({ nullable: true })
  livreurId?: string;

  @Column({ length: 200 })
  title: string;

  @Column('text')
  message: string;

  @Column({ length: 50 })
  type: string;

  @Column({ type: 'jsonb', nullable: true })
  data?: Record<string, any>;

  @Column({ default: false })
  isRead: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
