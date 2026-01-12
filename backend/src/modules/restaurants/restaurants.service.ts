import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Restaurant } from './entities/restaurant.entity';
import { RestaurantCategory } from './entities/restaurant-category.entity';
import { MenuCategory } from './entities/menu-category.entity';
import { MenuItem } from './entities/menu-item.entity';
import { MenuItemOption } from './entities/menu-item-option.entity';
import { MenuItemOptionChoice } from './entities/menu-item-option-choice.entity';

@Injectable()
export class RestaurantsService {
  constructor(
    @InjectRepository(Restaurant)
    private restaurantsRepository: Repository<Restaurant>,
    @InjectRepository(RestaurantCategory)
    private categoriesRepository: Repository<RestaurantCategory>,
    @InjectRepository(MenuCategory)
    private menuCategoriesRepository: Repository<MenuCategory>,
    @InjectRepository(MenuItem)
    private menuItemsRepository: Repository<MenuItem>,
    @InjectRepository(MenuItemOption)
    private menuItemOptionsRepository: Repository<MenuItemOption>,
    @InjectRepository(MenuItemOptionChoice)
    private menuItemOptionChoicesRepository: Repository<MenuItemOptionChoice>,
  ) {}

  // Restaurant CRUD
  async findAll(city?: string, isOpen?: boolean): Promise<Restaurant[]> {
    const query = this.restaurantsRepository.createQueryBuilder('restaurant')
      .where('restaurant.isActive = :isActive', { isActive: true });
    
    if (city) {
      query.andWhere('restaurant.city = :city', { city });
    }
    if (isOpen !== undefined) {
      query.andWhere('restaurant.isOpen = :isOpen', { isOpen });
    }
    
    return query.getMany();
  }

  async findOne(id: string): Promise<Restaurant> {
    const restaurant = await this.restaurantsRepository.findOne({
      where: { id },
      relations: ['menuCategories', 'menuItems', 'categories'],
    });
    if (!restaurant) {
      throw new NotFoundException(`Restaurant #${id} not found`);
    }
    return restaurant;
  }

  async findBySlug(slug: string): Promise<Restaurant> {
    const restaurant = await this.restaurantsRepository.findOne({
      where: { slug },
      relations: ['menuCategories', 'menuItems', 'categories'],
    });
    if (!restaurant) {
      throw new NotFoundException(`Restaurant with slug ${slug} not found`);
    }
    return restaurant;
  }

  async findByPhone(phone: string): Promise<Restaurant | null> {
    return this.restaurantsRepository.findOne({ where: { phone } });
  }

  async create(data: Partial<Restaurant>): Promise<Restaurant> {
    const restaurant = this.restaurantsRepository.create(data);
    return this.restaurantsRepository.save(restaurant);
  }

  async update(id: string, data: Partial<Restaurant>): Promise<Restaurant> {
    await this.restaurantsRepository.update(id, data);
    return this.findOne(id);
  }

  async updateOpenStatus(id: string, isOpen: boolean): Promise<Restaurant> {
    await this.restaurantsRepository.update(id, { isOpen });
    return this.findOne(id);
  }

  // Menu Categories
  async getMenuCategories(restaurantId: string): Promise<MenuCategory[]> {
    return this.menuCategoriesRepository.find({
      where: { restaurantId, isActive: true },
      order: { displayOrder: 'ASC' },
      relations: ['items'],
    });
  }

  async createMenuCategory(restaurantId: string, data: Partial<MenuCategory>): Promise<MenuCategory> {
    const category = this.menuCategoriesRepository.create({ ...data, restaurantId });
    return this.menuCategoriesRepository.save(category);
  }

  async updateMenuCategory(id: string, data: Partial<MenuCategory>): Promise<MenuCategory> {
    await this.menuCategoriesRepository.update(id, data);
    return this.menuCategoriesRepository.findOne({ where: { id } });
  }

  // Menu Items
  async getMenuItems(restaurantId: string, categoryId?: string): Promise<MenuItem[]> {
    const query = this.menuItemsRepository.createQueryBuilder('item')
      .where('item.restaurantId = :restaurantId', { restaurantId })
      .andWhere('item.isAvailable = :isAvailable', { isAvailable: true });
    
    if (categoryId) {
      query.andWhere('item.categoryId = :categoryId', { categoryId });
    }
    
    return query.leftJoinAndSelect('item.options', 'options')
      .leftJoinAndSelect('options.choices', 'choices')
      .getMany();
  }

  async createMenuItem(restaurantId: string, data: Partial<MenuItem>): Promise<MenuItem> {
    const item = this.menuItemsRepository.create({ ...data, restaurantId });
    return this.menuItemsRepository.save(item);
  }

  async updateMenuItem(id: string, data: Partial<MenuItem>): Promise<MenuItem> {
    await this.menuItemsRepository.update(id, data);
    return this.menuItemsRepository.findOne({ where: { id }, relations: ['options'] });
  }

  async deleteMenuItem(id: string): Promise<void> {
    await this.menuItemsRepository.delete(id);
  }

  // Restaurant Categories
  async getAllCategories(): Promise<RestaurantCategory[]> {
    return this.categoriesRepository.find({ order: { displayOrder: 'ASC' } });
  }

  // Nearby restaurants
  async findNearby(latitude: number, longitude: number, radiusKm: number = 5): Promise<Restaurant[]> {
    // Haversine formula for distance calculation
    return this.restaurantsRepository
      .createQueryBuilder('restaurant')
      .where('restaurant.isActive = :isActive', { isActive: true })
      .andWhere('restaurant.isOpen = :isOpen', { isOpen: true })
      .andWhere(`
        (6371 * acos(
          cos(radians(:latitude)) * cos(radians(restaurant.latitude)) *
          cos(radians(restaurant.longitude) - radians(:longitude)) +
          sin(radians(:latitude)) * sin(radians(restaurant.latitude))
        )) <= :radius
      `, { latitude, longitude, radius: radiusKm })
      .getMany();
  }
}
