export interface OneSignalResponse {
  id?: string;
  errors?: string[];
}

export class NotifyOrderDto {
  order_id: string;
}

export class NotifyDriverAssignedDto {
  order_id: string;
  livreur_id: string; // ⚠️ SQL: "livreur_id" (pas "driver_id")
}

export class NotifyNewDeliveryDto {
  livreur_id: string; // ⚠️ SQL: "livreur_id" (pas "driver_id")
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
