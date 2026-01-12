import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { Exclude } from 'class-transformer';

@Entity('admin_users')
export class AdminUser {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, length: 255 })
  email: string;

  @Column()
  @Exclude()
  passwordHash: string;

  @Column({ length: 100 })
  fullName: string;

  @Column({ length: 50, default: 'admin' })
  role: string;

  @Column({ type: 'jsonb', default: '[]' })
  permissions: string[];

  @Column({ default: true })
  isActive: boolean;

  @Column({ nullable: true })
  lastLogin?: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
