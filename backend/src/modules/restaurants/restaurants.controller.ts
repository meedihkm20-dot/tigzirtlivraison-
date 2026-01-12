import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, ForbiddenException } from '@nestjs/common';
import { RestaurantsService } from './restaurants.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('restaurants')
export class RestaurantsController {
  constructor(private readonly restaurantsService: RestaurantsService) {}

  // Public routes
  @Get()
  findAll(
    @Query('city') city?: string,
    @Query('isOpen') isOpen?: string,
  ) {
    return this.restaurantsService.findAll(city, isOpen === 'true');
  }

  @Get('categories')
  getAllCategories() {
    return this.restaurantsService.getAllCategories();
  }

  @Get('nearby')
  findNearby(
    @Query('latitude') latitude: string,
    @Query('longitude') longitude: string,
    @Query('radius') radius?: string,
  ) {
    if (!latitude || !longitude) {
      return [];
    }
    return this.restaurantsService.findNearby(
      parseFloat(latitude),
      parseFloat(longitude),
      radius ? parseFloat(radius) : 5,
    );
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.restaurantsService.findOne(id);
  }

  @Get('slug/:slug')
  findBySlug(@Param('slug') slug: string) {
    return this.restaurantsService.findBySlug(slug);
  }

  @Get(':id/menu')
  getMenu(@Param('id') id: string) {
    return this.restaurantsService.getMenuCategories(id);
  }

  @Get(':id/menu/items')
  getMenuItems(
    @Param('id') id: string,
    @Query('categoryId') categoryId?: string,
  ) {
    return this.restaurantsService.getMenuItems(id, categoryId);
  }

  // Protected routes for restaurant owners
  @Put(':id/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('restaurant')
  async updateOpenStatus(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body('isOpen') isOpen: boolean,
  ) {
    // Verify restaurant owns this resource
    if (user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.restaurantsService.updateOpenStatus(id, isOpen);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('restaurant', 'admin')
  async updateRestaurant(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() data: Partial<{
      name: string;
      description: string;
      address: string;
      logoUrl: string;
      coverImageUrl: string;
      minOrderAmount: number;
      avgPreparationTime: number;
      openingHours: Record<string, { open: string; close: string }>;
    }>,
  ) {
    // Verify restaurant owns this resource (unless admin)
    if (user.role === 'restaurant' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.restaurantsService.update(id, data);
  }

  @Post(':id/menu/categories')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('restaurant')
  async createMenuCategory(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() data: { name: string; description?: string; displayOrder?: number },
  ) {
    if (user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.restaurantsService.createMenuCategory(id, data);
  }

  @Put('menu/categories/:categoryId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('restaurant')
  async updateMenuCategory(
    @Param('categoryId') categoryId: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() data: { name?: string; description?: string; displayOrder?: number; isActive?: boolean },
  ) {
    // TODO: Verify category belongs to this restaurant
    return this.restaurantsService.updateMenuCategory(categoryId, data);
  }

  @Post(':id/menu/items')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('restaurant')
  async createMenuItem(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() data: {
      categoryId?: string;
      name: string;
      description?: string;
      price: number;
      imageUrl?: string;
      preparationTime?: number;
    },
  ) {
    if (user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.restaurantsService.createMenuItem(id, data);
  }

  @Put('menu/items/:itemId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('restaurant')
  async updateMenuItem(
    @Param('itemId') itemId: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() data: Partial<{
      name: string;
      description: string;
      price: number;
      imageUrl: string;
      isAvailable: boolean;
      isFeatured: boolean;
    }>,
  ) {
    // TODO: Verify item belongs to this restaurant
    return this.restaurantsService.updateMenuItem(itemId, data);
  }

  @Delete('menu/items/:itemId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('restaurant')
  async deleteMenuItem(
    @Param('itemId') itemId: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    // TODO: Verify item belongs to this restaurant
    return this.restaurantsService.deleteMenuItem(itemId);
  }
}
