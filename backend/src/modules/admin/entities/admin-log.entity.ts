import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('admin_logs')
export class AdminLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  adminId: string;

  @Column({ length: 100 })
  action: string;

  @Column({ length: 50, nullable: true })
  entityType?: string;

  @Column({ nullable: true })
  entityId?: string;

  @Column({ type: 'jsonb', nullable: true })
  details?: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;
}
