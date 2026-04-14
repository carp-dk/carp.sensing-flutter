/// A library containing utilities for managing CARP Mobile Sensing studies, including generating and uploading:
/// * a study protocol
/// * informed consent
/// * translation files (localization)
/// * messages and news articles
library;

import 'dart:async';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:carp_apps_package/apps.dart';
import 'package:carp_communication_package/communication.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_audio_package/media.dart';
import 'package:carp_survey_package/survey.dart';
import 'package:carp_health_package/health_package.dart';
import 'package:carp_esense_package/esense.dart';
import 'package:carp_polar_package/carp_polar_package.dart';

import 'package:research_package/research_package.dart';
import 'package:cognition_package/model.dart';

part 'cmd/command.dart';
part 'cmd/help.dart';
part 'cmd/create.dart';
part 'cmd/update.dart';
part 'cmd/consent.dart';
part 'cmd/localization.dart';
part 'cmd/dry_run.dart';
part 'cmd/messages.dart';
part 'cmd/delete_all_messages.dart';
