# CARP Study Generator Utility Package

This utility package helps generate the configuration files needed for a CARP Mobile Sensing study, and uploading this to the CARP web server (CAWS).

## Configuration and Setup

To use the study generator, do the following in you app:

1. Include [`carp_study_generator`](https://pub.dev/packages/carp_study_generator) and [`test`](https://pub.dev/packages/test) as part of the `dev_dependencies` in the `pubspec.yaml` file.
1. Copy the folder `carp` to the root of you project.
1. Configure `carpspec.yaml`, and the json files `protocol.json`, `consent.json`, and the message and language json files (`en.json`, etc.).

## Configuration of `carpspec.yaml`

The `carpspec.yaml` can be configured using the following properties for:

* the CARP Server
* the study ID
* the protocol
* the consent document
* messages
* language localizations

```yaml
# configuration of the CARP server URI and the user credentials who uploads this study
server:
  uri: https://dev.carp.dk
  username: xxx@xxx.dk
  password: xxx  

# configuration of the study ID - used for upload of informed consent and translations
study:
  study_id: 75b95ab5-bfc8-48ce-a5d4-d11b228ca74b

# configuration of the local path to the protocol, consent document, messages, 
# and localization files to be uploaded
protocol:
  path: carp/resources/protocol.json

consent:
  path: carp/resources/consent.json

message:
  path: carp/messages/
  # list the messages to be uploaded
  # add each message as a <name>.json file in the [path] folder
  messages:
    - 1
    - 2

localization:
  path: carp/lang/
  # list the locales supported
  # for each locale, add a <locale>.json file in the [path] folder
  locales:
    - en
    - da
```

> [!WARNING]
> Note that the `carpspec.yaml` file contains username and password in clear text and hence **SHOULD NOT BE ADDED TO VERSION CONTOL** - add it to `.gitignore`.

## File Structure

All files used for creating and uploading configurations to CARP is stored in the `carp` folder in the root of your (app) project file. The name of the json files to upload is specified in the `carpspec.yaml` file (see above). The default file structure is:

| File                      |   Description |
|---------------------------|---------------|
| `resources/protocol.json` | JSON definition of your [`SmartphoneStudyProtocol`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/SmartphoneStudyProtocol-class.html). |  
| `resources/consent.json`  | JSON definition of your [`RPOrderedTask`](https://pub.dev/documentation/research_package/latest/model/RPOrderedTask-class.html) with the informed consent to show to the user. |
| `lang/<language>.json`    | The JSON language file for each language supported of the form `<language>.json`. |
| `messages/<name>.json`    | The name of each JSON message file to upload. |

Please ignore the test scripts in the `carp` folder (these are used to execute the commands).

## Usage

Each command is run like this:

```bash
flutter test carp/<command>
```

The available commands are:

```
 help            Prints this help message.
 dry-run         Test access to the CARP server and the syntax of the json resources.
 create          Upload a new study protocol to the CARP server.
 update          Update an existing study protocol as a new version.
 consent         Upload the consent document json file to the CARP server.
 localization    Upload the localization files to the CARP server.
 message         Upload the list of messages to the CARP server.
 delete-all      Delete all messages on the CARP server.
```

Before uploading a any json files to CARP, run the `dry-run` command first. It will check and output a list like the following:

```
[✓] CARP App             CarpApp - name: CAWS @ DTU, uri: https://dev.carp.dk
[✓] Authenticated        username: xxx@xxx.xx
[✓] Protocol path        carp/resources/protocol.json
[✓] Protocol parse       name: CAMS App - Demo Study Protocol
[✓] Consent path         carp/resources/consent.json
[✓] Consent              identifier: consentTaskID
[✓] Locale - en          carp/lang/en.json
[✓] Locale - da          carp/lang/da.json
[✓] Message - 1          carp/messages/1.json
[✓] Message - 2          carp/messages/2.json
 •  No issues found!
 ```
