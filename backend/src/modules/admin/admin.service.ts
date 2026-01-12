import { Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { AdminUser } from './entities/admin-user.entity';
import { AdminLog } from './entities/admin-log.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(AdminUser)
    private adminUsersRepository: Repository<AdminUser>,
    @InjectRepository(AdminLog)
    private adminLogsRepository: Repository<AdminLog>,
  ) {}

  async findByEmail(email: string): Promise<AdminUser | null> {
    return this.adminUsersRepository.findOne({ where: { email } });
  }

  async validateAdmin(email: string, password: string): Promise<AdminUser | null> {
    const admin = await this.findByEmail(email);
    if (admin && await bcrypt.compare(password, admin.passwordHash)) {
      await this.adminUsersRepository.update(admin.id, { lastLogin: new Date() });
      return admin;
    }
    return null;
  }

  async createAdmin(data: {
    email: string;
    password: string;
    fullName: string;
    role?: string;
    permissions?: string[];
  }): Promise<AdminUser> {
    const passwordHash = await bcrypt.hash(data.password, 10);
    const admin = this.adminUsersRepository.create({
      email: data.email,
      passwordHash,
      fullName: data.fullName,
      role: data.role || 'admin',
      permissions: data.permissions || [],
    });
    return this.adminUsersRepository.save(admin);
  }

  async findAll(): Promise<AdminUser[]> {
    return this.adminUsersRepository.find();
  }

  async findOne(id: string): Promise<AdminUser> {
    const admin = await this.adminUsersRepository.findOne({ where: { id } });
    if (!admin) {
      throw new NotFoundException(`Admin #${id} not found`);
    }
    return admin;
  }

  async updateAdmin(id: string, data: Partial<AdminUser>): Promise<AdminUser> {
    await this.adminUsersRepository.update(id, data);
    return this.findOne(id);
  }

  async deactivateAdmin(id: string): Promise<void> {
    await this.adminUsersRepository.update(id, { isActive: false });
  }

  // Logging
  async logAction(
    adminId: string,
    action: string,
    entityType?: string,
    entityId?: string,
    details?: Record<string, any>,
  ): Promise<void> {
    const log = this.adminLogsRepository.create({
      adminId,
      action,
      entityType,
      entityId,
      details,
    });
    await this.adminLogsRepository.save(log);
  }

  async getAdminLogs(adminId?: string, limit: number = 100): Promise<AdminLog[]> {
    const query = this.adminLogsRepository.createQueryBuilder('log')
      .orderBy('log.createdAt', 'DESC')
      .take(limit);

    if (adminId) {
      query.where('log.adminId = :adminId', { adminId });
    }

    return query.getMany();
  }
}
