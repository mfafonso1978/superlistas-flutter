// lib/data/datasources/remote_config_service.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  final _defaults = <String, dynamic>{
    // Versioning
    'min_supported_version_code': 1,
    'latest_version_code': 1,
    'latest_version_name': '1.0.0',
    'update_url': 'https://github.com/mfafonso1978/superlistas-flutter/releases',
    'release_notes': 'Correções de bugs gerais.',

    // Feature Flags Completas
    'screen_dashboard_enabled': true,
    'dashboard_metrics_enabled': true,
    'dashboard_quick_actions_enabled': true,
    'dashboard_recent_lists_enabled': true,
    'dashboard_pull_to_refresh_enabled': true,
    'screen_shopping_lists_enabled': true,
    'action_add_list_enabled': true,
    'action_edit_list_enabled': true,
    'action_delete_list_enabled': true,
    'action_archive_list_enabled': true,
    'shopping_lists_pull_to_refresh_enabled': true,
    'screen_list_items_enabled': true, // Assumindo que a tela de itens pode ser controlada
    'action_add_item_enabled': true,
    'action_edit_item_enabled': true,
    'action_delete_item_enabled': true,
    'action_check_item_enabled': true,
    'feature_financial_summary_bar_enabled': true,
    'screen_list_analysis_enabled': true,
    'screen_history_enabled': true,
    'history_view_items_enabled': true,
    'action_reuse_list_enabled': true,
    'action_delete_history_list_enabled': true,
    'history_pull_to_refresh_enabled': true,
    'screen_stats_enabled': true,
    'stats_metrics_card_enabled': true,
    'stats_bar_chart_enabled': true,
    'stats_pie_chart_enabled': true,
    'stats_pull_to_refresh_enabled': true,
    'screen_categories_enabled': true,
    'action_add_category_enabled': true,
    'action_edit_category_enabled': true,
    'action_delete_category_enabled': true,
    'categories_pull_to_refresh_enabled': true,
    'screen_settings_enabled': true,
    'screen_units_enabled': true,
    'feature_theme_toggle_enabled': true,
    'feature_background_select_enabled': true,
    'feature_import_export_enabled': true,
    'action_duplicate_list_enabled': true, // Adicionado dos mapeamentos anteriores
    'feature_templates_enabled': true, // Adicionado dos mapeamentos anteriores
    'premium_stats_enabled': false,
  };

  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(_defaults);
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao inicializar o Remote Config: $e');
      }
    }
  }

  // Versioning
  int get minSupportedVersionCode => _remoteConfig.getInt('min_supported_version_code');
  int get latestVersionCode => _remoteConfig.getInt('latest_version_code');
  String get latestVersionName => _remoteConfig.getString('latest_version_name');
  String get updateUrl => _remoteConfig.getString('update_url');
  String get releaseNotes => _remoteConfig.getString('release_notes');

  // Premium
  bool get isPremiumStatsEnabled => _remoteConfig.getBool('premium_stats_enabled');

  // Screens
  bool get isDashboardScreenEnabled => _remoteConfig.getBool('screen_dashboard_enabled');
  bool get isShoppingListsScreenEnabled => _remoteConfig.getBool('screen_shopping_lists_enabled');
  bool get isHistoryScreenEnabled => _remoteConfig.getBool('screen_history_enabled');
  bool get isStatsScreenEnabled => _remoteConfig.getBool('screen_stats_enabled');
  bool get isCategoriesScreenEnabled => _remoteConfig.getBool('screen_categories_enabled');
  bool get isSettingsScreenEnabled => _remoteConfig.getBool('screen_settings_enabled');
  bool get isUnitsScreenEnabled => _remoteConfig.getBool('screen_units_enabled');
  bool get isListAnalysisScreenEnabled => _remoteConfig.getBool('screen_list_analysis_enabled');

  // Dashboard Features
  bool get isDashboardMetricsEnabled => _remoteConfig.getBool('dashboard_metrics_enabled');
  bool get isDashboardQuickActionsEnabled => _remoteConfig.getBool('dashboard_quick_actions_enabled');
  bool get isDashboardRecentListsEnabled => _remoteConfig.getBool('dashboard_recent_lists_enabled');
  bool get isDashboardPullToRefreshEnabled => _remoteConfig.getBool('dashboard_pull_to_refresh_enabled');

  // Shopping Lists Features & Actions
  bool get isAddListEnabled => _remoteConfig.getBool('action_add_list_enabled');
  bool get isEditListEnabled => _remoteConfig.getBool('action_edit_list_enabled');
  bool get isDeleteListEnabled => _remoteConfig.getBool('action_delete_list_enabled');
  bool get isArchiveListEnabled => _remoteConfig.getBool('action_archive_list_enabled');
  bool get isDuplicateListEnabled => _remoteConfig.getBool('action_duplicate_list_enabled');
  bool get isShoppingListsPullToRefreshEnabled => _remoteConfig.getBool('shopping_lists_pull_to_refresh_enabled');

  // List Items Features & Actions
  bool get isAddItemEnabled => _remoteConfig.getBool('action_add_item_enabled');
  bool get isEditItemEnabled => _remoteConfig.getBool('action_edit_item_enabled');
  bool get isDeleteItemEnabled => _remoteConfig.getBool('action_delete_item_enabled');
  bool get isCheckItemEnabled => _remoteConfig.getBool('action_check_item_enabled');
  bool get isFinancialSummaryBarEnabled => _remoteConfig.getBool('feature_financial_summary_bar_enabled');

  // History Features & Actions
  bool get isHistoryViewItemsEnabled => _remoteConfig.getBool('history_view_items_enabled');
  bool get isReuseListEnabled => _remoteConfig.getBool('action_reuse_list_enabled');
  bool get isDeleteHistoryListEnabled => _remoteConfig.getBool('action_delete_history_list_enabled');
  bool get isHistoryPullToRefreshEnabled => _remoteConfig.getBool('history_pull_to_refresh_enabled');

  // Stats Features
  bool get isStatsMetricsCardEnabled => _remoteConfig.getBool('stats_metrics_card_enabled');
  bool get isStatsBarChartEnabled => _remoteConfig.getBool('stats_bar_chart_enabled');
  bool get isStatsPieChartEnabled => _remoteConfig.getBool('stats_pie_chart_enabled');
  bool get isStatsPullToRefreshEnabled => _remoteConfig.getBool('stats_pull_to_refresh_enabled');

  // Categories Features & Actions
  bool get isAddCategoryEnabled => _remoteConfig.getBool('action_add_category_enabled');
  bool get isEditCategoryEnabled => _remoteConfig.getBool('action_edit_category_enabled');
  bool get isDeleteCategoryEnabled => _remoteConfig.getBool('action_delete_category_enabled');
  bool get isCategoriesPullToRefreshEnabled => _remoteConfig.getBool('categories_pull_to_refresh_enabled');

  // Settings Features
  bool get isThemeToggleEnabled => _remoteConfig.getBool('feature_theme_toggle_enabled');
  bool get isBackgroundSelectEnabled => _remoteConfig.getBool('feature_background_select_enabled');
  bool get isImportExportEnabled => _remoteConfig.getBool('feature_import_export_enabled');
  bool get isTemplatesEnabled => _remoteConfig.getBool('feature_templates_enabled');

  // Units Features & Actions (assumindo que a tela de unidades pode ser controlada)
  bool get isAddUnitEnabled => _remoteConfig.getBool('action_add_unit_enabled');
  bool get isEditUnitEnabled => _remoteConfig.getBool('action_edit_unit_enabled');
  bool get isDeleteUnitEnabled => _remoteConfig.getBool('action_delete_unit_enabled');
}