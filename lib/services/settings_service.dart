import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_service.dart';

/// APP CONFIGURATION MODEL
/// This data class defines every setting a user can change.
/// It also includes 'projectRoot' which is for the developer-only Desktop mode.

class AppSettings {
  final ThemeMode themeMode;
  final double voiceRate;
  final double voicePitch;
  final double voiceVolume;
  final String voiceLanguage;
  final String voiceName;
  final String sentenceSize; // small, medium, large
  final String sentenceType; // words, symbols, both
  final bool readSentenceOnly;
  final String profileImage;
  final String fontSize; // small, medium, large
  final bool highContrast;
  final String projectRoot; // Desktop only: path to project source
  final String colourTheme;  // teal | blue | purple | green | orange | rose | mono
  final double symbolSize;   // 0.6 – 1.6  (multiplier on base tile size)
  final double gridSpacing;  // 4 – 24 dp

  // ── Accessibility
  final bool reduceMotion;
  final bool boldText;
  final bool largerTouchTargets;
  final bool speakOnTap;
  final double buttonSpacing;

  // ── Language / Locale
  final String appLanguage;
  final bool showSymbolLabels;
  final String labelPosition;

  // ── Privacy
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
  final bool saveHistory;
  final int historyRetentionDays;

  // ── Cloud Sync
  final bool cloudSyncEnabled;
  final bool syncOnWifiOnly;
  final bool autoSyncOnLaunch;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.voiceRate = 0.80,
    this.voicePitch = 0.90,
    this.voiceVolume = 1.0,
    this.voiceLanguage = 'en-GB',
    this.voiceName = 'Google UK English Female',
    this.sentenceSize = 'medium',
    this.sentenceType = 'both',
    this.readSentenceOnly = false,
    this.profileImage = '',
    this.fontSize = 'medium',
    this.highContrast = false,
    this.projectRoot = '',
    this.colourTheme = 'teal',
    this.symbolSize = 1.0,
    this.gridSpacing = 10.0,
    this.reduceMotion = false,
    this.boldText = false,
    this.largerTouchTargets = false,
    this.speakOnTap = true,
    this.buttonSpacing = 1.0,
    this.appLanguage = 'en-GB',
    this.showSymbolLabels = true,
    this.labelPosition = 'below',
    this.analyticsEnabled = true,
    this.crashReportingEnabled = true,
    this.saveHistory = true,
    this.historyRetentionDays = 30,
    this.cloudSyncEnabled = false,
    this.syncOnWifiOnly = true,
    this.autoSyncOnLaunch = true,
  });

  /// COPY WITH
  /// Helper function to change just ONE setting while keeping others the same.
  ///
  AppSettings copyWith({
    ThemeMode? themeMode,
    double? voiceRate,
    double? voicePitch,
    double? voiceVolume,
    String? voiceLanguage,
    String? voiceName,
    String? sentenceSize,
    String? sentenceType,
    bool? readSentenceOnly,
    String? profileImage,
    String? fontSize,
    bool? highContrast,
    String? projectRoot,
    String? colourTheme,
    double? symbolSize,
    double? gridSpacing,
    bool? reduceMotion,
    bool? boldText,
    bool? largerTouchTargets,
    bool? speakOnTap,
    double? buttonSpacing,
    String? appLanguage,
    bool? showSymbolLabels,
    String? labelPosition,
    bool? analyticsEnabled,
    bool? crashReportingEnabled,
    bool? saveHistory,
    int? historyRetentionDays,
    bool? cloudSyncEnabled,
    bool? syncOnWifiOnly,
    bool? autoSyncOnLaunch,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      voiceRate: voiceRate ?? this.voiceRate,
      voicePitch: voicePitch ?? this.voicePitch,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      voiceName: voiceName ?? this.voiceName,
      sentenceSize: sentenceSize ?? this.sentenceSize,
      sentenceType: sentenceType ?? this.sentenceType,
      readSentenceOnly: readSentenceOnly ?? this.readSentenceOnly,
      profileImage: profileImage ?? this.profileImage,
      fontSize: fontSize ?? this.fontSize,
      highContrast: highContrast ?? this.highContrast,
      projectRoot: projectRoot ?? this.projectRoot,
      colourTheme: colourTheme ?? this.colourTheme,
      symbolSize: symbolSize ?? this.symbolSize,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      boldText: boldText ?? this.boldText,
      largerTouchTargets: largerTouchTargets ?? this.largerTouchTargets,
      speakOnTap: speakOnTap ?? this.speakOnTap,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      appLanguage: appLanguage ?? this.appLanguage,
      showSymbolLabels: showSymbolLabels ?? this.showSymbolLabels,
      labelPosition: labelPosition ?? this.labelPosition,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashReportingEnabled: crashReportingEnabled ?? this.crashReportingEnabled,
      saveHistory: saveHistory ?? this.saveHistory,
      historyRetentionDays: historyRetentionDays ?? this.historyRetentionDays,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      autoSyncOnLaunch: autoSyncOnLaunch ?? this.autoSyncOnLaunch,
    );
  }

  /// SERIALIZATION
  /// Converts settings to a Map for saving to storage (JSON).
  ///
  Map<String, dynamic> toMap() => {
        'themeMode': themeModeToString(themeMode),
        'voiceRate': voiceRate,
        'voicePitch': voicePitch,
        'voiceVolume': voiceVolume,
        'voiceLanguage': voiceLanguage,
        'voiceName': voiceName,
        'sentenceSize': sentenceSize,
        'sentenceType': sentenceType,
        'readSentenceOnly': readSentenceOnly,
        'profileImage': profileImage,
        'fontSize': fontSize,
        'highContrast': highContrast,
        'projectRoot': projectRoot,
        'colourTheme': colourTheme,
        'symbolSize': symbolSize,
        'gridSpacing': gridSpacing,
        'reduceMotion': reduceMotion,
        'boldText': boldText,
        'largerTouchTargets': largerTouchTargets,
        'speakOnTap': speakOnTap,
        'buttonSpacing': buttonSpacing,
        'appLanguage': appLanguage,
        'showSymbolLabels': showSymbolLabels,
        'labelPosition': labelPosition,
        'analyticsEnabled': analyticsEnabled,
        'crashReportingEnabled': crashReportingEnabled,
        'saveHistory': saveHistory,
        'historyRetentionDays': historyRetentionDays,
        'cloudSyncEnabled': cloudSyncEnabled,
        'syncOnWifiOnly': syncOnWifiOnly,
        'autoSyncOnLaunch': autoSyncOnLaunch,
      };

  static String themeModeToString(ThemeMode mode) {
    if (mode == ThemeMode.light) return 'light';
    if (mode == ThemeMode.dark) return 'dark';
    return 'system';
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final themeValue = map['themeMode']?.toString() ?? 'system';
    final themeMode = themeValue == 'light'
        ? ThemeMode.light
        : themeValue == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    return AppSettings(
      themeMode: themeMode,
      voiceRate: (map['voiceRate'] is num)
          ? (map['voiceRate'] as num).toDouble()
          : 0.80,
      voicePitch: (map['voicePitch'] is num)
          ? (map['voicePitch'] as num).toDouble()
          : 1.0,
      voiceVolume: (map['voiceVolume'] is num)
          ? (map['voiceVolume'] as num).toDouble()
          : 1.0,
      voiceLanguage: map['voiceLanguage']?.toString() ?? 'en-GB',
      voiceName: map['voiceName']?.toString() ?? 'Google UK English Female',
      sentenceSize: map['sentenceSize']?.toString() ?? 'medium',
      sentenceType: map['sentenceType']?.toString() ?? 'both',
      readSentenceOnly: map['readSentenceOnly'] == true,
      profileImage: map['profileImage']?.toString() ?? '',
      fontSize: map['fontSize']?.toString() ?? 'medium',
      highContrast: map['highContrast'] == true,
      projectRoot: map['projectRoot']?.toString() ?? '',
      colourTheme: map['colourTheme']?.toString() ?? 'teal',
      symbolSize: (map['symbolSize'] is num) ? (map['symbolSize'] as num).toDouble() : 1.0,
      gridSpacing: (map['gridSpacing'] is num) ? (map['gridSpacing'] as num).toDouble() : 10.0,
      reduceMotion: map['reduceMotion'] == true,
      boldText: map['boldText'] == true,
      largerTouchTargets: map['largerTouchTargets'] == true,
      speakOnTap: map['speakOnTap'] != false,
      buttonSpacing: (map['buttonSpacing'] is num) ? (map['buttonSpacing'] as num).toDouble() : 1.0,
      appLanguage: map['appLanguage']?.toString() ?? 'en-GB',
      showSymbolLabels: map['showSymbolLabels'] != false,
      labelPosition: map['labelPosition']?.toString() ?? 'below',
      analyticsEnabled: map['analyticsEnabled'] != false,
      crashReportingEnabled: map['crashReportingEnabled'] != false,
      saveHistory: map['saveHistory'] != false,
      historyRetentionDays: (map['historyRetentionDays'] is int) ? map['historyRetentionDays'] as int : 30,
      cloudSyncEnabled: map['cloudSyncEnabled'] == true,
      syncOnWifiOnly: map['syncOnWifiOnly'] != false,
      autoSyncOnLaunch: map['autoSyncOnLaunch'] != false,
    );
  }
}

/// CONFIGURATION SERVICE
/// This acts as the gatekeeper for reading and writing app settings. 
/// It interacts with SharedPreferences to ensure settings persist 
/// across app restarts.
///
class SettingsService {
  static const _themeKey = 'aac_theme_mode';
  static const _rateKey = 'aac_voice_rate';
  static const _pitchKey = 'aac_voice_pitch';
  static const _volumeKey = 'aac_voice_volume';
  static const _languageKey = 'aac_voice_language';
  static const _voiceNameKey = 'aac_voice_name';
  static const _sentenceSizeKey = 'aac_sentence_size';
  static const _sentenceTypeKey = 'aac_sentence_type';
  static const _readSentenceOnlyKey = 'aac_read_sentence_only';
  static const _profileImageKey = 'aac_profile_image';
  static const _fontSizeKey = 'aac_font_size';
  static const _highContrastKey = 'aac_high_contrast';
  static const _projectRootKey = 'aac_project_root';
  static const _tabOrderKey = 'aac_top_tab_order';
  static const _colourThemeKey = 'aac_colour_theme';
  static const _symbolSizeKey = 'aac_symbol_size';
  static const _gridSpacingKey = 'aac_grid_spacing';
  static const _reduceMotionKey = 'aac_reduce_motion';
  static const _boldTextKey = 'aac_bold_text';
  static const _largerTouchTargetsKey = 'aac_larger_touch';
  static const _speakOnTapKey = 'aac_speak_on_tap';
  static const _buttonSpacingKey = 'aac_button_spacing';
  static const _appLanguageKey = 'aac_app_language';
  static const _showSymbolLabelsKey = 'aac_show_labels';
  static const _labelPositionKey = 'aac_label_position';
  static const _analyticsKey = 'aac_analytics';
  static const _crashReportingKey = 'aac_crash_reporting';
  static const _saveHistoryKey = 'aac_save_history';
  static const _historyRetentionKey = 'aac_history_days';
  static const _cloudSyncEnabledKey = 'aac_cloud_sync';
  static const _syncWifiOnlyKey = 'aac_sync_wifi_only';
  static const _autoSyncOnLaunchKey = 'aac_auto_sync';
  static const _customColorsKey = 'aac_custom_colors';
  final SharedPreferences _prefs;

  SettingsService._(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs);
  }

  /// THE SETTINGS GETTER
  /// This builds a complete AppSettings object by pulling each 
  /// individual value from the device's storage.
  ///
  AppSettings get settings {
    final themeValue = _prefs.getString(_themeKey) ?? 'system';
    final themeMode = themeValue == 'light'
        ? ThemeMode.light
        : themeValue == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    final voiceRate = _prefs.getDouble(_rateKey) ?? 0.80;
    final voicePitch = _prefs.getDouble(_pitchKey) ?? 1.0;
    final voiceVolume = _prefs.getDouble(_volumeKey) ?? 1.0;
    final voiceLanguage = _prefs.getString(_languageKey) ?? 'en-GB';
    final voiceName = _prefs.getString(_voiceNameKey) ?? 'Google UK English Female';
    final sentenceSize = _prefs.getString(_sentenceSizeKey) ?? 'medium';
    final sentenceType = _prefs.getString(_sentenceTypeKey) ?? 'both';
    final readSentenceOnly = _prefs.getBool(_readSentenceOnlyKey) ?? false;
    final profileImage = _prefs.getString(_profileImageKey) ?? '';
    final fontSize = _prefs.getString(_fontSizeKey) ?? 'medium';
    final highContrast = _prefs.getBool(_highContrastKey) ?? false;
    final projectRoot = _prefs.getString(_projectRootKey) ?? '';
    final colourTheme = _prefs.getString(_colourThemeKey) ?? 'teal';
    final symbolSize = _prefs.getDouble(_symbolSizeKey) ?? 1.0;
    final gridSpacing = _prefs.getDouble(_gridSpacingKey) ?? 10.0;
    final reduceMotion = _prefs.getBool(_reduceMotionKey) ?? false;
    final boldText = _prefs.getBool(_boldTextKey) ?? false;
    final largerTouchTargets = _prefs.getBool(_largerTouchTargetsKey) ?? false;
    final speakOnTap = _prefs.getBool(_speakOnTapKey) ?? true;
    final buttonSpacing = _prefs.getDouble(_buttonSpacingKey) ?? 1.0;
    final appLanguage = _prefs.getString(_appLanguageKey) ?? 'en-GB';
    final showSymbolLabels = _prefs.getBool(_showSymbolLabelsKey) ?? true;
    final labelPosition = _prefs.getString(_labelPositionKey) ?? 'below';
    final analyticsEnabled = _prefs.getBool(_analyticsKey) ?? true;
    final crashReportingEnabled = _prefs.getBool(_crashReportingKey) ?? true;
    final saveHistory = _prefs.getBool(_saveHistoryKey) ?? true;
    final historyRetentionDays = _prefs.getInt(_historyRetentionKey) ?? 30;
    final cloudSyncEnabled = _prefs.getBool(_cloudSyncEnabledKey) ?? false;
    final syncOnWifiOnly = _prefs.getBool(_syncWifiOnlyKey) ?? true;
    final autoSyncOnLaunch = _prefs.getBool(_autoSyncOnLaunchKey) ?? true;

    return AppSettings(
      themeMode: themeMode,
      voiceRate: voiceRate,
      voicePitch: voicePitch,
      voiceVolume: voiceVolume,
      voiceLanguage: voiceLanguage,
      voiceName: voiceName,
      sentenceSize: sentenceSize,
      sentenceType: sentenceType,
      readSentenceOnly: readSentenceOnly,
      profileImage: profileImage,
      fontSize: fontSize,
      highContrast: highContrast,
      projectRoot: projectRoot,
      colourTheme: colourTheme,
      symbolSize: symbolSize,
      gridSpacing: gridSpacing,
      reduceMotion: reduceMotion,
      boldText: boldText,
      largerTouchTargets: largerTouchTargets,
      speakOnTap: speakOnTap,
      buttonSpacing: buttonSpacing,
      appLanguage: appLanguage,
      showSymbolLabels: showSymbolLabels,
      labelPosition: labelPosition,
      analyticsEnabled: analyticsEnabled,
      crashReportingEnabled: crashReportingEnabled,
      saveHistory: saveHistory,
      historyRetentionDays: historyRetentionDays,
      cloudSyncEnabled: cloudSyncEnabled,
      syncOnWifiOnly: syncOnWifiOnly,
      autoSyncOnLaunch: autoSyncOnLaunch,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_themeKey, _themeToString(settings.themeMode));
    await _prefs.setDouble(_rateKey, settings.voiceRate);
    await _prefs.setDouble(_pitchKey, settings.voicePitch);
    await _prefs.setDouble(_volumeKey, settings.voiceVolume);
    await _prefs.setString(_languageKey, settings.voiceLanguage);
    await _prefs.setString(_voiceNameKey, settings.voiceName);
    await _prefs.setString(_sentenceSizeKey, settings.sentenceSize);
    await _prefs.setString(_sentenceTypeKey, settings.sentenceType);
    await _prefs.setBool(_readSentenceOnlyKey, settings.readSentenceOnly);
    await _prefs.setString(_profileImageKey, settings.profileImage);
    await _prefs.setString(_fontSizeKey, settings.fontSize);
    await _prefs.setBool(_highContrastKey, settings.highContrast);
    await _prefs.setString(_projectRootKey, settings.projectRoot);
    await _prefs.setString(_colourThemeKey, settings.colourTheme);
    await _prefs.setDouble(_symbolSizeKey, settings.symbolSize);
    await _prefs.setDouble(_gridSpacingKey, settings.gridSpacing);
    await _prefs.setBool(_reduceMotionKey, settings.reduceMotion);
    await _prefs.setBool(_boldTextKey, settings.boldText);
    await _prefs.setBool(_largerTouchTargetsKey, settings.largerTouchTargets);
    await _prefs.setBool(_speakOnTapKey, settings.speakOnTap);
    await _prefs.setDouble(_buttonSpacingKey, settings.buttonSpacing);
    await _prefs.setString(_appLanguageKey, settings.appLanguage);
    await _prefs.setBool(_showSymbolLabelsKey, settings.showSymbolLabels);
    await _prefs.setString(_labelPositionKey, settings.labelPosition);
    await _prefs.setBool(_analyticsKey, settings.analyticsEnabled);
    await _prefs.setBool(_crashReportingKey, settings.crashReportingEnabled);
    await _prefs.setBool(_saveHistoryKey, settings.saveHistory);
    await _prefs.setInt(_historyRetentionKey, settings.historyRetentionDays);
    await _prefs.setBool(_cloudSyncEnabledKey, settings.cloudSyncEnabled);
    await _prefs.setBool(_syncWifiOnlyKey, settings.syncOnWifiOnly);
    await _prefs.setBool(_autoSyncOnLaunchKey, settings.autoSyncOnLaunch);
    await _recordSyncChange(settings);
  }

  List<String> getTabOrder() {
    return _prefs.getStringList(_tabOrderKey) ?? [];
  }

  Future<void> saveTabOrder(List<String> order) async {
    await _prefs.setStringList(_tabOrderKey, order);
    final sync = await SyncService.init();
    await sync.recordChange(
      entityType: SyncEntityType.settings,
      entityId: 'global_tab_order',
      operation: SyncOperation.upsert,
      payload: {'tabOrder': order},
    );
  }

  Future<void> _recordSyncChange(AppSettings settings) async {
    final sync = await SyncService.init();
    await sync.recordChange(
      entityType: SyncEntityType.settings,
      entityId: 'global',
      operation: SyncOperation.upsert,
      payload: settings.toMap(),
    );
  }

  List<String> getCustomColors() {
    return _prefs.getStringList(_customColorsKey) ?? [];
  }

  Future<void> saveCustomColors(List<String> colors) async {
    await _prefs.setStringList(_customColorsKey, colors);
  }

  String _themeToString(ThemeMode mode) {
    if (mode == ThemeMode.light) return 'light';
    if (mode == ThemeMode.dark) return 'dark';
    return 'system';
  }
}
