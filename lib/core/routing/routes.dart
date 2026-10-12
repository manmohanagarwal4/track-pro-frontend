/// Route paths. Use the helpers for parameterised routes.
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  // Shell tabs
  static const home = '/home';
  static const devices = '/devices';
  static const map = '/map';
  static const alerts = '/alerts';
  static const more = '/more';
  static const fleet = '/fleet';
  static const trips = '/trips';

  // Full screen
  static const addDevice = '/add-device';
  static const geofences = '/geofences';
  static const newGeofence = '/geofences/new';
  static const notifications = '/notifications';
  static const drivers = '/drivers';
  static const assets = '/assets';
  static const profile = '/profile';
  static const settings = '/settings';

  static String device(String id) => '/device/$id';
  static String deviceHistory(String id) => '/device/$id/history';
  static String deviceTrips(String id) => '/device/$id/trips';
  static String deviceSettings(String id) => '/device/$id/settings';
  static String deviceShare(String id) => '/device/$id/share';
  static String trip(String deviceId, String tripId) => '/device/$deviceId/trips/$tripId';
  static String geofence(String id) => '/geofences/$id';
  static String newGeofenceFor(String deviceId) => '/geofences/new?device=$deviceId';
  static String driver(String id) => '/drivers/$id';
  static String mapFocus(String deviceId) => '/map?device=$deviceId';
  static String settingsSection(String section) => '/settings/$section';

  static const publicPaths = {splash, onboarding, login, register};
}
