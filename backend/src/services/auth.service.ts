import bcrypt from 'bcryptjs';
import { prisma } from '../config/database';
import { AppError } from '../utils/app-error';
import { generateTokens, verifyRefreshToken } from '../utils/jwt';
import { LoginInput } from '../validators/auth.validator';
import { logger } from '../utils/logger';

export class AuthService {
  static async login(input: LoginInput) {
    const user = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase() },
    });

    if (!user) {
      logger.warn('Login failed: User not found', { email: input.email });
      throw AppError.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS');
    }

    const isValidPassword = await bcrypt.compare(input.password, user.passwordHash);
    if (!isValidPassword) {
      logger.warn('Login failed: Password mismatch', { email: input.email });
      throw AppError.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS');
    }

    const tokens = generateTokens({
      userId: user.id,
      email: user.email,
      role: user.role,
    });

    logger.info('User logged in successfully', { userId: user.id, email: user.email, role: user.role });

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    };
  }

  static async refreshToken(refreshToken: string) {
    const payload = verifyRefreshToken(refreshToken);

    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
    });

    if (!user) {
      throw AppError.unauthorized('User not found', 'USER_NOT_FOUND');
    }

    const tokens = generateTokens({
      userId: user.id,
      email: user.email,
      role: user.role,
    });

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    };
  }

  static async getMe(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    if (!user) {
      throw AppError.notFound('User not found', 'USER_NOT_FOUND');
    }

    return user;
  }
}

