import { Response } from 'express';

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  hasNext: boolean;
}

export const sendSuccess = <T>(res: Response, data: T, message: string = 'Success', statusCode: number = 200): Response => {
  const response: ApiResponse<T> = {
    success: true,
    data,
    message,
  };
  return res.status(statusCode).json(response);
};

export const sendPaginated = <T>(
  res: Response,
  items: T[],
  page: number,
  limit: number,
  total: number,
  message: string = 'Success'
): Response => {
  const totalPages = Math.ceil(total / limit);
  const hasNext = page < totalPages;

  const response: ApiResponse<{
    items: T[];
    page: number;
    limit: number;
    total: number;
    hasNext: boolean;
  }> = {
    success: true,
    data: {
      items,
      page,
      limit,
      total,
      hasNext,
    },
    message,
  };

  return res.status(200).json(response);
};

export const sendError = (
  res: Response,
  statusCode: number,
  code: string,
  message: string,
  details?: any
): Response => {
  const response: ApiResponse = {
    success: false,
    error: {
      code,
      message,
      ...(details ? { details } : {}),
    },
  };
  return res.status(statusCode).json(response);
};

