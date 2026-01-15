export interface OneSignalResponse {
  id?: string;
  errors?: string[];
}

export class NotifyOrderDto {
  order_id: string;
}

export class NotifyDriverAssignedDto {
  order_id: string;
  driver_id: string;
}

export class NotifyNewDeliveryDto {
  driver_id: string;
  order_id: string;
}

export class NotifyOrderCancelledDto {
  order_id: string;
  reason?: string;
}

export class TestNotificationDto {
  user_id: string;
  title: string;
  message: string;
}
