import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Livreur } from './entities/livreur.entity';
import { LivreurZone } from './entities/livreur-zone.entity';
import { LivreursController } from './livreurs.controller';
import { LivreursService } from './livreurs.service';

@Module({
  imports: [TypeOrmModule.forFeature([Livreur, LivreurZone])],
  controllers: [LivreursController],
  providers: [LivreursService],
  exports: [LivreursService],
})
export class LivreursModule {}
