part of '../carp_study_generator.dart';

class MessagesCommand extends AbstractCommand {
  MessagesCommand() : super();

  String getMessageJson(String id) =>
      File('$messagesPath$id.json').readAsStringSync();

  @override
  Future<void> execute() async {
    await authenticate();

    for (var element in messageIds) {
      String id = element.toString();
      Message message = Message.fromJson(
        json.decode(getMessageJson(id)) as Map<String, dynamic>,
      );

      await CarpResourceManager().setMessage(message);
      print("Uploaded message '$id' - id: '${message.id}'");
    }
  }
}
