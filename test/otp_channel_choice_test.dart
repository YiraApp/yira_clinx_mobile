// Numbers outside India get a WhatsApp / SMS choice for the login code; +91 does not.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/widgets/otp_channel_choice.dart';

Widget _host(String code, String channel, ValueChanged<String> onChanged) => MaterialApp(
      home: Scaffold(body: OtpChannelChoice(countryCode: code, channel: channel, onChanged: onChanged)),
    );

void main() {
  testWidgets('hidden for Indian numbers', (tester) async {
    await tester.pumpWidget(_host('+91', LoginBloc.otpChannelWhatsApp, (_) {}));
    expect(find.text('WhatsApp'), findsNothing);
    expect(find.text('Get the code on'), findsNothing);
  });

  testWidgets('shown for other countries and reports the tapped option', (tester) async {
    String? picked;
    await tester.pumpWidget(_host('+971', LoginBloc.otpChannelWhatsApp, (c) => picked = c));
    expect(find.text('Get the code on'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    await tester.tap(find.text('SMS'));
    expect(picked, LoginBloc.otpChannelSms);
  });

  test('only non-Indian numbers ask the server for a channel', () {
    expect(LoginBloc.isIndianCode('+91'), isTrue);
    expect(LoginBloc.isIndianCode('91'), isTrue);
    expect(LoginBloc.isIndianCode('+1'), isFalse);
  });
}
