import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/core/theme/app_theme.dart';

import 'support/test_environment.dart';

void main() {
  setUpAll(TestEnvironment.ensureLoaded);
  test('dob month-name format roundtrip', () {
    // Mobile display format: `15-october-2026` (D-MMMM-YYYY, lowercase).
    expect(Fmt.dobInput('1995-06-01'), '1-june-1995');
    expect(Fmt.dobInput('2001-10-09'), '9-october-2001');
    expect(Fmt.dobInput('01/06/2026'), '1-june-2026');
    expect(Fmt.dobInput('01/June/1995'), '1-june-1995');
    expect(Fmt.dobInput(null), '');
    expect(Fmt.date('01/06/2026'), '01/June/2026');
    expect(Fmt.date('1995-06-01'), '01/June/1995');
    expect(Fmt.dobToIso('1-june-1995'), '1995-06-01');
    expect(Fmt.dobToIso('9-october-2001'), '2001-10-09');
    expect(Fmt.dobToIso('15-october-2026'), '2026-10-15');
    expect(Fmt.dobToIso('9/6/1995'), '1995-06-09');
    expect(Fmt.dobToIso('1995-06-01'), '1995-06-01');
    expect(Fmt.dobToIso(''), '');
    expect(Fmt.dobToIso('junk'), 'junk');
  });
}
