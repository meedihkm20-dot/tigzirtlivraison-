import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
  WsException,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Logger } from '@nestjs/common';
import { OrderStatus } from './entities/order.entity';

interface AuthenticatedSocket extends Socket {
  user?: {
    id: string;
    role: string;
    phone: string;
  };
}

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: '/orders',
})
export class OrdersGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(OrdersGateway.name);
  private connectedClients: Map<string, AuthenticatedSocket> = new Map();

  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async handleConnection(client: AuthenticatedSocket) {
    try {
      // Extract and verify JWT token
      const token = this.extractToken(client);
      if (!token) {
        this.logger.warn(`Client ${client.id} connected without token`);
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('jwt.secret'),
      });

      client.user = {
        id: payload.sub,
        role: payload.role,
        phone: payload.phone,
      };

      this.connectedClients.set(client.id, client);
      this.logger.log(`Client ${client.id} connected as ${payload.role}:${payload.sub}`);
    } catch (error) {
      this.logger.warn(`Client ${client.id} failed authentication: ${error.message}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: AuthenticatedSocket) {
    this.logger.log(`Client ${client.id} disconnected`);
    this.connectedClients.delete(client.id);
  }

  private extractToken(client: Socket): string | null {
    const authHeader = client.handshake.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }
    return client.handshake.auth?.token || client.handshake.query?.token as string;
  }

  @SubscribeMessage('join')
  handleJoin(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { role: string; entityId: string },
  ) {
    if (!client.user) {
      throw new WsException('Unauthorized');
    }

    // Verify user can only join their own room
    if (data.entityId !== client.user.id) {
      throw new WsException('Access denied');
    }

    const room = `${data.role}:${data.entityId}`;
    client.join(room);
    this.logger.log(`Client ${client.id} joined room ${room}`);
    
    return { success: true, room };
  }

  @SubscribeMessage('joinOrder')
  async handleJoinOrder(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() orderId: string,
  ) {
    if (!client.user) {
      throw new WsException('Unauthorized');
    }

    // TODO: Verify user has access to this order
    // This should check if the user is the customer, restaurant, or livreur for this order

    client.join(`order:${orderId}`);
    this.logger.log(`Client ${client.id} joined order room ${orderId}`);
    
    return { success: true, orderId };
  }

  @SubscribeMessage('leaveOrder')
  handleLeaveOrder(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() orderId: string,
  ) {
    client.leave(`order:${orderId}`);
    return { success: true };
  }

  // Emit new order to restaurant
  emitNewOrder(restaurantId: string, order: any) {
    this.server.to(`restaurant:${restaurantId}`).emit('newOrder', {
      ...order,
      // Remove sensitive data
      confirmationCode: undefined,
    });
  }

  // Emit order status update
  emitOrderStatusUpdate(orderId: string, status: OrderStatus, order: any) {
    this.server.to(`order:${orderId}`).emit('orderStatusUpdate', { 
      status, 
      order: {
        ...order,
        confirmationCode: undefined,
      },
    });
  }

  // Emit to specific user
  emitToUser(userId: string, event: string, data: any) {
    this.server.to(`user:${userId}`).emit(event, data);
  }

  // Emit to specific livreur
  emitToLivreur(livreurId: string, event: string, data: any) {
    this.server.to(`livreur:${livreurId}`).emit(event, data);
  }

  // Emit livreur location update
  @SubscribeMessage('updateLocation')
  handleLocationUpdate(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { orderId: string; latitude: number; longitude: number },
  ) {
    if (!client.user || client.user.role !== 'livreur') {
      throw new WsException('Only livreurs can update location');
    }

    // Validate coordinates
    if (
      typeof data.latitude !== 'number' ||
      typeof data.longitude !== 'number' ||
      data.latitude < -90 || data.latitude > 90 ||
      data.longitude < -180 || data.longitude > 180
    ) {
      throw new WsException('Invalid coordinates');
    }

    this.server.to(`order:${data.orderId}`).emit('livreurLocation', {
      latitude: data.latitude,
      longitude: data.longitude,
      timestamp: new Date().toISOString(),
    });

    return { success: true };
  }
}
