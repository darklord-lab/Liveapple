import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';
import { getStorageService, UploadedFileInput } from './storage.service.js';

export interface CreateFolderDto {
  instituteId: string;
  batchId: string;
  userId: string;
  userRole: string;
  name: string;
  parentId?: string;
}

export interface UploadMaterialDto {
  instituteId: string;
  batchId: string;
  userId: string;
  userRole: string;
  title: string;
  description?: string;
  kind?: string;
  folderId?: string;
  isFree?: boolean;
  url?: string;
  file?: UploadedFileInput;
}

export interface GetMaterialsFilter {
  instituteId: string;
  batchId: string;
  userId: string;
  userRole: string;
  folderId?: string | null;
  q?: string;
  sort?: string;
}

export class MaterialService {
  private storage = getStorageService();

  // 1. Create a Folder inside a Batch
  async createFolder(dto: CreateFolderDto) {
    if (dto.userRole !== 'TEACHER' && dto.userRole !== 'ADMIN') {
      throw new AppError('FORBIDDEN', 'Only teachers and admins can create folders', 403);
    }

    if (!dto.name || dto.name.trim().length === 0) {
      throw new AppError('BAD_REQUEST', 'Folder name is required', 400);
    }

    // Verify batch exists in institute
    const batch = await prisma.batch.findFirst({
      where: { id: dto.batchId, instituteId: dto.instituteId },
    });
    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found in this institute', 404);
    }

    // If parentId is provided, verify it exists and belongs to same batch
    if (dto.parentId) {
      const parent = await prisma.materialFolder.findFirst({
        where: { id: dto.parentId, batchId: dto.batchId, instituteId: dto.instituteId },
      });
      if (!parent) {
        throw new AppError('NOT_FOUND', 'Parent folder not found in this batch', 404);
      }
    }

    const folder = await prisma.materialFolder.create({
      data: {
        instituteId: dto.instituteId,
        batchId: dto.batchId,
        name: dto.name.trim(),
        parentId: dto.parentId || null,
      },
    });

    return folder;
  }

  // 2. List Folders in a Batch
  async getFolders(instituteId: string, batchId: string, parentId?: string | null) {
    const whereClause: any = {
      instituteId,
      batchId,
    };

    if (parentId !== undefined) {
      whereClause.parentId = parentId;
    }

    return prisma.materialFolder.findMany({
      where: whereClause,
      include: {
        _count: {
          select: {
            materials: true,
            children: true,
          },
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  // 3. Delete a Folder
  async deleteFolder(instituteId: string, folderId: string, userRole: string) {
    if (userRole !== 'TEACHER' && userRole !== 'ADMIN') {
      throw new AppError('FORBIDDEN', 'Only teachers and admins can delete folders', 403);
    }

    const folder = await prisma.materialFolder.findFirst({
      where: { id: folderId, instituteId },
      include: { materials: true },
    });

    if (!folder) {
      throw new AppError('NOT_FOUND', 'Folder not found', 404);
    }

    // Delete associated physical files from disk
    for (const m of folder.materials) {
      if (m.fileKey) {
        await this.storage.delete(m.fileKey);
      }
    }

    await prisma.materialFolder.delete({
      where: { id: folderId },
    });

    return { success: true };
  }

  // 4. Upload Material (File or Link)
  async uploadMaterial(dto: UploadMaterialDto) {
    if (dto.userRole !== 'TEACHER' && dto.userRole !== 'ADMIN') {
      throw new AppError('FORBIDDEN', 'Only teachers and admins can upload study materials', 403);
    }

    if (!dto.title || dto.title.trim().length === 0) {
      throw new AppError('BAD_REQUEST', 'Title is required', 400);
    }

    const batch = await prisma.batch.findFirst({
      where: { id: dto.batchId, instituteId: dto.instituteId },
    });
    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found in this institute', 404);
    }

    if (dto.folderId) {
      const folder = await prisma.materialFolder.findFirst({
        where: { id: dto.folderId, batchId: dto.batchId, instituteId: dto.instituteId },
      });
      if (!folder) {
        throw new AppError('NOT_FOUND', 'Folder not found in this batch', 404);
      }
    }

    let fileKey: string | undefined;
    let fileName: string | undefined;
    let mimeType: string | undefined;
    let sizeBytes: number | undefined;
    let kind = dto.kind || 'DOC';

    if (dto.file) {
      // Physical file upload through storage service
      const putResult = await this.storage.put(dto.file);
      fileKey = putResult.key;
      sizeBytes = putResult.sizeBytes;
      mimeType = putResult.mimeType;

      // Sanitize display filename (prevent header injection/path chars)
      fileName = dto.file.originalname.replace(/[/\\?%*:|"<>]/g, '_');

      // Auto-detect kind from MIME if not explicitly given
      if (mimeType.includes('pdf')) {
        kind = 'PDF';
      } else if (mimeType.includes('image')) {
        kind = 'IMAGE';
      } else {
        kind = 'DOC';
      }
    } else if (dto.url) {
      // Link or Video Link
      const trimmedUrl = dto.url.trim();
      if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
        throw new AppError('BAD_REQUEST', 'URL must begin with http:// or https://', 400);
      }
      if (trimmedUrl.includes('youtube.com') || trimmedUrl.includes('youtu.be') || trimmedUrl.includes('vimeo')) {
        kind = 'VIDEO_LINK';
      } else {
        kind = 'LINK';
      }
    } else {
      throw new AppError('BAD_REQUEST', 'Either a file upload or external URL link is required', 400);
    }

    const material = await prisma.studyMaterial.create({
      data: {
        instituteId: dto.instituteId,
        batchId: dto.batchId,
        folderId: dto.folderId || null,
        title: dto.title.trim(),
        description: dto.description?.trim() || null,
        kind,
        fileKey: fileKey || null,
        fileName: fileName || null,
        mimeType: mimeType || null,
        url: dto.url?.trim() || null,
        sizeBytes: sizeBytes || null,
        isFree: Boolean(dto.isFree),
        uploadedById: dto.userId,
      },
    });

    return material;
  }

  // 5. Get Materials for a Batch (with enrollment & free preview checks)
  async getMaterials(filter: GetMaterialsFilter) {
    const isStudent = filter.userRole === 'STUDENT';

    let isEnrolled = false;
    if (isStudent) {
      const enrollment = await prisma.enrollment.findUnique({
        where: {
          instituteId_batchId_studentId: {
            instituteId: filter.instituteId,
            batchId: filter.batchId,
            studentId: filter.userId,
          },
        },
      });
      isEnrolled = enrollment?.status === 'ACTIVE';
    }

    const whereClause: any = {
      instituteId: filter.instituteId,
      batchId: filter.batchId,
    };

    // If student is NOT enrolled, restrict to free preview materials only
    if (isStudent && !isEnrolled) {
      whereClause.isFree = true;
    }

    if (filter.folderId !== undefined) {
      whereClause.folderId = filter.folderId;
    }

    if (filter.q && filter.q.trim().length > 0) {
      const term = filter.q.trim();
      whereClause.OR = [
        { title: { contains: term } },
        { description: { contains: term } },
        { fileName: { contains: term } },
      ];
    }

    let orderBy: any = { createdAt: 'desc' };
    if (filter.sort === 'oldest') {
      orderBy = { createdAt: 'asc' };
    } else if (filter.sort === 'title_asc') {
      orderBy = { title: 'asc' };
    } else if (filter.sort === 'title_desc') {
      orderBy = { title: 'desc' };
    }

    const materials = await prisma.studyMaterial.findMany({
      where: whereClause,
      include: {
        folder: {
          select: { id: true, name: true },
        },
        uploadedBy: {
          select: { id: true, name: true, role: true },
        },
      },
      orderBy,
    });

    return {
      isEnrolled: !isStudent || isEnrolled,
      materials,
    };
  }

  // 6. Download / View Material (Stream with authorization checks)
  async getDownloadStream(instituteId: string, materialId: string, userId: string, userRole: string) {
    const material = await prisma.studyMaterial.findUnique({
      where: { id: materialId },
    });

    if (!material || material.instituteId !== instituteId) {
      throw new AppError('NOT_FOUND', 'Study material not found', 404);
    }

    if (!material.fileKey) {
      throw new AppError('BAD_REQUEST', 'This study material is a link, not a stored file', 400);
    }

    // Authorization check for Students:
    // If not marked 'isFree', student MUST have an active enrollment in the batch
    if (userRole === 'STUDENT' && !material.isFree) {
      const enrollment = await prisma.enrollment.findUnique({
        where: {
          instituteId_batchId_studentId: {
            instituteId,
            batchId: material.batchId,
            studentId: userId,
          },
        },
      });

      if (!enrollment || enrollment.status !== 'ACTIVE') {
        throw new AppError(
          'ENROLLMENT_REQUIRED',
          'You must be actively enrolled in this batch to access this study material',
          403
        );
      }
    }

    const stream = this.storage.getStream(material.fileKey);

    return {
      stream,
      fileName: material.fileName || 'document.pdf',
      mimeType: material.mimeType || 'application/octet-stream',
      sizeBytes: material.sizeBytes || 0,
    };
  }

  // 7. Delete Material
  async deleteMaterial(instituteId: string, materialId: string, userRole: string) {
    if (userRole !== 'TEACHER' && userRole !== 'ADMIN') {
      throw new AppError('FORBIDDEN', 'Only teachers and admins can delete study materials', 403);
    }

    const material = await prisma.studyMaterial.findUnique({
      where: { id: materialId },
    });

    if (!material || material.instituteId !== instituteId) {
      throw new AppError('NOT_FOUND', 'Study material not found', 404);
    }

    if (material.fileKey) {
      await this.storage.delete(material.fileKey);
    }

    await prisma.studyMaterial.delete({
      where: { id: materialId },
    });

    return { success: true };
  }
}

export const materialService = new MaterialService();
