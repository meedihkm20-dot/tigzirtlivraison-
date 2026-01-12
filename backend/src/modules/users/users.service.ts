import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { UserAddress } from './entities/user-address.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(UserAddress)
    private addressesRepository: Repository<UserAddress>,
  ) {}

  async create(data: Partial<User>): Promise<User> {
    const user = this.usersRepository.create(data);
    return this.usersRepository.save(user);
  }

  async findAll(): Promise<User[]> {
    return this.usersRepository.find({
      select: ['id', 'phone', 'fullName', 'email', 'isActive', 'isVerified', 'createdAt'],
    });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({
      where: { id },
      relations: ['addresses'],
      select: ['id', 'phone', 'fullName', 'email', 'defaultAddressId', 'isActive', 'isVerified', 'createdAt', 'updatedAt'],
    });
    if (!user) {
      throw new NotFoundException(`User #${id} not found`);
    }
    return user;
  }

  async findByPhone(phone: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { phone } });
  }

  async update(id: string, data: Partial<User>): Promise<User> {
    // Prevent updating sensitive fields
    delete (data as any).passwordHash;
    delete (data as any).phone;
    delete (data as any).isVerified;
    
    await this.usersRepository.update(id, data);
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    const result = await this.usersRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException(`User #${id} not found`);
    }
  }

  // Addresses
  async addAddress(userId: string, addressData: Partial<UserAddress>): Promise<UserAddress> {
    // If this is the first address, make it default
    const existingAddresses = await this.addressesRepository.count({ where: { userId } });
    const isDefault = existingAddresses === 0;

    const address = this.addressesRepository.create({
      ...addressData,
      userId,
      isDefault,
    });
    const savedAddress = await this.addressesRepository.save(address);

    // Update user's default address if this is the first one
    if (isDefault) {
      await this.usersRepository.update(userId, { defaultAddressId: savedAddress.id });
    }

    return savedAddress;
  }

  async getUserAddresses(userId: string): Promise<UserAddress[]> {
    return this.addressesRepository.find({
      where: { userId },
      order: { isDefault: 'DESC', createdAt: 'DESC' },
    });
  }

  async updateAddress(addressId: string, data: Partial<UserAddress>): Promise<UserAddress> {
    // Prevent updating userId
    delete (data as any).userId;
    
    await this.addressesRepository.update(addressId, data);
    return this.addressesRepository.findOne({ where: { id: addressId } });
  }

  async deleteAddress(addressId: string): Promise<void> {
    const address = await this.addressesRepository.findOne({ where: { id: addressId } });
    if (!address) {
      throw new NotFoundException(`Address #${addressId} not found`);
    }

    await this.addressesRepository.delete(addressId);

    // If this was the default address, set another one as default
    if (address.isDefault) {
      const nextAddress = await this.addressesRepository.findOne({
        where: { userId: address.userId },
        order: { createdAt: 'DESC' },
      });
      if (nextAddress) {
        await this.addressesRepository.update(nextAddress.id, { isDefault: true });
        await this.usersRepository.update(address.userId, { defaultAddressId: nextAddress.id });
      } else {
        await this.usersRepository.update(address.userId, { defaultAddressId: null });
      }
    }
  }

  async setDefaultAddress(userId: string, addressId: string): Promise<void> {
    // Remove default from all addresses
    await this.addressesRepository.update({ userId }, { isDefault: false });
    
    // Set new default
    await this.addressesRepository.update(addressId, { isDefault: true });
    await this.usersRepository.update(userId, { defaultAddressId: addressId });
  }
}
