import { TokenUserPayload } from '../utils/jwt.js';

declare global {
  namespace Express {
    interface Request {
      user?: TokenUserPayload;
    }
  }
}
