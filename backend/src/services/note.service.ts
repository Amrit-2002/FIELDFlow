import { prisma } from '../config/database';
import { AppError } from '../utils/app-error';
import { CreateNoteInput } from '../validators/note.validator';
import { logger } from '../utils/logger';

export class NoteService {
  static async getNotesByTaskId(taskId: string) {
    const task = await prisma.task.findUnique({ where: { id: taskId } });
    if (!task) {
      throw AppError.notFound(`Task with ID ${taskId} not found`, 'TASK_NOT_FOUND');
    }

    return prisma.taskNote.findMany({
      where: { taskId },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { id: true, name: true, email: true } },
      },
    });
  }

  static async createNote(taskId: string, userId: string, input: CreateNoteInput) {
    const task = await prisma.task.findUnique({ where: { id: taskId } });
    if (!task) {
      throw AppError.notFound(`Task with ID ${taskId} not found`, 'TASK_NOT_FOUND');
    }

    const note = await prisma.taskNote.create({
      data: {
        taskId,
        userId,
        content: input.content,
      },
      include: {
        user: { select: { id: true, name: true } },
      },
    });

    logger.info('Note added to task', { taskId, noteId: note.id, userId });
    return note;
  }
}
