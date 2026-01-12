import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private firebaseApp: admin.app.App;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const firebaseConfig = this.configService.get('firebase');
    
    if (firebaseConfig?.projectId) {
      this.firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: firebaseConfig.projectId,
          clientEmail: firebaseConfig.clientEmail,
          privateKey: firebaseConfig.privateKey?.replace(/\\n/g, '\n'),
        }),
      });
    }
  }

  async sendNotification(
    token: string,
    title: string,
    body: string,
    data?: Record<string, any>,
  ): Promise<string> {
    if (!this.firebaseApp) {
      console.warn('Firebase not initialized, skipping notification');
      return null;
    }

    const message: admin.messaging.Message = {
      token,
      notification: {
        title,
        body,
      },
      data: data ? this.stringifyData(data) : undefined,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'dz_delivery_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    return admin.messaging().send(message);
  }

  async sendToMultiple(
    tokens: string[],
    title: string,
    body: string,
    data?: Record<string, any>,
  ): Promise<admin.messaging.BatchResponse> {
    if (!this.firebaseApp || tokens.length === 0) {
      return null;
    }

    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title,
        body,
      },
      data: data ? this.stringifyData(data) : undefined,
    };

    return admin.messaging().sendEachForMulticast(message);
  }

  private stringifyData(data: Record<string, any>): Record<string, string> {
    const result: Record<string, string> = {};
    for (const [key, value] of Object.entries(data)) {
      result[key] = typeof value === 'string' ? value : JSON.stringify(value);
    }
    return result;
  }
}
