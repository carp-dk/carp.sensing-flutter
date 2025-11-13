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
  static const String STUDY_TABLE_NAME = 'studies';
  static const String TASK_QUEUE_TABLE_NAME = 'task_queue';

  static const String STUDY_ID_COLUMN = 'study_id';
  static const String STUDY_DEPLOYMENT_ID_COLUMN = 'study_deployment_id';
  static const String DEVICE_ROLE_NAME_COLUMN = 'device_role_name';
  static const String PARTICIPANT_ID_COLUMN = 'participant_id';
  static const String PARTICIPANT_ROLE_NAME_COLUMN = 'participant_role_name';
  static const String CREATED_ON_COLUMN = 'created_on';
  static const String UPDATED_ON_COLUMN = 'updated_on';
  static const String DEPLOYED_ON_COLUMN = 'deployed_on';
  static const String DEPLOYMENT_STATUS_COLUMN = 'deployment_status';
  static const String DEPLOYMENT_COLUMN = 'deployment';

  static const String ID_COLUMN = 'id';
  static const String TASK_ID_COLUMN = 'task_id';
  static const String TASK_COLUMN = 'task';

  String? _databasePath;
  Database? _database;

  static final Persistence _instance = Persistence._();
  Persistence._();

  /// Get the singleton persistence layer.
  factory Persistence() => _instance;

  /// Path of the database.
  String get databasePath => '$_databasePath';

  /// Full path and name of the database.
  String get databaseName => '$_databasePath/$DATABASE_NAME.db';

  /// Initialize the persistence layer and the database.
  Future<void> init() async {
    info('Initializing $runtimeType...');
    _databasePath ??= await getDatabasesPath();

    // open the database - make sure to use the same database across app (re)start
    _database = await openDatabase(
      databaseName,
      version: 1,
      singleInstance: true,
      onCreate: (Database db, int version) async {
        // when creating the database, create the tables
        await db.execute(
          'CREATE TABLE $STUDY_TABLE_NAME ('
          '$STUDY_ID_COLUMN TEXT, '
          '$STUDY_DEPLOYMENT_ID_COLUMN TEXT, '
          '$DEVICE_ROLE_NAME_COLUMN TEXT, '
          '$PARTICIPANT_ID_COLUMN TEXT, '
          '$PARTICIPANT_ROLE_NAME_COLUMN TEXT, '
          '$CREATED_ON_COLUMN TEXT, '
          '$UPDATED_ON_COLUMN TEXT, '
          '$DEPLOYED_ON_COLUMN TEXT, '
          '$DEPLOYMENT_STATUS_COLUMN TEXT, '
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

    // listen to changes to the app task queue so we can save them
    AppTaskController().userTaskEvents.listen((task) => saveUserTask(task));

    info('$runtimeType - SQLite DB initialized - name: $databaseName');
  }

  /// Close the persistence layer. After close is called, no deployment can be
  /// accessed or saved.
  Future<void> close() async => await _database?.close();

  /// Get the list of all studies previously stored on this phone.
  ///
  /// Returns an empty list, if not study deployments are stored.
  Future<List<SmartphoneStudy>> getAllStudies() async {
    List<SmartphoneStudy> list = [];
    try {
      final List<Map<String, Object?>> maps =
          await _database?.query(
            STUDY_TABLE_NAME,
            columns: [
              STUDY_ID_COLUMN,
              STUDY_DEPLOYMENT_ID_COLUMN,
              DEVICE_ROLE_NAME_COLUMN,
              PARTICIPANT_ID_COLUMN,
              PARTICIPANT_ROLE_NAME_COLUMN,
              CREATED_ON_COLUMN,
              DEPLOYMENT_STATUS_COLUMN,
              DEPLOYMENT_COLUMN,
            ],
          ) ??
          [];
      if (maps.isNotEmpty) {
        for (var map in maps) {
          list.add(SmartphoneStudy.fromMap(map));
        }
      }
    } catch (exception) {
      warning('$runtimeType - Failed to load studies - $exception');
    }

    return list;
  }

  /// Save the [study] persistently to a local cache.
  /// Returns true if successful.
  Future<bool> saveStudy(Study study) async {
    bool success = true;
    try {
      final Map<String, dynamic> map = {
        STUDY_DEPLOYMENT_ID_COLUMN: study.studyDeploymentId,
        DEVICE_ROLE_NAME_COLUMN: study.deviceRoleName,
        PARTICIPANT_ID_COLUMN: '',
        PARTICIPANT_ROLE_NAME_COLUMN: '',
        CREATED_ON_COLUMN: study.createdOn.toUtc().toIso8601String(),
        UPDATED_ON_COLUMN: DateTime.now().toUtc().toIso8601String(),
        DEPLOYED_ON_COLUMN: study.deploymentStatus?.createdOn
            .toUtc()
            .toIso8601String(),
        DEPLOYMENT_STATUS_COLUMN: jsonEncode(study.deploymentStatus),
        DEPLOYMENT_COLUMN: jsonEncode(study.deployment),
      };

      if (study.deployment is SmartphoneDeployment) {
        final d = study.deployment as SmartphoneDeployment;
        map[PARTICIPANT_ID_COLUMN] = d.participantId;
        map[PARTICIPANT_ROLE_NAME_COLUMN] = d.participantRoleName;
      }

      await _database?.insert(
        STUDY_TABLE_NAME,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (exception) {
      success = false;
      warning('$runtimeType - Failed to save deployment - $exception');
    }
    return success;
  }

  /// Return the [SmartphoneStudy] with [studyDeploymentId] and [deviceRoleName],
  /// or null when no such study is found.
  Future<SmartphoneStudy?> getStudy(
    String studyDeploymentId,
    String deviceRoleName,
  ) async {
    SmartphoneStudy? study;
    try {
      final List<Map<String, Object?>> maps =
          await _database?.query(
            STUDY_TABLE_NAME,
            columns: [
              STUDY_ID_COLUMN,
              STUDY_DEPLOYMENT_ID_COLUMN,
              DEVICE_ROLE_NAME_COLUMN,
              PARTICIPANT_ID_COLUMN,
              PARTICIPANT_ROLE_NAME_COLUMN,
              CREATED_ON_COLUMN,
              DEPLOYMENT_STATUS_COLUMN,
              DEPLOYMENT_COLUMN,
            ],
            where:
                '$STUDY_DEPLOYMENT_ID_COLUMN = ? AND '
                '$DEVICE_ROLE_NAME_COLUMN = ?',
            whereArgs: [studyDeploymentId, deviceRoleName],
          ) ??
          [];

      if (maps.isNotEmpty) {
        study = SmartphoneStudy.fromMap(maps[0]);
      }
    } catch (exception) {
      warning('$runtimeType - Failed to restore deployment - $exception');
    }

    return study;
  }

  /// Remove the [study] from local cache.
  Future<void> removeStudy(Study study) async {
    final deploymentId = study.studyDeploymentId;
    final deviceRoleName = study.deviceRoleName;
    info("$runtimeType - Erasing study, deploymentId: $study");
    try {
      await _database?.delete(
        STUDY_TABLE_NAME,
        where:
            '$STUDY_DEPLOYMENT_ID_COLUMN = ? AND '
            '$DEVICE_ROLE_NAME_COLUMN = ?',
        whereArgs: [deploymentId, deviceRoleName],
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
            await _database?.update(
              TASK_QUEUE_TABLE_NAME,
              map,
              where: '$TASK_ID_COLUMN = ?',
              whereArgs: [task.id],
              conflictAlgorithm: ConflictAlgorithm.replace,
            ) ??
            0;

        if (count == 0) {
          await _database?.insert(
            TASK_QUEUE_TABLE_NAME,
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        break;
      case UserTaskState.dequeued:
        await _database?.delete(
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
          await _database?.query(
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
