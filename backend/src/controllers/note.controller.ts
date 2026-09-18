import { Response, NextFunction } from 'express';
import { NoteService } from '../services/note.service';
import { sendSuccess } from '../utils/response';
import { AuthenticatedRequest } from '../middleware/auth.middleware';

export class NoteController {
  static async getNotes(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const notes = await NoteService.getNotesByTaskId(req.params.id);
      return sendSuccess(res, notes, 'Task notes retrieved');
    } catch (error) {
      next(error);
    }
  }

  static async createNote(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const note = await NoteService.createNote(req.params.id, req.user!.userId, req.body);
      return sendSuccess(res, note, 'Note created successfully', 201);
    } catch (error) {
      next(error);
    }
  }
}

