enum ErrorCode { validationError, unauthorized, forbidden, notFound, conflict, internalError }

String errorCodeToString(ErrorCode code) {
  switch (code) {
    case ErrorCode.validationError:
      return 'VALIDATION_ERROR';
    case ErrorCode.unauthorized:
      return 'UNAUTHORIZED';
    case ErrorCode.forbidden:
      return 'FORBIDDEN';
    case ErrorCode.notFound:
      return 'NOT_FOUND';
    case ErrorCode.conflict:
      return 'CONFLICT';
    case ErrorCode.internalError:
      return 'INTERNAL_ERROR';
  }
}
