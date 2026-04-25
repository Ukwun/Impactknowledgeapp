import 'package:flutter_test/flutter_test.dart';
import 'package:impactknowledge_app/widgets/forms/app_forms.dart';

void main() {
  group('FormValidators', () {
    test('validateRequired enforces non-empty values', () {
      expect(FormValidators.validateRequired(''), 'This field is required');
      expect(FormValidators.validateRequired('value'), isNull);
    });

    test('validateMinLength enforces minimum length', () {
      expect(
        FormValidators.validateMinLength('short', 10),
        'Must be at least 10 characters',
      );
      expect(FormValidators.validateMinLength('long enough', 5), isNull);
    });

    test('validateEmail accepts valid email and rejects invalid', () {
      expect(FormValidators.validateEmail('invalid'), 'Invalid email format');
      expect(FormValidators.validateEmail('user@example.com'), isNull);
    });

    test('validateUrl accepts http/https URLs only', () {
      expect(FormValidators.validateUrl('ftp://bad.url'), 'Invalid URL format');
      expect(FormValidators.validateUrl('https://impactknowledge.app'), isNull);
    });
  });
}
