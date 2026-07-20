


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../common_size_helpers/common_size_helpers.dart';


 Future<void> showDateSelectionSheet({
  required BuildContext context,
  required DateTime initialDate,
  required Function(DateTime) onDateConfirmed,
}) async {
  DateTime tempDate = initialDate;

  await showModalBottomSheet(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
    ),
    context: context,
    isDismissible: true,
    builder: (BuildContext context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height / 3,
        child: Column(
          children: [
            _buildHeader(context, onDone: () {
              onDateConfirmed(tempDate);
              Navigator.pop(context);
            }),
            Container(width: displayWidth(context),height: 0.5,color: Colors.grey,),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: initialDate,
                dateOrder: DatePickerDateOrder.dmy,
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (DateTime dateTime) => tempDate = dateTime,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildHeader(BuildContext context, {required VoidCallback onDone}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoButton(
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    ),
  );
}