import 'package:flutter/services.dart';

import '../models/models.dart';

/// Reads the device SMS inbox through a native MethodChannel (Android only).
class SmsService {
  static const _channel = MethodChannel('pa_app/sms');

  Future<List<SmsItem>> getInbox({int limit = 500}) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getInboxSms',
        {'limit': limit},
      );
      if (result == null) return [];
      return result
          .map((e) => SmsItem.fromChannel(e as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }
}
