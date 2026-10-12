/// Domain enums shared across the app.
library;

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

enum AccountType {
  personal('Personal'),
  business('Business');

  const AccountType(this.label);
  final String label;
}

enum AssetCategory { personal, business }

enum AssetType {
  pet('Pet', AssetCategory.personal),
  key('Key', AssetCategory.personal),
  car('Vehicle', AssetCategory.personal),
  bike('Bike', AssetCategory.personal),
  person('Person', AssetCategory.personal),
  item('Personal Asset', AssetCategory.personal),
  taxi('Taxi', AssetCategory.business),
  truck('Truck', AssetCategory.business),
  delivery('Delivery', AssetCategory.business),
  equipment('Equipment', AssetCategory.business),
  generic('Tracker', AssetCategory.personal);

  const AssetType(this.label, this.category);
  final String label;
  final AssetCategory category;

  bool get isVehicle =>
      this == car || this == bike || this == taxi || this == truck || this == delivery;
  bool get hasIgnition => isVehicle;
  bool get hasFuel => this == truck || this == delivery || this == taxi;
  bool get usesRegistration => isVehicle;

  /// km/h below which the asset is considered not moving.
  double get movingThreshold => isVehicle ? 3 : 1;

  double get defaultSpeedLimit => switch (this) {
        AssetType.bike => 70,
        _ => 80,
      };

  /// Filter bucket used by the device list "asset" filter.
  AssetFilter get filterGroup => switch (this) {
        AssetType.pet => AssetFilter.pet,
        AssetType.key => AssetFilter.key,
        AssetType.car || AssetType.bike => AssetFilter.vehicle,
        AssetType.taxi => AssetFilter.taxi,
        AssetType.truck => AssetFilter.truck,
        AssetType.delivery => AssetFilter.delivery,
        AssetType.person => AssetFilter.person,
        _ => AssetFilter.other,
      };

  /// Types offered in the Add Tracker flow.
  static const selectable = [
    pet,
    car,
    bike,
    taxi,
    truck,
    delivery,
    person,
    key,
    item,
    equipment,
  ];
}

enum AssetFilter {
  all('All'),
  pet('Pet'),
  vehicle('Vehicle'),
  taxi('Taxi'),
  truck('Truck'),
  key('Key'),
  person('Person'),
  delivery('Delivery'),
  other('Other');

  const AssetFilter(this.label);
  final String label;
}

enum TrackingMode {
  realTime('Real Time', Duration(seconds: 2), 'Live updates every 2 seconds'),
  normal('Normal', Duration(seconds: 5), 'Balanced, updates every 5 seconds'),
  powerSaving('Power Saving', Duration(seconds: 15), 'Updates every 15 seconds'),
  sleep('Sleep', Duration(seconds: 60), 'Wakes once a minute'),
  emergency('Emergency', Duration(seconds: 1), 'Maximum frequency, every second');

  const TrackingMode(this.label, this.interval, this.description);
  final String label;
  final Duration interval;
  final String description;
}

/// Every status the status engine can produce.
enum DeviceStatus {
  online('Online'),
  offline('Offline'),
  moving('Moving'),
  idle('Idle'),
  stopped('Stopped'),
  stationary('Stationary'),
  lowBattery('Low battery'),
  noGps('No GPS'),
  noNetwork('No network'),
  emergency('Emergency');

  const DeviceStatus(this.label);
  final String label;
}

enum StatusFilter {
  all('All'),
  online('Online'),
  offline('Offline'),
  moving('Moving'),
  idle('Idle'),
  alert('Alert');

  const StatusFilter(this.label);
  final String label;
}

enum SignalQuality {
  none('No signal', 0),
  poor('Poor', 1),
  fair('Fair', 2),
  good('Good', 3),
  excellent('Excellent', 4);

  const SignalQuality(this.label, this.bars);
  final String label;
  final int bars;
}

enum GeofenceType {
  home('Home'),
  office('Office'),
  warehouse('Warehouse'),
  restricted('Restricted Area'),
  customer('Customer Location'),
  safeZone('Safe Zone');

  const GeofenceType(this.label);
  final String label;
}

enum GeofenceEventType { enter, exit }

enum AlertType {
  overspeed('Overspeed'),
  geofenceEnter('Geofence Enter'),
  geofenceExit('Geofence Exit'),
  lowBattery('Low Battery'),
  offline('Device Offline'),
  online('Back Online'),
  emergency('Emergency'),
  ignition('Ignition');

  const AlertType(this.label);
  final String label;
}

enum AlertSeverity { critical, warning, info }

enum AlertFilter {
  all('All'),
  unread('Unread'),
  overspeed('Overspeed'),
  geofence('Geofence'),
  battery('Battery'),
  offline('Offline'),
  emergency('Emergency');

  const AlertFilter(this.label);
  final String label;
}

enum NotificationCategory {
  alerts('Alerts'),
  system('System'),
  devices('Devices'),
  trips('Trips');

  const NotificationCategory(this.label);
  final String label;
}

enum SharePermission {
  viewOnly('View only', 'Current location snapshot'),
  liveTracking('Live tracking', 'Real-time position updates'),
  history('History', 'Live tracking plus route history');

  const SharePermission(this.label, this.description);
  final String label;
  final String description;
}

enum DistanceUnit {
  km('Kilometers', 'km', 'km/h'),
  miles('Miles', 'mi', 'mph');

  const DistanceUnit(this.label, this.short, this.speed);
  final String label;
  final String short;
  final String speed;
}

enum DeviceSort {
  name('Name'),
  status('Status'),
  speed('Speed'),
  battery('Battery'),
  lastUpdate('Last update');

  const DeviceSort(this.label);
  final String label;
}

enum DriverStatus {
  driving('Driving'),
  onDuty('On duty'),
  offDuty('Off duty');

  const DriverStatus(this.label);
  final String label;
}
