part of carp_study_generator;

class HelpCommand implements Command {
  static final String helpText =
      "Manage your CARP Mobile Sensing (CAMS) Study.\n\n"
      "Usage: flutter test carp/<command>\n\n"
      "Available commands:\n"
      " help \t\t Prints this help message.\n"
      " dryrun \t Test access to the CARP server and the syntax of the json resources.\n"
      " create \t Upload a new study protocol to the CARP server.\n"
      " update \t Update an existing study protocol as a new version.\n"
      " consent \t Upload the informed consent json file to the CARP server.\n"
      " localization \t Upload the localization files to the CARP server.\n"
      " message \t Upload the list of messages to the CARP server.\n"
      " delete-all \t Delete all messages on the CARP server.\n"
      "\n";

  HelpCommand() : super();

  @override
  Future execute() async => print(helpText);
}
