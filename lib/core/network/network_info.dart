import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstract class for network information
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Concrete implementation of NetworkInfo
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
