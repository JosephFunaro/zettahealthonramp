import 'dart:async';
import 'dart:convert';
import 'package:universal_html/html.dart' as http;

List<String> updateResponse = ["nan"];
dynamic responseBody;

class Connections {
  List<Map<String, dynamic>> asClient;
  List<Map<String, dynamic>> asServer;

  Connections({
    required this.asClient,
    required this.asServer,
  });

  // Factory method to initialize an empty object
  factory Connections.empty() {
    return Connections(
      asClient: [],
      asServer: [],
    );
  }

  // Method to add a new entry to "AsClient"
  void addClientEntry(String guid, bool success, String message) {
    // Check if GUID already exists
    if (!asClient.any((entry) => entry['ServerClientGUID'] == guid)) {
      asClient.add({
        "ServerClientGUID": guid,
        "Success": success,
        "Message": message,
      });
    }
  }

  // Method to add a new entry to "AsServer"
  void addServerEntry(String guid, String clientDataKeys, String message) {
    // Check if GUID already exists
    if (!asServer.any((entry) => entry['ServiceGUID'] == guid)) {
      asServer.add({
        "ServiceGUID": guid,
        "ClientDataKeys": clientDataKeys,
        "Success": true,
        "Message": message,
      });
    }
  }

  // Method to update success status
  void updateSuccess(String guid, bool success, bool isClient, String message) {
    List<Map<String, dynamic>> listToUpdate = isClient ? asClient : asServer;

    for (var entry in listToUpdate) {
      if ((isClient && entry['ServerClientGUID'] == guid) ||
          (!isClient && entry['ServiceGUID'] == guid)) {
        entry['Success'] = success;
        entry['Message'] = message;
        break;
      }
    }
  }

  bool entryExists(String guid, {bool isClient = true}) {
    List<Map<String, dynamic>> listToCheck = isClient ? asClient : asServer;
    return listToCheck.any((entry) =>
        (isClient && entry['ServerClientGUID'] == guid) ||
        (!isClient && entry['ServiceGUID'] == guid));
  }

  // Convert to JSON string
  String toJson() {
    return jsonEncode({
      "AsClient": asClient,
      "AsServer": asServer,
    });
  }
}

Future<void> httpCall(String message, Connections payload) async {
  var req = http.HttpRequest();
  // post to our localhost port. message will be sent over npt to the localhost port
  // on the listener and then to our API call
  req.open('post', 'http://localhost:4100');
  req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
  req.send("$message;${json.encode(payload.toJson())}");

  // Create a Completer that will complete when the request finishes
  Completer<void> completer = Completer<void>();

  req.onReadyStateChange.listen((_) async {
    //print("Response Text: ${req.responseText}");
    //print("Response Status: ${req.status}");
    if (req.readyState == http.HttpRequest.DONE &&
        (req.status == 200 || req.status == 0)) {
      String responsefromserver = req.responseText ?? "";
      // split up response message into its respective parts
      if (responsefromserver.startsWith("true") ||
          responsefromserver.startsWith("false")) {
        updateResponse = responsefromserver.split(";");
        completer.complete();
      } else {
        updateResponse = ["nan"];
        responseBody = responsefromserver;
        completer.complete();
      }
    }
  });
  return completer.future;
}
