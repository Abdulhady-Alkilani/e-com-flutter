import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/api/api_client.dart';

class ConfigProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  String _ipAddress = ApiConstants.defaultIp;
  String _port = ApiConstants.defaultPort;

  String get ipAddress => _ipAddress;
  String get port => _port;
  String get baseUrl => 'http://$_ipAddress:$_port/api';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _ipAddress = _prefs.getString('server_ip') ?? ApiConstants.defaultIp;
    _port = _prefs.getString('server_port') ?? ApiConstants.defaultPort;
    _updateApiClient();
    notifyListeners();
  }

  Future<void> setNetworkConfig(String ip, String port) async {
    _ipAddress = ip;
    _port = port;
    await _prefs.setString('server_ip', ip);
    await _prefs.setString('server_port', port);
    _updateApiClient();
    notifyListeners();
  }

  void _updateApiClient() {
    ApiClient.instance.updateBaseUrl(baseUrl);
  }
}
