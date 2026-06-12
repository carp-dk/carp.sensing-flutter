import 'dart:convert';
import 'dart:io';

import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

/// Tests that a database created with CAMS 1.x is migrated to the 2.x schema
/// when the [PersistenceService] is initialized.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const deploymentId = '14cd5547-2fcd-4685-9b12-2d9e21b7b1d8';
  const roleName = 'phone';

  setUpAll(() {
    CarpMobileSensing.ensureInitialized();
  });

  test('1.x database is migrated to the 2.x schema', () async {
    final databaseName =
        '${await getDatabasesPath()}/${PersistenceService.DATABASE_NAME}.db';
    await deleteDatabase(databaseName);

    final deploymentJson = File(
      'test/json/cams_1.x_study_deployment.json',
    ).readAsStringSync();

    final snapshot = UserTaskSnapshot(
      '7fb3fd47-f61b-48c5-add2-39d4762bfc67',
      AppTask(type: 'survey', name: 'Task #1'),
      UserTaskState.enqueued,
      DateTime.now(),
      DateTime.now(),
      null,
      false,
      deploymentId,
      roleName,
    );

    // Create a database with the 1.x schema and content.
    var db = await openDatabase(
      databaseName,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE deployment ('
          'study_id TEXT, '
          'study_deployment_id TEXT PRIMARY KEY, '
          'device_role_name TEXT, '
          'participant_id TEXT, '
          'participant_role_name TEXT, '
          'deployment_status INTEGER, '
          'updated_at TEXT, '
          'deployed_at TEXT, '
          'deployment TEXT)',
        );
        await db.execute(
          'CREATE TABLE task_queue ('
          'id INTEGER PRIMARY KEY, '
          'study_deployment_id TEXT, '
          'task_id TEXT, '
          'task TEXT)',
        );
      },
    );
    await db.insert('deployment', {
      'study_id': 'study-1',
      'study_deployment_id': deploymentId,
      'device_role_name': roleName,
      'participant_id': 'participant-1',
      'participant_role_name': 'Participant',
      'deployment_status': 4,
      'updated_at': '2023-09-04T20:31:36.550766Z',
      'deployed_at': '2023-09-04T20:31:36.550766Z',
      'deployment': deploymentJson,
    });
    await db.insert('task_queue', {
      'study_deployment_id': deploymentId,
      'task_id': snapshot.id,
      'task': jsonEncode(snapshot),
    });
    await db.close();

    // Initializing the persistence service migrates the database.
    final persistence = PersistenceService();
    await persistence.init();

    final studies = await persistence.getAllStudies();
    expect(studies.length, 1);

    final study = studies.first;
    expect(study.studyId, 'study-1');
    expect(study.studyDeploymentId, deploymentId);
    expect(study.deviceRoleName, roleName);
    expect(study.participantId, 'participant-1');
    expect(study.participantRoleName, 'Participant');
    expect(study.deployment, isNotNull);
    expect(study.deployment!.deviceConfiguration.roleName, roleName);

    // Querying tasks per study requires the backfilled device role name.
    final tasks = await persistence.getUserTasks(study);
    expect(tasks.length, 1);
    expect(tasks.first.id, snapshot.id);
    expect(tasks.first.deviceRoleName, roleName);

    await persistence.close();

    // The 1.x deployment table is removed after migration.
    db = await openDatabase(databaseName);
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'deployment'",
    );
    expect(tables, isEmpty);
    await db.close();
  });
}
