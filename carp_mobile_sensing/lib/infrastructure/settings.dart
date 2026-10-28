part of '../infrastructure.dart';

/// The amount of logging done by CAMS, set in [Settings.debugLevel].
///
/// Each level includes the levels before it. Logging is done with the
/// top-level `info`, `warning` and `debug` functions.
///  * [none] - no logging.
///  * [info] - information messages.
///  * [warning] - warnings.
///  * [debug] - debug messages (only shown when the app runs in debug mode).
enum DebugLevel { none, info, warning, debug }

/// Global settings for CAMS: logging level, app info, time zone, a user ID,
/// and the file paths used to store data on the phone.
///
/// A singleton, accessed as `Settings()`. Must be initialized with [init]
/// before use, which [SmartPhoneClientManager.configure] does.
///
/// Supports:
///  * setting debug level - see [debugLevel]
///  * getting shared preferences - see [preferences]
///  * getting app info - see [appName], [packageName], [version], [buildNumber],
///    and [packageInfo]
///  * generating a unique and anonymous user id - see [userId]
///  * getting the current timezone of the app - see [timezone]
///  * getting file paths for storing data - see [localApplicationPath], [carpBasePath],
///    [getDeploymentBasePath], [getCacheBasePath], and [getDataBasePath]
class Settings {
  /// The [preferences] key under which [userId] is stored.
  static const String USER_ID_KEY = 'user_id';

  /// Folder name for deployments under [carpBasePath].
  static const String CARP_DEPLOYMENT_FILE_PATH = 'deployments';

  /// Folder name for data under a deployment folder.
  static const String CARP_DATA_FILE_PATH = 'data';

  /// Folder name for cached data under a deployment folder.
  static const String CARP_CACHE_FILE_PATH = 'cache';

  static final Settings _instance = Settings._();
  factory Settings() => _instance;
  Settings._();

  SharedPreferences? _preferences;
  PackageInfo? _packageInfo;
  String? _appName;
  String? _packageName;
  String? _version;
  String? _buildNumber;
  String? _localApplicationPath, _carpBasePath;
  final Map<String, String> _deploymentBasePaths = {};
  String _timezone = 'Europe/Copenhagen';
  bool _initialized = false;

  /// Has the setting been initialized via calling the [init] method?
  bool get initialized => _initialized;

  /// The global debug level setting.
  ///
  /// See [DebugLevel] for valid debug level settings.
  /// Can be changed at runtime. Default is [DebugLevel.warning].
  DebugLevel debugLevel = DebugLevel.warning;

  /// The app name as displayed in the OS.
  /// `CFBundleDisplayName` on iOS, `application/android:label` on Android.
  String? get appName => _appName;

  /// The package name.
  /// `PRODUCT_BUNDLE_IDENTIFIER` on iOS, `package` on Android.
  String? get packageName => _packageName;

  /// The package version.
  /// `CFBundleShortVersionString` on iOS, `versionName` on Android.
  String? get version => _version;

  /// The build number.
  /// `CFBundleVersion` on iOS, `versionCode` on Android.
  String? get buildNumber => _buildNumber;

  /// A simple persistent store for simple data. Note that data is saved in
  /// plain format and should hence **not** be used for sensitive data.
  ///
  /// Wraps NSUserDefaults (on iOS) and SharedPreferences (on Android).
  SharedPreferences? get preferences => _preferences;

  /// Package information for the app, from the `package_info_plus` plugin.
  PackageInfo? get packageInfo => _packageInfo;

  /// The current time zone of this app.
  ///
  /// Note that this is only set once when the app starts, and will not update
  /// if the user changes the time zone while the app is running.
  /// Defaults to `Europe/Copenhagen` if the time zone cannot be read.
  String get timezone => _timezone;

  /// Path to a directory where the application may place data that is
  /// user-generated (the app documents directory).
  Future<String> get localApplicationPath async {
    if (_localApplicationPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _localApplicationPath = directory.path;
    }
    return _localApplicationPath!;
  }

  /// The base path for storing all CARP related files on the form
  ///
  ///  `<localApplicationPath>/carp`
  ///
  Future<String> get carpBasePath async {
    if (_carpBasePath == null) {
      _carpBasePath = '${await localApplicationPath}/carp';
      var directory = Directory(_carpBasePath!);
      await directory.exists().then((exists) {
        if (!exists) directory.createSync(recursive: true);
      });
    }

    return _carpBasePath!;
  }

  /// The base path for storing all deployment related files on the form
  ///
  ///  `<localApplicationPath>/carp/deployments/<study_deployment_id>`
  ///
  Future<String> getDeploymentBasePath(String studyDeploymentId) async {
    if (_deploymentBasePaths[studyDeploymentId] == null) {
      final path = '${await carpBasePath}/$CARP_DEPLOYMENT_FILE_PATH/$studyDeploymentId';
      _deploymentBasePaths[studyDeploymentId] = path;
      Directory(path).createSync(recursive: true);
    }

    return _deploymentBasePaths[studyDeploymentId]!;
  }

  /// The base path for storing cached data for a deployment.
  /// The folder is created if it does not exist.
  ///
  ///  `<localApplicationPath>/carp/deployments/<study_deployment_id>/cache`
  ///
  Future<String> getCacheBasePath(String studyDeploymentId) async => (await Directory(
    '${await getDeploymentBasePath(studyDeploymentId)}/$CARP_CACHE_FILE_PATH',
  ).create(recursive: true)).path;

  /// The base path for storing data (e.g. data files and media files) for a
  /// deployment. The folder is created if it does not exist.
  ///
  ///  `<localApplicationPath>/carp/deployments/<study_deployment_id>/data`
  ///
  Future<String> getDataBasePath(String studyDeploymentId) async => (await Directory(
    '${await getDeploymentBasePath(studyDeploymentId)}/$CARP_DATA_FILE_PATH',
  ).create(recursive: true)).path;

  /// Initializes settings. Must be called before using any settings.
  ///
  /// Loads shared preferences and package info, creates [carpBasePath], and
  /// reads the local [timezone]. Calling it again does nothing.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _preferences ??= await SharedPreferences.getInstance();
    _packageInfo ??= await PackageInfo.fromPlatform();
    _appName = _packageInfo?.appName;
    _packageName = _packageInfo?.packageName;
    _version = _packageInfo?.version;
    _buildNumber = _packageInfo?.buildNumber;

    // ensure that the base carp path is created
    localApplicationPath.then((_) async => await carpBasePath);

    debug('$runtimeType - Shared Preferences: ${_preferences?.getKeys()}');

    // setting up time zone settings
    tz.initializeTimeZones();
    try {
      _timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (error) {
      warning(
        '$runtimeType - Could not get the local timezone - $error. '
        'Setting timezone to default: $_timezone',
      );
    }

    info('$runtimeType - Time zone set to $timezone');
    debug('$runtimeType - Time zone location: ${tz.getLocation(timezone)}');
    info('$runtimeType initialized');
  }

  String? _userId;

  /// A user ID that is:
  ///  * unique
  ///  * anonymous
  ///  * persistent
  ///
  /// This id is generated the first time this method is called and then stored
  /// on the phone in-between sessions, and will therefore be the same for
  /// the same app on the same phone. Requires [init] to have been called.
  Future<String> get userId async {
    assert(_preferences != null, "Setting is not initialized. Call 'Setting().init()' first.");
    if (_userId == null) {
      _userId = preferences?.get(USER_ID_KEY) as String?;
      if (_userId == null) {
        _userId = const Uuid().v4();
        await preferences?.setString(USER_ID_KEY, _userId!);
      }
    }
    return _userId!;
  }
}
