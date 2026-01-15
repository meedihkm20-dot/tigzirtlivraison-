export interface OrderItem {
  menu_item_id: string;
  quantity: number;
  unit_price: number;
  total_price: number;
  name: string;
}

export interface CreateOrderResponse {
  order: any;
  items: OrderItem[];
}
