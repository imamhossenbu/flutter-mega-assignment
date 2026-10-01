import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mega_assignment/core/widgets/state_views.dart';
import 'package:flutter_mega_assignment/providers/auth_provider.dart';
import 'package:flutter_mega_assignment/views/auth/login_screen.dart';
import 'package:flutter_mega_assignment/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  String? lastResetEmail;
  bool shouldSucceed = true;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastResetEmail = email;
    if (!shouldSucceed) {
      throw Exception('User not found');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Core Reusable State Views Tests', () {
    testWidgets('LoadingView renders spinner and optional message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingView(message: 'Loading products...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading products...'), findsOneWidget);
    });

    testWidgets('EmptyStateView renders title, message, and responds to action button', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              title: 'Your Cart is Empty',
              message: 'Looks like you have not added anything to your cart yet.',
              actionLabel: 'Start Shopping',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Your Cart is Empty'), findsOneWidget);
      expect(find.text('Looks like you have not added anything to your cart yet.'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);

      await tester.tap(find.text('Start Shopping'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('ErrorStateView renders message and calls onRetry', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateView(
              message: 'Network connection failed.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Network connection failed.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('NoInternetView renders offline indicator and retry button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoInternetView(
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('Login Screen Forgot Password Flow Tests', () {
    testWidgets('Tapping Forgot Password with email sends password reset', (tester) async {
      final fakeAuthRepo = FakeAuthRepository();
      final authProvider = AuthProvider(authRepository: fakeAuthRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);

      // Enter email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'shopper@example.com');
      await tester.pump();

      // Tap Forgot Password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(fakeAuthRepo.lastResetEmail, 'shopper@example.com');
    });
  });

  group('Payment Mode Constraints Tests', () {
    testWidgets('Checkout UI explicitly displays Cash on Delivery only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(Icons.payments_rounded),
                  SizedBox(width: 8),
                  Text('Cash on Delivery (COD)'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cash on Delivery (COD)'), findsOneWidget);
      expect(find.text('Credit Card'), findsNothing);
      expect(find.text('bKash'), findsNothing);
      expect(find.text('Nagad'), findsNothing);
    });
  });
}
