import { Entity, PrimaryGeneratedColumn, Column, OneToMany, ManyToOne } from 'typeorm';
import { MenuItemOptionChoice } from './menu-item-option-choice.entity';
import { MenuItem } from './menu-item.entity';

@Entity('menu_item_options')
export class MenuItemOption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  menuItemId: string;

  @Column({ length: 100 })
  name: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  price: number;

  @Column({ default: false })
  isRequired: boolean;

  @Column({ default: 1 })
  maxSelections: number;

  // Relations
  @ManyToOne(() => MenuItem, menuItem => menuItem.options)
  menuItem: MenuItem;

  @OneToMany(() => MenuItemOptionChoice, choice => choice.option)
  choices: MenuItemOptionChoice[];
}
