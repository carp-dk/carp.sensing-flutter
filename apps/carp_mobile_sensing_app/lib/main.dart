import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_connectivity_package/connectivity.dart';
import 'package:carp_esense_package/esense.dart';
import 'package:carp_polar_package/carp_polar_package.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_audio_package/media.dart';
import 'package:carp_communication_package/communication.dart';
import 'package:carp_apps_package/apps.dart';
// import 'package:movisens_flutter/movisens_flutter.dart';
import 'package:carp_movisens_package/carp_movisens_package.dart';
import 'package:carp_health_package/health_package.dart';
import 'package:health/health.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';
// import 'package:carp_cortrium_package/carp_cortrium_package.dart';

import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'config.dart';

part 'src/app.dart';
part 'src/blocs/sensing.dart';
part 'src/view_models/probe_view_model.dart';
part 'src/view_models/device_view_model.dart';
part 'src/view_models/probe_descriptions.dart';
part 'src/view_models/device_descriptions.dart';
part 'src/view_models/study_deployment_view_model.dart';
part 'src/blocs/sensing_bloc.dart';
part 'src/blocs/carp_backend.dart';
part 'src/blocs/local_study_protocol_manager.dart';
part 'src/views/probe_list_page.dart';
part 'src/views/device_list_page.dart';
part 'src/views/study_deployment_page.dart';
part 'src/views/cachet_colors.dart';

void main() async {
  // Makes sure to have an instance of the WidgetsBinding, which is required
  // to use platform channels to call native code
  // See https://stackoverflow.com/questions/63873338/what-does-widgetsflutterbinding-ensureinitialized-do/63873689
  WidgetsFlutterBinding.ensureInitialized();

  // Make sure to initialize CAMS incl. json serialization
  CarpMobileSensing.ensureInitialized();

  // Initialize the bloc, setting the deployment mode.
  await bloc.initialize(
    deploymentMode: DeploymentMode.dev,
    useCachedStudyDeployment: false,
    resumeSensingOnStartup: false,
  );

  runApp(App());
}

final bloc = SensingBLoC();
