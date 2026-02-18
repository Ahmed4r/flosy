import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flosy/core/custome_alert.dart';
import 'package:flutter/widgets.dart';

class NetworkCheck {
  Future<bool> checkNetwork(BuildContext context) async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());

    // This condition is for demo purposes only to explain every connection type.
    // Use conditions which work for your requirements.
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      log('Mobile network available');
      return true;
      // Mobile network available.
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      log('Wi-Fi connection available');
      return true;
      // Wi-fi is available.
      // Note for Android:
      // When both mobile and Wi-Fi are turned on system will return Wi-Fi only as active network type
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      // No available network types
      CustomAlert.show(
        context,
        title: "No Network",
        body: "Please check your internet connection.",
      );
    }
    return false;
  }
}
