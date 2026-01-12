import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { Livreur } from './livreur.entity';

@Entity('livreur_zones')
export class LivreurZone {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  livreurId: string;

  @Column({ length: 100 })
  city: string;

  @Column({ length: 100 })
  wilaya: string;

  @Column({ default: true })
  isActive: boolean;

  // Relations
  @ManyToOne(() => Livreur, livreur => livreur.zones)
  livreur: Livreur;
}
