function sendValidationError(res, error) {
  return res.status(400).json({
    success: false,
    error,
  });
}

function isPlainObject(value) {
  return value != null && typeof value === 'object' && !Array.isArray(value);
}

function validateAgainstSchema(source, schema) {
  for (const [field, rules] of Object.entries(schema)) {
    const value = source[field];
    const hasValue = value !== undefined && value !== null && value !== '';

    if (rules.required && !hasValue) {
      return `${field} is required.`;
    }

    if (!hasValue) {
      continue;
    }

    if (rules.type === 'string') {
      if (typeof value !== 'string') {
        return `${field} must be a string.`;
      }
      const trimmed = value.trim();
      if (rules.minLength && trimmed.length < rules.minLength) {
        return `${field} must be at least ${rules.minLength} characters.`;
      }
      if (rules.maxLength && trimmed.length > rules.maxLength) {
        return `${field} must be at most ${rules.maxLength} characters.`;
      }
      if (rules.enum && !rules.enum.includes(trimmed)) {
        return `${field} must be one of: ${rules.enum.join(', ')}.`;
      }
      if (rules.pattern && !rules.pattern.test(trimmed)) {
        return `${field} format is invalid.`;
      }
    }

    if (rules.type === 'number') {
      const numeric = Number(value);
      if (!Number.isFinite(numeric)) {
        return `${field} must be a valid number.`;
      }
      if (rules.integer && !Number.isInteger(numeric)) {
        return `${field} must be an integer.`;
      }
      if (rules.min != null && numeric < rules.min) {
        return `${field} must be greater than or equal to ${rules.min}.`;
      }
      if (rules.max != null && numeric > rules.max) {
        return `${field} must be less than or equal to ${rules.max}.`;
      }
    }

    if (rules.type === 'boolean' && typeof value !== 'boolean') {
      return `${field} must be a boolean.`;
    }

    if (rules.type === 'object' && !isPlainObject(value)) {
      return `${field} must be an object.`;
    }

    if (rules.type === 'array') {
      if (!Array.isArray(value)) {
        return `${field} must be an array.`;
      }
      if (rules.minItems != null && value.length < rules.minItems) {
        return `${field} must contain at least ${rules.minItems} items.`;
      }
      if (rules.maxItems != null && value.length > rules.maxItems) {
        return `${field} must contain at most ${rules.maxItems} items.`;
      }
      if (rules.items === 'int') {
        const allInts = value.every((item) => Number.isInteger(Number(item)));
        if (!allInts) {
          return `${field} must contain only integers.`;
        }
      }
    }
  }

  return null;
}

function validateBody(schema) {
  return (req, res, next) => {
    const body = isPlainObject(req.body) ? req.body : {};
    const error = validateAgainstSchema(body, schema);
    if (error) {
      return sendValidationError(res, error);
    }
    return next();
  };
}

function validateQuery(schema) {
  return (req, res, next) => {
    const query = isPlainObject(req.query) ? req.query : {};
    const error = validateAgainstSchema(query, schema);
    if (error) {
      return sendValidationError(res, error);
    }
    return next();
  };
}

module.exports = {
  validateBody,
  validateQuery,
  isPlainObject,
};
