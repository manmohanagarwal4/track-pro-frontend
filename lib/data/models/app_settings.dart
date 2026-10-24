import 'package:flutter/material.dart' show ThemeMode;

import 'enums.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.unit = DistanceUnit.km,
    this.liveSimulation = true,
    this.simulationSpeed = 1,
    this.clustering = true,
    this.showTrails = true,
    this.showGeofences = true,
    this.showMapLabels = true,
    this.inAppBanners = true,
    this.pushOverspeed = true,
    this.pushGeofence = true,
    this.pushBattery = true,
    this.pushOffline = true,
    this.pushTrips = true,
    this.simulateErrors = true,
    this.biometricLock = false,
    this.twoFactor = false,
    this.shareAnalytics = true,
    this.historyRetentionDays = 90,
    this.onboardingDone = false,
  });

  final ThemeMode themeMode;
  final DistanceUnit unit;
  final bool liveSimulation;

  /// Simulation time multiplier (1x, 2x, 5x, 10x).
  final double simulationSpeed;
  final bool clustering;
  final bool showTrails;
  final bool showGeofences;
  final bool showMapLabels;
  final bool inAppBanners;
  final bool pushOverspeed;
  final bool pushGeofence;
  final bool pushBattery;
  final bool pushOffline;
  final bool pushTrips;

  /// Randomly fail some mock reads to exercise error states.
  final bool simulateErrors;
  final bool biometricLock;
  final bool twoFactor;
  final bool shareAnalytics;
  final int historyRetentionDays;
  final bool onboardingDone;

  AppSettings copyWith({
    ThemeMode? themeMode,
    DistanceUnit? unit,
    bool? liveSimulation,
    double? simulationSpeed,
    bool? clustering,
    bool? showTrails,
    bool? showGeofences,
    bool? showMapLabels,
    bool? inAppBanners,
    bool? pushOverspeed,
    bool? pushGeofence,
    bool? pushBattery,
    bool? pushOffline,
    bool? pushTrips,
    bool? simulateErrors,
    bool? biometricLock,
    bool? twoFactor,
    bool? shareAnalytics,
    int? historyRetentionDays,
    bool? onboardingDone,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        unit: unit ?? this.unit,
        liveSimulation: liveSimulation ?? this.liveSimulation,
        simulationSpeed: simulationSpeed ?? this.simulationSpeed,
        clustering: clustering ?? this.clustering,
        showTrails: showTrails ?? this.showTrails,
        showGeofences: showGeofences ?? this.showGeofences,
        showMapLabels: showMapLabels ?? this.showMapLabels,
        inAppBanners: inAppBanners ?? this.inAppBanners,
        pushOverspeed: pushOverspeed ?? this.pushOverspeed,
        pushGeofence: pushGeofence ?? this.pushGeofence,
        pushBattery: pushBattery ?? this.pushBattery,
        pushOffline: pushOffline ?? this.pushOffline,
        pushTrips: pushTrips ?? this.pushTrips,
        simulateErrors: simulateErrors ?? this.simulateErrors,
        biometricLock: biometricLock ?? this.biometricLock,
        twoFactor: twoFactor ?? this.twoFactor,
        shareAnalytics: shareAnalytics ?? this.shareAnalytics,
        historyRetentionDays: historyRetentionDays ?? this.historyRetentionDays,
        onboardingDone: onboardingDone ?? this.onboardingDone,
      );

  bool allowsAlert(AlertType type) => switch (type) {
        AlertType.overspeed => pushOverspeed,
        AlertType.geofenceEnter || AlertType.geofenceExit => pushGeofence,
        AlertType.lowBattery => pushBattery,
        AlertType.offline || AlertType.online => pushOffline,
        _ => true,
      };

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'unit': unit.name,
        'live': liveSimulation,
        'simSpeed': simulationSpeed,
        'clustering': clustering,
        'trails': showTrails,
        'geofences': showGeofences,
        'labels': showMapLabels,
        'banners': inAppBanners,
        'pOverspeed': pushOverspeed,
        'pGeofence': pushGeofence,
        'pBattery': pushBattery,
        'pOffline': pushOffline,
        'pTrips': pushTrips,
        'errors': simulateErrors,
        'bio': biometricLock,
        'twoFactor': twoFactor,
        'analytics': shareAnalytics,
        'retention': historyRetentionDays,
        'onboarding': onboardingDone,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    const d = AppSettings();
    return AppSettings(
      themeMode: enumByName(ThemeMode.values, j['themeMode'], d.themeMode),
      unit: enumByName(DistanceUnit.values, j['unit'], d.unit),
      liveSimulation: j['live'] as bool? ?? d.liveSimulation,
      simulationSpeed: (j['simSpeed'] as num?)?.toDouble() ?? d.simulationSpeed,
      clustering: j['clustering'] as bool? ?? d.clustering,
      showTrails: j['trails'] as bool? ?? d.showTrails,
      showGeofences: j['geofences'] as bool? ?? d.showGeofences,
      showMapLabels: j['labels'] as bool? ?? d.showMapLabels,
      inAppBanners: j['banners'] as bool? ?? d.inAppBanners,
      pushOverspeed: j['pOverspeed'] as bool? ?? d.pushOverspeed,
      pushGeofence: j['pGeofence'] as bool? ?? d.pushGeofence,
      pushBattery: j['pBattery'] as bool? ?? d.pushBattery,
      pushOffline: j['pOffline'] as bool? ?? d.pushOffline,
      pushTrips: j['pTrips'] as bool? ?? d.pushTrips,
      simulateErrors: j['errors'] as bool? ?? d.simulateErrors,
      biometricLock: j['bio'] as bool? ?? d.biometricLock,
      twoFactor: j['twoFactor'] as bool? ?? d.twoFactor,
      shareAnalytics: j['analytics'] as bool? ?? d.shareAnalytics,
      historyRetentionDays: (j['retention'] as num?)?.toInt() ?? d.historyRetentionDays,
      onboardingDone: j['onboarding'] as bool? ?? d.onboardingDone,
    );
  }
}
