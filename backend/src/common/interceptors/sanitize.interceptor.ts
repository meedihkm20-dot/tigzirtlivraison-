import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

/**
 * Interceptor to sanitize sensitive data from responses
 */
@Injectable()
export class SanitizeInterceptor implements NestInterceptor {
  private sensitiveFields = [
    'passwordHash',
    'password',
    'refreshToken',
    'accessToken',
    'token',
    'secret',
    'privateKey',
    'apiKey',
  ];

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      map((data) => this.sanitize(data)),
    );
  }

  private sanitize(data: any): any {
    if (data === null || data === undefined) {
      return data;
    }

    if (Array.isArray(data)) {
      return data.map((item) => this.sanitize(item));
    }

    if (typeof data === 'object') {
      const sanitized = { ...data };
      for (const key of Object.keys(sanitized)) {
        if (this.sensitiveFields.includes(key)) {
          delete sanitized[key];
        } else if (typeof sanitized[key] === 'object') {
          sanitized[key] = this.sanitize(sanitized[key]);
        }
      }
      return sanitized;
    }

    return data;
  }
}
