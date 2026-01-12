import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v4 as uuidv4 } from 'uuid';

// S3 types - install @aws-sdk/client-s3 and @aws-sdk/s3-request-presigner
interface S3Config {
  region: string;
  credentials: {
    accessKeyId: string;
    secretAccessKey: string;
  };
}

@Injectable()
export class S3Service {
  private s3Client: any;
  private bucketName: string;

  constructor(private configService: ConfigService) {
    // Initialize S3 client when AWS SDK is installed
    // npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner
    this.bucketName = this.configService.get<string>('AWS_S3_BUCKET') || 'dz-delivery';
  }

  private async initS3Client() {
    if (this.s3Client) return;
    
    try {
      const { S3Client } = await import('@aws-sdk/client-s3');
      this.s3Client = new S3Client({
        region: this.configService.get<string>('AWS_REGION') || 'eu-west-1',
        credentials: {
          accessKeyId: this.configService.get<string>('AWS_ACCESS_KEY_ID'),
          secretAccessKey: this.configService.get<string>('AWS_SECRET_ACCESS_KEY'),
        },
      });
    } catch (error) {
      console.warn('AWS SDK not installed. S3 uploads will not work.');
    }
  }

  async uploadFile(
    file: Buffer,
    originalName: string,
    mimeType: string,
    folder: string = 'uploads',
  ): Promise<string> {
    await this.initS3Client();
    if (!this.s3Client) {
      throw new Error('S3 client not initialized. Install @aws-sdk/client-s3');
    }

    const { PutObjectCommand } = await import('@aws-sdk/client-s3');
    const extension = originalName.split('.').pop();
    const key = `${folder}/${uuidv4()}.${extension}`;

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: key,
      Body: file,
      ContentType: mimeType,
      ACL: 'public-read',
    });

    await this.s3Client.send(command);

    return `https://${this.bucketName}.s3.amazonaws.com/${key}`;
  }

  async deleteFile(url: string): Promise<void> {
    await this.initS3Client();
    if (!this.s3Client) return;

    const { DeleteObjectCommand } = await import('@aws-sdk/client-s3');
    const key = url.split('.amazonaws.com/')[1];
    if (!key) return;

    const command = new DeleteObjectCommand({
      Bucket: this.bucketName,
      Key: key,
    });

    await this.s3Client.send(command);
  }

  async getSignedUploadUrl(
    fileName: string,
    mimeType: string,
    folder: string = 'uploads',
  ): Promise<{ uploadUrl: string; fileUrl: string }> {
    await this.initS3Client();
    if (!this.s3Client) {
      throw new Error('S3 client not initialized. Install @aws-sdk/client-s3');
    }

    const { PutObjectCommand } = await import('@aws-sdk/client-s3');
    const { getSignedUrl } = await import('@aws-sdk/s3-request-presigner');
    
    const extension = fileName.split('.').pop();
    const key = `${folder}/${uuidv4()}.${extension}`;

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: key,
      ContentType: mimeType,
    });

    const uploadUrl = await getSignedUrl(this.s3Client, command, { expiresIn: 3600 });
    const fileUrl = `https://${this.bucketName}.s3.amazonaws.com/${key}`;

    return { uploadUrl, fileUrl };
  }
}
