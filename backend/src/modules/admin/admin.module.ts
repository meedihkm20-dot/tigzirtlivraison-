import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminUser } from './entities/admin-user.entity';
import { AdminLog } from './entities/admin-log.entity';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { DashboardService } from './dashboard.service';

@Module({
  imports: [TypeOrmModule.forFeature([AdminUser, AdminLog])],
  controllers: [AdminController],
  providers: [AdminService, DashboardService],
  exports: [AdminService],
})
export class AdminModule {}
