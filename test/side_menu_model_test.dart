import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/models/side_menu/side_menu_model.dart';

void main() {
  group('SideMenuModel & SideMenuItemModel Tests', () {
    test('parses json with string taskId correctly', () {
      final json = {
        'status': true,
        'message': 'Success',
        'data': [
          {
            'title': 'Appointments',
            'taskCode': '3',
            'taskId': '3',
            'ImagePath': '/icons/app.png',
          },
          {
            'title': 'Patients',
            'taskCode': '4',
            'taskId': 4,
            'imagePath': '/icons/pat.png',
          },
        ]
      };

      final model = SideMenuModel.fromJson(json);
      expect(model.status, true);
      expect(model.message, 'Success');
      expect(model.data.length, 2);
      expect(model.data[0].taskId, 3);
      expect(model.data[0].title, 'Appointments');
      expect(model.data[0].imagePath, '/icons/app.png');
      expect(model.data[1].taskId, 4);
      expect(model.data[1].imagePath, '/icons/pat.png');
    });

    test('handles null and empty data gracefully', () {
      final json = {
        'status': true,
        'message': 'Empty',
        'data': null,
      };

      final model = SideMenuModel.fromJson(json);
      expect(model.status, true);
      expect(model.data, isEmpty);
    });
  });
}
