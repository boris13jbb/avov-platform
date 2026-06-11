import 'package:flutter_test/flutter_test.dart';

import 'package:avov_frontend/features/institution_reports/data/datasources/export_remote_datasource.dart';

void main() {
  test('ExportFile almacena bytes y nombre', () {
    const file = ExportFile(
      bytes: [65, 66, 67],
      fileName: 'estudiantes.csv',
    );

    expect(file.bytes, [65, 66, 67]);
    expect(file.fileName, 'estudiantes.csv');
  });
}
