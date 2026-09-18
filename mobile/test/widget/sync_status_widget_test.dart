import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_flow/core/widgets/network_status_bar.dart';

void main() {
  testWidgets('NetworkStatusBar renders online state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NetworkStatusBar(status: NetworkStatus.online),
        ),
      ),
    );

    expect(find.text('All changes synced'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('NetworkStatusBar renders offline state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NetworkStatusBar(status: NetworkStatus.offline),
        ),
      ),
    );

    expect(find.text('Offline mode — local changes will sync'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });

  testWidgets('NetworkStatusBar renders syncing state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NetworkStatusBar(status: NetworkStatus.syncing),
        ),
      ),
    );

    expect(find.text('Back online — syncing changes...'), findsOneWidget);
    expect(find.byIcon(Icons.sync), findsOneWidget);
  });
}

