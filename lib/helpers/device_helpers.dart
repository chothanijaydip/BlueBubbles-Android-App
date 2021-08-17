import 'dart:ui';

import 'package:flutter/widgets.dart';

enum DeviceType { Phone, Tablet }

DeviceType getDeviceType() {
  SingletonFlutterWindow? window = WidgetsBinding.instance?.window;
  if (window == null) return DeviceType.Phone;
  final data = MediaQueryData.fromWindow(window);
  return data.size.shortestSide < 550 ? DeviceType.Phone : DeviceType.Tablet;
}
