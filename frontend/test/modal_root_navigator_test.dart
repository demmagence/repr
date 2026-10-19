import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repr/app.dart';
import 'package:repr/ui/material/app_ui.dart';
import 'package:repr/ui/widgets/kinetic_components.dart';

void main() {
  testWidgets(
    'showAppActionSheet dan modal dibuka pada root navigator di atas bottom navigation bar',
    (tester) async {
      String? selectedAction;

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => AppShell(shell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/test',
                    builder: (context, _) => Scaffold(
                      body: Center(
                        child: ElevatedButton(
                          key: const Key('open-actions-btn'),
                          onPressed: () async {
                            selectedAction = await showAppActionSheet<String>(
                              context: context,
                              title: 'upper',
                              actions: const [
                                AppAction(
                                  value: 'start',
                                  label: 'Start Routine',
                                ),
                                AppAction(
                                  value: 'edit',
                                  label: 'Edit Routine',
                                ),
                                AppAction(
                                  value: 'delete',
                                  label: 'Hapus Routine',
                                ),
                              ],
                            );
                          },
                          child: const Text('Buka Pilihan'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // KineticBottomNav is present
      expect(find.byType(KineticBottomNav), findsOneWidget);

      // Open the action sheet
      await tester.tap(find.byKey(const Key('open-actions-btn')));
      await tester.pumpAndSettle();

      // Action sheet items are visible on the root layer
      expect(find.text('upper'), findsOneWidget);
      expect(find.text('Start Routine'), findsOneWidget);
      expect(find.text('Edit Routine'), findsOneWidget);
      expect(find.text('Hapus Routine'), findsOneWidget);

      // Tap "Start Routine"
      await tester.tap(find.text('Start Routine'));
      await tester.pumpAndSettle();

      expect(selectedAction, 'start');
      expect(find.text('Start Routine'), findsNothing);
    },
  );
}
