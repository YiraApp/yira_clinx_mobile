
import 'package:flutter/material.dart';

import '../../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/common_widgets/common_text.dart';
import '../../../../../core/constants/constants.dart';

class DashBoardPatientContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const DashBoardPatientContactRow({
    super.key,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 18),
        const SizedBox(width: 14),
        Expanded(
          child: CommonText(
            value,
            style:  TextStyle(fontFamily: appPoppinFont,
              fontWeight: FontWeight.w500,
              fontSize: displayWidth(context)*0.032,),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}