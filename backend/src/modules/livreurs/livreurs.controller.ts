import { Controller, Get, Put, Post, Delete, Body, Param, Query, UseGuards, ForbiddenException } from '@nestjs/common';
import { LivreursService } from './livreurs.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AdminGuard } from '../../common/guards/admin.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('livreurs')
export class LivreursController {
  constructor(private readonly livreursService: LivreursService) {}

  // Admin only - list all livreurs
  @Get()
  @UseGuards(JwtAuthGuard, AdminGuard)
  findAll(
    @Query('city') city?: string,
    @Query('isOnline') isOnline?: string,
  ) {
    return this.livreursService.findAll(city, isOnline === 'true');
  }

  // Find available livreurs nearby (for order assignment)
  @Get('available')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('restaurant', 'admin')
  findAvailableNearby(
    @Query('latitude') latitude: string,
    @Query('longitude') longitude: string,
    @Query('radius') radius?: string,
  ) {
    if (!latitude || !longitude) {
      return [];
    }
    return this.livreursService.findAvailableNearby(
      parseFloat(latitude),
      parseFloat(longitude),
      radius ? parseFloat(radius) : 5,
    );
  }

  // Get livreur profile
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async findOne(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    // Livreurs can only view their own profile
    if (user.role === 'livreur' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.livreursService.findOne(id);
  }

  // Update location (livreur only)
  @Put(':id/location')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('livreur')
  async updateLocation(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() body: { latitude: number; longitude: number },
  ) {
    if (user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    
    // Validate coordinates
    if (
      typeof body.latitude !== 'number' ||
      typeof body.longitude !== 'number' ||
      body.latitude < -90 || body.latitude > 90 ||
      body.longitude < -180 || body.longitude > 180
    ) {
      throw new ForbiddenException('Invalid coordinates');
    }

    return this.livreursService.updateLocation(id, body.latitude, body.longitude);
  }

  // Update online status (livreur only)
  @Put(':id/online')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('livreur')
  async updateOnlineStatus(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body('isOnline') isOnline: boolean,
  ) {
    if (user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.livreursService.updateOnlineStatus(id, isOnline);
  }

  // Get livreur zones
  @Get(':id/zones')
  @UseGuards(JwtAuthGuard)
  async getZones(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    if (user.role === 'livreur' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.livreursService.getZones(id);
  }

  // Add zone (livreur only)
  @Post(':id/zones')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('livreur')
  async addZone(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() body: { city: string; wilaya: string },
  ) {
    if (user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.livreursService.addZone(id, body.city, body.wilaya);
  }

  // Remove zone (livreur only)
  @Delete('zones/:zoneId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('livreur')
  async removeZone(
    @Param('zoneId') zoneId: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    // TODO: Verify zone belongs to this livreur
    return this.livreursService.removeZone(zoneId);
  }

  // Update livreur profile
  @Put(':id')
  @UseGuards(JwtAuthGuard)
  async updateProfile(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() data: Partial<{
      fullName: string;
      email: string;
      vehicleType: string;
      vehiclePlate: string;
    }>,
  ) {
    if (user.role === 'livreur' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.livreursService.update(id, data);
  }
}
