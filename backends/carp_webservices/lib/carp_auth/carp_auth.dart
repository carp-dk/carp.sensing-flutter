import 'dart:async';
import 'package:carp_mobile_sensing/infrastructure.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

part 'oauth.dart';
part 'carp_user.dart';
part 'carp_auth.g.dart';
part 'carp_auth_properties.dart';
part 'carp_auth_service.dart';
