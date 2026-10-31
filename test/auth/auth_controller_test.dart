import 'package:alessio_test_task/auth/auth_controller.dart';
import 'package:alessio_test_task/auth/auth_repository.dart';
import 'package:alessio_test_task/auth/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const user = User(
  id: 1,
  firstName: 'Emily',
  lastName: 'Johnson',
  email: 'emily@example.com',
  image: null,
);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockAuthRepository repository;
  late ProviderContainer container;

  AuthState read() => container.read(authControllerProvider);
  AuthController controller() =>
      container.read(authControllerProvider.notifier);

  Future<void> start() async {
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    )..listen(authControllerProvider, (_, _) {});
    await settle();
  }

  setUp(() => repository = MockAuthRepository());

  tearDown(() => container.dispose());

  test('no stored session starts signed out', () async {
    when(() => repository.restore()).thenAnswer((_) async => null);

    await start();

    expect(read(), isA<SignedOut>());
  });

  test('valid stored session starts signed in', () async {
    when(() => repository.restore()).thenAnswer((_) async => user);

    await start();

    expect(read(), isA<SignedIn>());
  });

  test('storage failure on start does not leave the app loading', () async {
    when(
      () => repository.restore(),
    ).thenAnswer((_) => Future.error(StateError('keystore')));

    await start();

    expect(read(), isA<SignedOut>());
  });

  test('signIn, signOut and expire update the state', () async {
    when(() => repository.restore()).thenAnswer((_) async => null);
    when(
      () => repository.signIn('emilys', 'emilyspass'),
    ).thenAnswer((_) async => user);
    when(() => repository.signOut()).thenAnswer((_) async {});
    await start();

    await controller().signIn('emilys', 'emilyspass');
    expect(read(), isA<SignedIn>());

    await controller().signOut();
    expect(read(), isA<SignedOut>());

    await controller().signIn('emilys', 'emilyspass');
    controller().expire();
    expect(read(), isA<SignedOut>());
  });
}
