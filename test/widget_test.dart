import 'package:f_o_l_k_auto_dialer/pages/login/login_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginWidget(),
      ),
    );

    expect(find.text('FOLK Auto Dialer'), findsOneWidget);
    expect(find.text('SEND OTP'), findsOneWidget);
  });
}
