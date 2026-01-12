import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('device_tokens')
export class DeviceToken {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  userId?: string;

  @Column({ nullable: true })
  restaurantId?: string;

  @Column({ nullable: true })
  livreurId?: string;

  @Column({ length: 500 })
  token: string;

  @Column({ length: 20, nullable: true })
  deviceType?: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
