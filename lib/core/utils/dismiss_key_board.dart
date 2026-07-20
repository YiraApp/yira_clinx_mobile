import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension UIContextExtensions on BuildContext {
  void dismissKeyboard() {
    final FocusScopeNode currentFocus = FocusScope.of(this);

    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    if (kIsWeb) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }
}
