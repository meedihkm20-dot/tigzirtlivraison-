import { Controller, Get, Post, Body, Put, Param, Delete, UseGuards, ForbiddenException } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AdminGuard } from '../../common/guards/admin.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UpdateUserDto, CreateAddressDto } from './dto/update-user.dto';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // Admin only - list all users
  @Get()
  @UseGuards(AdminGuard)
  findAll() {
    return this.usersService.findAll();
  }

  // Get current user profile
  @Get('me')
  getMyProfile(@CurrentUser('id') userId: string) {
    return this.usersService.findOne(userId);
  }

  // Get user by ID (admin or self only)
  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    // Users can only view their own profile
    if (user.role === 'user' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.usersService.findOne(id);
  }

  // Update user profile (self only)
  @Put(':id')
  async update(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() updateUserDto: UpdateUserDto,
  ) {
    // Users can only update their own profile
    if (user.role === 'user' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.usersService.update(id, updateUserDto);
  }

  // Delete user (admin only)
  @Delete(':id')
  @UseGuards(AdminGuard)
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }

  // Get user addresses (self only)
  @Get(':id/addresses')
  async getUserAddresses(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    if (user.role === 'user' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.usersService.getUserAddresses(id);
  }

  // Add address (self only)
  @Post(':id/addresses')
  async addAddress(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() addressData: CreateAddressDto,
  ) {
    if (user.role === 'user' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.usersService.addAddress(id, addressData);
  }

  // Update address
  @Put(':id/addresses/:addressId')
  async updateAddress(
    @Param('id') id: string,
    @Param('addressId') addressId: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() addressData: Partial<CreateAddressDto>,
  ) {
    if (user.role === 'user' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.usersService.updateAddress(addressId, addressData);
  }

  // Delete address
  @Delete(':id/addresses/:addressId')
  async deleteAddress(
    @Param('id') id: string,
    @Param('addressId') addressId: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    if (user.role === 'user' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.usersService.deleteAddress(addressId);
  }

  // Set default address
  @Put(':id/addresses/:addressId/default')
  async setDefaultAddress(
    @Param('id') id: string,
    @Param('addressId') addressId: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    if (user.role === 'user' && user.id !== id) {
      throw new ForbiddenException('Access denied');
    }
    return this.usersService.setDefaultAddress(id, addressId);
  }
}
