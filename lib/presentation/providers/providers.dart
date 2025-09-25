// lib/presentation/providers/providers.dart
import 'package:firebase_remote_config/firebase_remote_config.dart'; // <<< ADICIONE ESTE
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart'; // <<< ADICIONE ESTE
import 'package:superlistas/core/database/database_helper.dart';
import 'package:superlistas/data/datasources/firebase_auth_service.dart';
import 'package:superlistas/data/datasources/local_datasource.dart';
import 'package:superlistas/data/datasources/remote_config_service.dart'; // <<< ADICIONE ESTE
import 'package:superlistas/data/repositories/firebase_auth_repository_impl.dart';
import 'package:superlistas/data/repositories/shopping_list_repository_impl.dart';
import 'package:superlistas/domain/entities/category.dart';
import 'package:superlistas/domain/entities/dashboard_data.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/entities/stats_data.dart';
import 'package:superlistas/domain/entities/user.dart';
import 'package:superlistas/domain/repositories/auth_repository.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';
import 'package:superlistas/presentation/viewmodels/auth_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/background_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/categories_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/history_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/list_items_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/password_recovery_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/shopping_lists_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/stats_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/theme_viewmodel.dart';
import 'package:superlistas/presentation/viewmodels/units_viewmodel.dart';

final mainScreenIndexProvider = StateProvider<int>((ref) => 0);

final themeModeProvider =
StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// --- SEÇÃO DE AUTENTICAÇÃO COM FIREBASE ---
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuthService = ref.watch(firebaseAuthServiceProvider);
  return FirebaseAuthRepositoryImpl(firebaseAuthService);
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthViewModel(authRepository);
});

// --- SEÇÃO DE DADOS LOCAIS (SQFLITE) ---
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return LocalDataSourceImpl(databaseHelper: dbHelper);
});

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  final localDataSource = ref.watch(localDataSourceProvider);
  return ShoppingListRepositoryImpl(localDataSource: localDataSource);
});

// --- SEÇÃO DE VIEWMODELS E PROVIDERS DA UI ---
final singleListProvider =
FutureProvider.autoDispose.family<ShoppingList, String>((ref, id) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.getShoppingListById(id);
});

final dashboardViewModelProvider = StateNotifierProvider.autoDispose
    .family<DashboardViewModel, AsyncValue<DashboardData>, String>((ref, userId) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return DashboardViewModel(repository, userId);
});

final shoppingListsViewModelProvider = StateNotifierProvider.autoDispose.family<
    ShoppingListsViewModel, AsyncValue<List<ShoppingList>>, String>((ref, userId) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return ShoppingListsViewModel(repository, userId);
});

final listItemsViewModelProvider = StateNotifierProvider.autoDispose
    .family<ListItemsViewModel, AsyncValue<List<Item>>, String>(
        (ref, shoppingListId) {
      final repository = ref.watch(shoppingListRepositoryProvider);
      return ListItemsViewModel(ref, repository, shoppingListId);
    });

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.getCategories();
});

final categoriesViewModelProvider = StateNotifierProvider.autoDispose<
    CategoriesViewModel, AsyncValue<List<Category>>>((ref) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return CategoriesViewModel(repository);
});

final historyViewModelProvider = StateNotifierProvider.autoDispose
    .family<HistoryViewModel, AsyncValue<List<ShoppingList>>, String>(
        (ref, userId) {
      final repository = ref.watch(shoppingListRepositoryProvider);
      return HistoryViewModel(repository, userId);
    });

final statsViewModelProvider = StateNotifierProvider.autoDispose
    .family<StatsViewModel, AsyncValue<StatsData>, String>((ref, userId) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return StatsViewModel(repository, userId);
});

final passwordRecoveryViewModelProvider =
StateNotifierProvider.autoDispose<PasswordRecoveryViewModel, AsyncValue<void>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return PasswordRecoveryViewModel(authRepository);
});

final unitsViewModelProvider =
StateNotifierProvider.autoDispose<UnitsViewModel, AsyncValue<List<String>>>(
        (ref) {
      final repository = ref.watch(shoppingListRepositoryProvider);
      return UnitsViewModel(repository);
    });

// --- SEÇÃO DE TEMA E UI ---
final backgroundProvider =
StateNotifierProvider<BackgroundNotifier, String>((ref) {
  return BackgroundNotifier();
});

// <<< NOVOS PROVIDERS ADICIONADOS AQUI >>>
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService(FirebaseRemoteConfig.instance);
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});