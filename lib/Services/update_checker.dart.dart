import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Screens/update_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get/get.dart';

class UpdateChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final url =
      Uri.parse("https://raw.githubusercontent.com/justaman045/Money_Control/master/app_version.json");

      final response = await http.get(url);

      if (response.statusCode == 404){
        debugPrint("Error with the Setup");
        return;
      } else if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body);

      debugPrint(data["latest_version"].toString());

      final latestVersion = data["latest_version"];
      final updateMessage = data["update_message"];
      final isForce = data["force"] ?? false;

      final package = await PackageInfo.fromPlatform();
      final currentVersion = package.version;

      if (_isNewerVersion(latestVersion, currentVersion)) {

        _showUpdateDialog(context, latestVersion, updateMessage, isForce);
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static bool _isNewerVersion(String remote, String local) {
    List<int> r = remote.split('.').map(int.parse).toList();
    List<int> l = local.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
      BuildContext context, String version, String message, bool force) {
    Get.dialog(
      barrierDismissible: !force,
      AlertDialog(
        title: Text("New Update Available (v$version)"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: !force ? () => Get.back() : null,
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              gotoPage(UpdatePage());
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }
}
