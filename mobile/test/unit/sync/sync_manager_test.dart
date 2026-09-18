import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_flow/core/database/app_database.dart';
import 'package:field_flow/core/network/api_client.dart';
import 'package:field_flow/core/network/network_info.dart';
import 'package:field_flow/features/sync/data/datasources/sync_manager.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockApiClient extends Mock implements ApiClient {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late SyncManager syncManager;
  late MockAppDatabase mockDb;
  late MockApiClient mockApiClient;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockDb = MockAppDatabase();
    mockApiClient = MockApiClient();
    mockNetworkInfo = MockNetworkInfo();

    when(() => mockNetworkInfo.onConnectivityChanged).thenAnswer((_) => const Stream.empty());

    syncManager = SyncManager(
      db: mockDb,
      apiClient: mockApiClient,
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() {
    syncManager.dispose();
  });

  group('SyncManager Exponential Backoff Calculations', () {
    test('calculateBackoff calculates 2^retryCount exponential backoff correctly', () {
      expect(syncManager.calculateBackoff(0), const Duration(seconds: 1));
      expect(syncManager.calculateBackoff(1), const Duration(seconds: 2));
      expect(syncManager.calculateBackoff(2), const Duration(seconds: 4));
      expect(syncManager.calculateBackoff(3), const Duration(seconds: 8));
      expect(syncManager.calculateBackoff(4), const Duration(seconds: 16));
    });

    test('calculateBackoff caps retry delay at 16 seconds for higher retry counts', () {
      expect(syncManager.calculateBackoff(5), const Duration(seconds: 16));
      expect(syncManager.calculateBackoff(10), const Duration(seconds: 16));
    });
  });
}

