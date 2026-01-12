import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Restaurant } from './entities/restaurant.entity';
import { RestaurantCategory } from './entities/restaurant-category.entity';
import { MenuCategory } from './entities/menu-category.entity';
import { MenuItem } from './entities/menu-item.entity';
import { MenuItemOption } from './entities/menu-item-option.entity';
import { MenuItemOptionChoice } from './entities/menu-item-option-choice.entity';
import { RestaurantsController } from './restaurants.controller';
import { RestaurantsService } from './restaurants.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Restaurant,
      RestaurantCategory,
      MenuCategory,
      MenuItem,
      MenuItemOption,
      MenuItemOptionChoice,
    ]),
  ],
  controllers: [RestaurantsController],
  providers: [RestaurantsService],
  exports: [RestaurantsService],
})
export class RestaurantsModule {}
