import {
  Controller,
  Post,
  Delete,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { S3Service } from './s3.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('uploads')
export class UploadsController {
  constructor(private readonly s3Service: S3Service) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(
    @UploadedFile() file: Express.Multer.File,
    @Body('folder') folder?: string,
  ) {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    const allowedMimeTypes = [
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
      'application/pdf',
    ];

    if (!allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException('Invalid file type');
    }

    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      throw new BadRequestException('File too large (max 5MB)');
    }

    const url = await this.s3Service.uploadFile(
      file.buffer,
      file.originalname,
      file.mimetype,
      folder || 'uploads',
    );

    return { url };
  }

  @Post('signed-url')
  @UseGuards(JwtAuthGuard)
  async getSignedUploadUrl(
    @Body() body: { fileName: string; mimeType: string; folder?: string },
  ) {
    return this.s3Service.getSignedUploadUrl(
      body.fileName,
      body.mimeType,
      body.folder || 'uploads',
    );
  }

  @Delete()
  @UseGuards(JwtAuthGuard)
  async deleteFile(@Body('url') url: string) {
    await this.s3Service.deleteFile(url);
    return { success: true };
  }
}
