import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { Exclude } from 'class-transformer';
import { UserAddress } from './user-address.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, length: 15 })
  phone: string;

  @Column({ length: 100 })
  fullName: string;

  @Column({ unique: true, nullable: true, length: 255 })
  email?: string;

  @Column()
  @Exclude()
  passwordHash: string;

  @Column({ nullable: true })
  defaultAddressId?: string;

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: false })
  isVerified: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @OneToMany(() => UserAddress, address => address.user)
  addresses: UserAddress[];
}
