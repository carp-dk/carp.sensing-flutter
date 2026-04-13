// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

void sensing() async {
  // create a new CAMS study protocol with an owner
  StudyProtocol protocol = StudyProtocol(
    ownerId: 'AB',
    name: 'patient_tracking',
    description: 'Track patient movement',
  );

  // define which devices are used for data collection
  // in this case, its only this smartphone
  Smartphone phone = Smartphone();

  protocol.addPrimaryDevice(phone);

  // add selected measures from the sampling packages
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
      measures: [
        Measure(type: SensorSamplingPackage.ACCELERATION),
        Measure(type: SensorSamplingPackage.ROTATION),
        Measure(type: DeviceSamplingPackage.FREE_MEMORY),
        Measure(type: DeviceSamplingPackage.BATTERY_STATE),
        Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
        Measure(type: SensorSamplingPackage.STEP_EVENT),
        Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
      ],
    ),
    phone,
    Control.Start,
  );

  var invitation = ParticipantInvitation(
    participantId: const Uuid().v1,
    assignedRoles: AssignedTo.all(),
    identity: EmailAccountIdentity("test@test.com"),
    invitation: StudyInvitation(
      "Movement study",
      "This study tracks your movements.",
    ),
  );

  // deploy this protocol using the on-phone deployment service
  StudyDeploymentStatus status = await SmartphoneDeploymentService()
      .createStudyDeployment(protocol, [invitation]);

  // create and configure a client manager for this phone
  SmartPhoneClientManager client = SmartPhoneClientManager();
  await client.configure();

  // add the study and get the study runtime (controller)
  final study = await client.addStudy(
    SmartphoneStudy(
      studyDeploymentId: status.studyDeploymentId,
      deviceRoleName: phone.roleName,
    ),
  );
  await client.tryDeployment(study.studyDeploymentId, study.deviceRoleName);

  SmartphoneStudyController? controller = client.getStudyController(study);
  controller?.resume();

  // listening on the data stream and print them as json to the debug console
  controller?.measurements.listen((data) => print(toJsonString(data)));

  // subscribe to events
  controller?.measurements.listen((Measurement measurement) {
    // do something w. the data, e.g. print the json
    print(const JsonEncoder.withIndent(' ').convert(measurement));
  });

  // listening on events of a specific type
  controller
      ?.measurementsByType(DeviceSamplingPackage.SCREEN_EVENT)
      .forEach(print);
}
