import 'dart:async';

import 'package:aws402_flutter/watch/watch_client.dart';
import 'package:flutter/material.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

class WatchConnectionService with WidgetsBindingObserver{
  final WatchConnectivity _watch = WatchConnectivity();
  final _connectionController = StreamController<bool>.broadcast();

  Timer? _pollingTimer;
  bool _lastKnownStatus = false;

  Stream<bool> get connectionStream => _connectionController.stream.distinct();

  bool get currentStatus => _lastKnownStatus;

  void startMonitoring({Duration interval = const Duration(seconds: 5)}){
    WidgetsBinding.instance.addObserver(this);
    _checkConnection();

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_){
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    try{
      debugPrint('${DateTime.now()} 워치 모니터링...');
      final isPaired = await _watch.isPaired;
      final isReachable = isPaired ? await _watch.isReachable : false;
      debugPrint('isPaired : $isPaired, isReachable : $isReachable');
      if(isPaired){
        if(isReachable){
          WatchClient.instance.reportConnection(WatchConnection.connected);
        }else{
          WatchClient.instance.reportConnection(WatchConnection.disconnected);
        }
      }else{
          WatchClient.instance.reportConnection(WatchConnection.disconnected);
      }
      if(_lastKnownStatus != isReachable) {
        _lastKnownStatus = isReachable;
        _connectionController.add(isReachable);
      }
    }catch (e){
      debugPrint(e.toString());
      WatchClient.instance.reportConnection(WatchConnection.disconnected);
      if(_lastKnownStatus != false){
        _lastKnownStatus = false;
        _connectionController.add(false);
      }
    }


  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.resumed){
      _checkConnection();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _connectionController.close();
  }
}
