import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { MenuItemOption } from './menu-item-option.entity';

@Entity('menu_item_option_choices')
export class MenuItemOptionChoice {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  optionId: string;

  @Column({ length: 100 })
  name: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  price: number;

  // Relations
  @ManyToOne(() => MenuItemOption, option => option.choices)
  option: MenuItemOption;
}
