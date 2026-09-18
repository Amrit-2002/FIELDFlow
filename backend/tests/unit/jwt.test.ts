import { generateTokens, verifyAccessToken, verifyRefreshToken } from '../../src/utils/jwt';
import { AppError } from '../../src/utils/app-error';

describe('JWT Utilities Unit Tests', () => {
  const payload = {
    userId: 'user-uuid-1234',
    email: 'technician@fieldflow.dev',
    role: 'FIELD_WORKER',
  };

  it('should generate valid access and refresh tokens', () => {
    const tokens = generateTokens(payload);
    expect(tokens).toHaveProperty('accessToken');
    expect(tokens).toHaveProperty('refreshToken');
    expect(typeof tokens.accessToken).toBe('string');
    expect(typeof tokens.refreshToken).toBe('string');
  });

  it('should verify and decode valid access token', () => {
    const tokens = generateTokens(payload);
    const decoded = verifyAccessToken(tokens.accessToken);
    expect(decoded.userId).toBe(payload.userId);
    expect(decoded.email).toBe(payload.email);
    expect(decoded.role).toBe(payload.role);
  });

  it('should verify and decode valid refresh token', () => {
    const tokens = generateTokens(payload);
    const decoded = verifyRefreshToken(tokens.refreshToken);
    expect(decoded.userId).toBe(payload.userId);
  });

  it('should throw AppError.unauthorized when token is invalid or tampered', () => {
    expect(() => verifyAccessToken('invalid.jwt.token')).toThrow(AppError);
    try {
      verifyAccessToken('invalid.jwt.token');
    } catch (err: any) {
      expect(err.statusCode).toBe(401);
      expect(err.code).toBe('INVALID_TOKEN');
    }
  });
});

