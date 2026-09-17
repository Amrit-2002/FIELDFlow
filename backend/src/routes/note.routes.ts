import { Router } from 'express';
import { NoteController } from '../controllers/note.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validateBody } from '../middleware/validate.middleware';
import { createNoteSchema } from '../validators/note.validator';

const router = Router({ mergeParams: true });

router.use(authenticate);

router.get('/', NoteController.getNotes);
router.post('/', validateBody(createNoteSchema), NoteController.createNote);

export default router;
