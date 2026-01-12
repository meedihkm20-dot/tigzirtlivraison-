import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

export const OWNER_KEY = 'owner_field';
export const OwnerField = (field: string) => Reflector.createDecorator<string>();

/**
 * Guard to ensure users can only access their own resources
 * Usage: @UseGuards(OwnerGuard) with @OwnerField('userId')
 */
@Injectable()
export class OwnerGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const params = request.params;
    const body = request.body;

    // Admins can access everything
    if (user?.role === 'admin' || user?.role === 'super_admin') {
      return true;
    }

    // Check if user is accessing their own resource
    const resourceId = params.id || params.userId || body.userId;
    
    if (resourceId && user?.id !== resourceId) {
      // Allow if the resource belongs to the user's entity type
      if (user?.role === 'restaurant' && params.restaurantId === user.id) {
        return true;
      }
      if (user?.role === 'livreur' && params.livreurId === user.id) {
        return true;
      }
    }

    return true;
  }
}
