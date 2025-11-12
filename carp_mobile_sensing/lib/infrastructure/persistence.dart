/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../infrastructure.dart';

/// Stores meta data about the running [SmartphoneDeployment] and all
/// [UserTask] json objects in an SQLite database on the device's
/// local storage media. To be used across app restarts.
///
/// Deployments are stored in the `deployment` table and user tasks are stored
/// in the `task_queue` table.
///
/// The path and filename format is
///
///   `~/carp.db`
///
/// where `~` is the folder where SQLite places it database files.
///
/// On iOS, this is the `NSDocumentsDirectory` and the files can be accessed via
/// the MacOS Finder.
///
/// On Android, Flutter files are stored in the `databases` directory, which is
/// located in the `data/data/<package_name>/databases/` folder.
/// Files can be accessed via AndroidStudio.
class Persistence {
  static const String DATABASE_NAME = 'carp';
  static const String DEPLOYMENT_TABLE_NAME = 'deployment';
  static const String TASK_QUEUE_TABLE_NAME = 'task_queue';

  static const String STUDY_ID_COLUMN = 'study_id';
  static const String STUDY_DEPLOYMENT_ID_COLUMN = 'study_deployment_id';
  static const String STUDY_DEPLOYMENT_STATUS_COLUMN =
      'study_deployment_status';
  static const String DEVICE_ROLE_NAME_COLUMN = 'device_role_name';
  static const String PARTICIPANT_ID_COLUMN = 'participant_id';
  static const String PARTICIPANT_ROLE_NAME_COLUMN = 'participant_role_name';
  static const String UPDATED_AT_COLUMN = 'updated_at';
  static const String DEPLOYED_AT_COLUMN = 'deployed_at';
  static const String DEPLOYMENT_COLUMN = 'deployment';
  // static const String USER_ID_COLUMN = 'user_id';

  static const String ID_COLUMN = 'id';
  static const String TASK_ID_COLUMN = 'task_id';
  static const String TASK_COLUMN = 'task';

  static final Persistence _instance = Persistence._();
  Persistence._();
  factory Persistence() => _instance;

  String? _databasePath;
  Database? database;

  /// Path of the database.
  String get databasePath => '$_databasePath';

  /// Full path and name of the database.
  String get databaseName => '$_databasePath/$DATABASE_NAME.db';

  /// Initialize the persistence layer and the database.
  Future<void> init([SmartphoneDeployment? deployment]) async {
    info('Initializing $runtimeType...');
    _databasePath ??= await getDatabasesPath();

    // open the database - make sure to use the same database across app (re)start
    database = await openDatabase(
      databaseName,
      version: 1,
      singleInstance: true,
      onCreate: (Database db, int version) async {
        // when creating the database, create the tables
        await db.execute(
          'CREATE TABLE $DEPLOYMENT_TABLE_NAME ('
          '$STUDY_ID_COLUMN TEXT, '
          '$STUDY_DEPLOYMENT_ID_COLUMN TEXT PRIMARY KEY, '
          '$DEVICE_ROLE_NAME_COLUMN TEXT, '
          '$PARTICIPANT_ID_COLUMN TEXT, '
          '$PARTICIPANT_ROLE_NAME_COLUMN TEXT, '
          '$STUDY_DEPLOYMENT_STATUS_COLUMN INTEGER, '
          '$UPDATED_AT_COLUMN TEXT, '
          '$DEPLOYED_AT_COLUMN TEXT, '
          '$DEPLOYMENT_COLUMN TEXT)',
        );

        await db.execute(
          'CREATE TABLE $TASK_QUEUE_TABLE_NAME ('
          '$ID_COLUMN INTEGER PRIMARY KEY, '
          '$STUDY_DEPLOYMENT_ID_COLUMN TEXT, '
          '$TASK_ID_COLUMN TEXT, '
          '$TASK_COLUMN TEXT)',
        );

        debug('$runtimeType - $databaseName DB created');
      },
    );

    // save the deployment if specified
    if (deployment != null) saveDeployment(deployment);

    // listen to changes to the app task queue so we can save them
    AppTaskController().userTaskEvents.listen((task) => saveUserTask(task));

    info('$runtimeType - SQLite DB initialized - name: $databaseName');
  }

  /// Close the persistence layer. After close is called, no deployment can be
  /// accessed or saved.
  Future<void> close() async => await database?.close();

  /// Get the list of all study deployments previously stored on this phone.
  ///
  /// Returns an empty list, if not study deployments are stored.
  Future<List<SmartphoneStudy>> getAllStudyDeployments() async {
    info("$runtimeType - Getting all study deployments stored on this device.");
    List<SmartphoneStudy> list = [];
    try {
      final List<Map<String, Object?>> maps =
          await database?.query(
            DEPLOYMENT_TABLE_NAME,
            columns: [
              STUDY_ID_COLUMN,
              STUDY_DEPLOYMENT_ID_COLUMN,
              DEVICE_ROLE_NAME_COLUMN,
              PARTICIPANT_ID_COLUMN,
              PARTICIPANT_ROLE_NAME_COLUMN,
              STUDY_DEPLOYMENT_STATUS_COLUMN,
            ],
          ) ??
          [];
      if (maps.isNotEmpty) {
        for (var map in maps) {
          final study = SmartphoneStudy(
            studyId: map[STUDY_ID_COLUMN] as String,
            studyDeploymentId: map[STUDY_DEPLOYMENT_ID_COLUMN] as String,
            deviceRoleName: map[DEVICE_ROLE_NAME_COLUMN] as String,
            participantId: map[PARTICIPANT_ID_COLUMN] as String,
            participantRoleName: map[PARTICIPANT_ROLE_NAME_COLUMN] as String,
          );
          final status = map[STUDY_DEPLOYMENT_STATUS_COLUMN] as int;
          study.status = StudyStatus.values[status];
          list.add(study);
        }
      }
    } catch (exception) {
      warning('$runtimeType - Failed to load deployments - $exception');
    }

    return list;
  }

  /// Save the [deployment] persistently to a local cache.
  /// Returns `true` if successful.
  Future<bool> saveDeployment(SmartphoneDeployment deployment) async {
    info("$runtimeType - Saving deployment to database.");
    bool success = true;
    try {
      final Map<String, dynamic> map = {
        STUDY_ID_COLUMN: deployment.studyId,
        STUDY_DEPLOYMENT_ID_COLUMN: deployment.studyDeploymentId,
        DEVICE_ROLE_NAME_COLUMN: deployment.deviceRoleName,
        PARTICIPANT_ID_COLUMN: deployment.participantId,
        PARTICIPANT_ROLE_NAME_COLUMN: deployment.participantRoleName,
        STUDY_DEPLOYMENT_STATUS_COLUMN: deployment.status.index,
        UPDATED_AT_COLUMN: DateTime.now().toUtc().toIso8601String(),
        DEPLOYED_AT_COLUMN: deployment.deployed?.toUtc().toIso8601String(),
        DEPLOYMENT_COLUMN: jsonEncode(deployment),
      };
      await database?.insert(
        DEPLOYMENT_TABLE_NAME,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (exception) {
      success = false;
      warning('$runtimeType - Failed to save deployment - $exception');
    }
    return success;
  }

  /// Restore the [SmartphoneDeployment] with the [deploymentId] from local cache.
  /// Returns a [SmartphoneDeployment] if successful, null otherwise.
  Future<SmartphoneDeployment?> restoreDeployment(String deploymentId) async {
    info("$runtimeType - Restoring deployment, deploymentId: $deploymentId");
    SmartphoneDeployment? deployment;
    try {
      final List<Map<String, Object?>> maps =
          await database?.query(
            DEPLOYMENT_TABLE_NAME,
            columns: [DEPLOYMENT_COLUMN],
            where: '$STUDY_DEPLOYMENT_ID_COLUMN = ?',
            whereArgs: [deploymentId],
          ) ??
          [];

      if (maps.isNotEmpty) {
        final jsonString = maps[0][DEPLOYMENT_COLUMN] as String;
        deployment = SmartphoneDeployment.fromJson(
          json.decode(jsonString) as Map<String, dynamic>,
        );
      }
    } catch (exception) {
      warning('$runtimeType - Failed to restore deployment - $exception');
    }

    return deployment;
  }

  /// Erase the [SmartphoneDeployment] with the [deploymentId] from local cache.
  Future<void> eraseDeployment(String deploymentId) async {
    info("$runtimeType - Erasing deployment, deploymentId: $deploymentId");
    try {
      await database?.delete(
        DEPLOYMENT_TABLE_NAME,
        where: '$STUDY_DEPLOYMENT_ID_COLUMN = ?',
        whereArgs: [deploymentId],
      );
    } catch (exception) {
      warning('$runtimeType - Failed to erase deployment - $exception');
    }
  }

  /// Update or delete a task queue entry.
  Future<void> saveUserTask(UserTask task) async {
    debug("$runtimeType - Saving task to database '$task'.");
    switch (task.state) {
      case UserTaskState.initialized:
      case UserTaskState.enqueued:
      case UserTaskState.notified:
      case UserTaskState.started:
      case UserTaskState.canceled:
      case UserTaskState.done:
      case UserTaskState.expired:
      case UserTaskState.undefined:
        // all these cases we need to create or update the record
        var snapshot = UserTaskSnapshot.fromUserTask(task);
        final Map<String, dynamic> map = {
          STUDY_DEPLOYMENT_ID_COLUMN: task.studyDeploymentId,
          TASK_ID_COLUMN: task.id,
          TASK_COLUMN: jsonEncode(snapshot),
        };
        int count =
            await database?.update(
              TASK_QUEUE_TABLE_NAME,
              map,
              where: '$TASK_ID_COLUMN = ?',
              whereArgs: [task.id],
              conflictAlgorithm: ConflictAlgorithm.replace,
            ) ??
            0;

        if (count == 0) {
          await database?.insert(
            TASK_QUEUE_TABLE_NAME,
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        break;
      case UserTaskState.dequeued:
        await database?.delete(
          TASK_QUEUE_TABLE_NAME,
          where: '$TASK_ID_COLUMN = ?',
          whereArgs: [task.id],
        );
        break;
    }
  }

  /// Get the entire list of [UserTaskSnapshot].
  Future<List<UserTaskSnapshot>> getUserTasks() async {
    List<UserTaskSnapshot> result = [];
    try {
      final List<Map<String, Object?>> list =
          await database?.query(
            TASK_QUEUE_TABLE_NAME,
            columns: [TASK_COLUMN],
          ) ??
          [];

      if (list.isNotEmpty) {
        for (var element in list) {
          final jsonString = element[TASK_COLUMN] as String;
          result.add(
            UserTaskSnapshot.fromJson(
              json.decode(jsonString) as Map<String, dynamic>,
            ),
          );
        }
      }
    } catch (exception) {
      warning('$runtimeType - Failed to load task queue - $exception');
    }

    return result;
  }
}
