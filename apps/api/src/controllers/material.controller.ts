import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { materialService } from '../services/material.service.js';
import { AppError } from '../errors/AppError.js';

const createFolderSchema = z.object({
  name: z.string().min(1, 'Folder name is required').max(100, 'Folder name too long'),
  parentId: z.string().optional(),
});

const uploadMaterialSchema = z.object({
  title: z.string().min(1, 'Title is required').max(150, 'Title is too long'),
  description: z.string().max(1000).optional(),
  kind: z.enum(['PDF', 'DOC', 'IMAGE', 'VIDEO_LINK', 'LINK']).optional(),
  folderId: z.string().optional(),
  isFree: z.union([z.boolean(), z.string().transform((v) => v === 'true' || v === '1')]).optional(),
  url: z.string().url('Invalid URL format').optional(),
});

export class MaterialController {
  // 1. POST /v1/batches/:id/folders
  static async createFolder(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const batchId = req.params.id;
      const userId = req.user!.userId;
      const userRole = req.user!.role;

      const body = createFolderSchema.parse(req.body);

      const folder = await materialService.createFolder({
        instituteId,
        batchId,
        userId,
        userRole,
        name: body.name,
        parentId: body.parentId,
      });

      res.status(201).json({
        status: 'success',
        data: folder,
      });
    } catch (err) {
      next(err);
    }
  }

  // 2. GET /v1/batches/:id/folders
  static async getFolders(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const batchId = req.params.id;
      const parentId = req.query.parentId as string | undefined;

      const folders = await materialService.getFolders(
        instituteId,
        batchId,
        parentId === 'root' ? null : parentId
      );

      res.status(200).json({
        status: 'success',
        data: folders,
      });
    } catch (err) {
      next(err);
    }
  }

  // 3. DELETE /v1/folders/:id
  static async deleteFolder(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const folderId = req.params.id;
      const userRole = req.user!.role;

      const result = await materialService.deleteFolder(instituteId, folderId, userRole);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  // 4. POST /v1/batches/:id/materials (multipart or JSON)
  static async uploadMaterial(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const batchId = req.params.id;
      const userId = req.user!.userId;
      const userRole = req.user!.role;

      const body = uploadMaterialSchema.parse(req.body);

      const file = req.file
        ? {
            buffer: req.file.buffer,
            mimetype: req.file.mimetype,
            originalname: req.file.originalname,
            size: req.file.size,
          }
        : undefined;

      const material = await materialService.uploadMaterial({
        instituteId,
        batchId,
        userId,
        userRole,
        title: body.title,
        description: body.description,
        kind: body.kind,
        folderId: body.folderId,
        isFree: body.isFree === true || body.isFree === 'true',
        url: body.url,
        file,
      });

      res.status(201).json({
        status: 'success',
        data: material,
      });
    } catch (err) {
      next(err);
    }
  }

  // 5. GET /v1/batches/:id/materials?folder=&q=&sort=
  static async getMaterials(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const batchId = req.params.id;
      const userId = req.user!.userId;
      const userRole = req.user!.role;

      const folderId = req.query.folder as string | undefined;
      const q = req.query.q as string | undefined;
      const sort = req.query.sort as string | undefined;

      const result = await materialService.getMaterials({
        instituteId,
        batchId,
        userId,
        userRole,
        folderId: folderId === 'root' ? null : folderId,
        q,
        sort,
      });

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  // 6. GET /v1/materials/:id/download
  static async downloadMaterial(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const materialId = req.params.id;
      const userId = req.user!.userId;
      const userRole = req.user!.role;

      const fileInfo = await materialService.getDownloadStream(
        instituteId,
        materialId,
        userId,
        userRole
      );

      res.setHeader('Content-Type', fileInfo.mimeType);
      // Safe Content-Disposition header with encoded filename
      const safeFilename = encodeURIComponent(fileInfo.fileName);
      res.setHeader(
        'Content-Disposition',
        `attachment; filename="${fileInfo.fileName.replace(/"/g, '')}"; filename*=UTF-8''${safeFilename}`
      );
      if (fileInfo.sizeBytes > 0) {
        res.setHeader('Content-Length', fileInfo.sizeBytes.toString());
      }

      fileInfo.stream.pipe(res);
    } catch (err) {
      next(err);
    }
  }

  // 7. DELETE /v1/materials/:id
  static async deleteMaterial(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const materialId = req.params.id;
      const userRole = req.user!.role;

      const result = await materialService.deleteMaterial(instituteId, materialId, userRole);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }
}
