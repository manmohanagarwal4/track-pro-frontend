import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/enums.dart';

/// Single icon system for the app (Lucide).
abstract final class AppIcons {
  // Navigation
  static const home = LucideIcons.house;
  static const dashboard = LucideIcons.layoutDashboard;
  static const devices = LucideIcons.radar;
  static const map = LucideIcons.map;
  static const alerts = LucideIcons.bell;
  static const more = LucideIcons.ellipsis;
  static const fleet = LucideIcons.truck;
  static const trips = LucideIcons.route;

  // Actions
  static const add = LucideIcons.plus;
  static const search = LucideIcons.search;
  static const filter = LucideIcons.slidersHorizontal;
  static const sort = LucideIcons.arrowUpDown;
  static const share = LucideIcons.share2;
  static const copy = LucideIcons.copy;
  static const delete = LucideIcons.trash2;
  static const edit = LucideIcons.pencil;
  static const close = LucideIcons.x;
  static const check = LucideIcons.check;
  static const chevronRight = LucideIcons.chevronRight;
  static const back = LucideIcons.chevronLeft;
  static const qr = LucideIcons.qrCode;
  static const scan = LucideIcons.scanLine;
  static const refresh = LucideIcons.refreshCw;
  static const play = LucideIcons.play;
  static const pause = LucideIcons.pause;
  static const link = LucideIcons.link;
  static const logout = LucideIcons.logOut;
  static const settings = LucideIcons.settings;

  // Map
  static const locate = LucideIcons.locateFixed;
  static const crosshair = LucideIcons.crosshair;
  static const layers = LucideIcons.layers;
  static const zoomIn = LucideIcons.plus;
  static const zoomOut = LucideIcons.minus;
  static const navigation = LucideIcons.navigation2;
  static const pin = LucideIcons.mapPin;
  static const geofence = LucideIcons.circleDot;
  static const history = LucideIcons.history;
  static const follow = LucideIcons.locate;

  // Telemetry
  static const speed = LucideIcons.gauge;
  static const compass = LucideIcons.compass;
  static const altitude = LucideIcons.mountain;
  static const accuracy = LucideIcons.crosshair;
  static const satellite = LucideIcons.satellite;
  static const battery = LucideIcons.batteryMedium;
  static const batteryLow = LucideIcons.batteryLow;
  static const network = LucideIcons.signal;
  static const temperature = LucideIcons.thermometer;
  static const motion = LucideIcons.activity;
  static const ignition = LucideIcons.power;
  static const fuel = LucideIcons.fuel;
  static const odometer = LucideIcons.milestone;
  static const clock = LucideIcons.clock;
  static const calendar = LucideIcons.calendar;
  static const timer = LucideIcons.timer;
  static const stops = LucideIcons.octagonPause;

  // Status / alerts
  static const emergency = LucideIcons.siren;
  static const warning = LucideIcons.triangleAlert;
  static const info = LucideIcons.info;
  static const success = LucideIcons.circleCheck;
  static const offline = LucideIcons.cloudOff;
  static const online = LucideIcons.wifi;
  static const overspeed = LucideIcons.gauge;
  static const geofenceEnter = LucideIcons.logIn;
  static const geofenceExit = LucideIcons.logOut;

  // Misc
  static const user = LucideIcons.circleUser;
  static const users = LucideIcons.users;
  static const driver = LucideIcons.idCard;
  static const assets = LucideIcons.boxes;
  static const tracker = LucideIcons.cpu;
  static const phone = LucideIcons.phone;
  static const mail = LucideIcons.mail;
  static const lock = LucideIcons.lock;
  static const shield = LucideIcons.shieldCheck;
  static const bellRing = LucideIcons.bellRing;
  static const sun = LucideIcons.sun;
  static const moon = LucideIcons.moon;
  static const system = LucideIcons.monitorSmartphone;
  static const ruler = LucideIcons.ruler;
  static const eye = LucideIcons.eye;
  static const eyeOff = LucideIcons.eyeOff;
  static const building = LucideIcons.building2;
  static const star = LucideIcons.star;
  static const flask = LucideIcons.flaskConical;
  static const sparkles = LucideIcons.sparkles;
  static const inbox = LucideIcons.inbox;
  static const route = LucideIcons.route;
  static const flag = LucideIcons.flag;
  static const circle = LucideIcons.circle;

  static IconData asset(AssetType type) => switch (type) {
        AssetType.pet => LucideIcons.pawPrint,
        AssetType.key => LucideIcons.keyRound,
        AssetType.car => LucideIcons.car,
        AssetType.bike => LucideIcons.bike,
        AssetType.person => LucideIcons.user,
        AssetType.item => LucideIcons.briefcase,
        AssetType.taxi => LucideIcons.carTaxiFront,
        AssetType.truck => LucideIcons.truck,
        AssetType.delivery => LucideIcons.package,
        AssetType.equipment => LucideIcons.factory,
        AssetType.generic => LucideIcons.radio,
      };

  static IconData alert(AlertType type) => switch (type) {
        AlertType.overspeed => overspeed,
        AlertType.geofenceEnter => geofenceEnter,
        AlertType.geofenceExit => geofenceExit,
        AlertType.lowBattery => batteryLow,
        AlertType.offline => offline,
        AlertType.online => online,
        AlertType.emergency => emergency,
        AlertType.ignition => ignition,
      };

  static IconData geofenceType(GeofenceType type) => switch (type) {
        GeofenceType.home => LucideIcons.house,
        GeofenceType.office => LucideIcons.building2,
        GeofenceType.warehouse => LucideIcons.warehouse,
        GeofenceType.restricted => LucideIcons.ban,
        GeofenceType.customer => LucideIcons.store,
        GeofenceType.safeZone => LucideIcons.shieldCheck,
      };

  static IconData notification(NotificationCategory c) => switch (c) {
        NotificationCategory.alerts => alerts,
        NotificationCategory.system => LucideIcons.sparkles,
        NotificationCategory.devices => tracker,
        NotificationCategory.trips => trips,
      };
}
