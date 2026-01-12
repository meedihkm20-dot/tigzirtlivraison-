import { Controller, Get, Post, Put, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { AdminService } from './admin.service';
import { DashboardService } from './dashboard.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../../common/guards/admin.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly dashboardService: DashboardService,
  ) {}

  @Get('dashboard/overview')
  getOverviewStats() {
    return this.dashboardService.getOverviewStats();
  }

  @Get('dashboard/revenue')
  getRevenueStats(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.dashboardService.getRevenueStats(
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Get('dashboard/top-restaurants')
  getTopRestaurants(@Query('limit') limit?: string) {
    return this.dashboardService.getTopRestaurants(limit ? parseInt(limit) : 10);
  }

  @Get('dashboard/top-livreurs')
  getTopLivreurs(@Query('limit') limit?: string) {
    return this.dashboardService.getTopLivreurs(limit ? parseInt(limit) : 10);
  }

  @Get('admins')
  @UseGuards(RolesGuard)
  @Roles('super_admin')
  findAllAdmins() {
    return this.adminService.findAll();
  }

  @Post('admins')
  @UseGuards(RolesGuard)
  @Roles('super_admin')
  createAdmin(
    @Request() req,
    @Body() data: {
      email: string;
      password: string;
      fullName: string;
      role?: string;
      permissions?: string[];
    },
  ) {
    // Log admin creation
    this.adminService.logAction(
      req.user.id,
      'create_admin',
      'admin',
      null,
      { email: data.email },
    );
    return this.adminService.createAdmin(data);
  }

  @Put('admins/:id')
  @UseGuards(RolesGuard)
  @Roles('super_admin')
  updateAdmin(
    @Request() req,
    @Param('id') id: string,
    @Body() data: { fullName?: string; role?: string; permissions?: string[] },
  ) {
    this.adminService.logAction(
      req.user.id,
      'update_admin',
      'admin',
      id,
      data,
    );
    return this.adminService.updateAdmin(id, data);
  }

  @Put('admins/:id/deactivate')
  @UseGuards(RolesGuard)
  @Roles('super_admin')
  deactivateAdmin(@Request() req, @Param('id') id: string) {
    this.adminService.logAction(
      req.user.id,
      'deactivate_admin',
      'admin',
      id,
    );
    return this.adminService.deactivateAdmin(id);
  }

  @Get('logs')
  getAdminLogs(
    @Query('adminId') adminId?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getAdminLogs(adminId, limit ? parseInt(limit) : 100);
  }
}
