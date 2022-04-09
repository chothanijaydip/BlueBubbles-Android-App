import 'dart:async';

import 'package:bluebubbles/helpers/logger.dart';
import 'package:get/get.dart';
import 'package:tuple/tuple.dart';

enum SyncStatus { IDLE, IN_PROGRESS, STOPPING, COMPLETED_SUCCESS, COMPLETED_ERROR }

abstract class SyncManager {
  String name;

  /// The current status of the sync
  Rx<SyncStatus> status = SyncStatus.IDLE.obs;

  /// If the sync errors out, this will be filled
  String? error;

  /// The current progress of the sync
  RxDouble progress = 0.0.obs;

  /// When the sync started
  DateTime? startedAt;

  /// When the sync ended
  DateTime? endedAt;

  /// So we can track the progress of the
  Completer<void>? completer;

  // Store any log output here
  RxList<Tuple2<LogLevel, String>> output = <Tuple2<LogLevel, String>>[].obs;

  SyncManager(this.name);

  /// Start the sync
  Future<void> start() async {
    if (completer != null && !completer!.isCompleted) {
      return completer!.future;
    } else {
      completer = Completer<void>();
    }

    startedAt = DateTime.now().toUtc();
    progress.value = 0.0;
    error = null;

    Logger.info('$name Sync is starting...', tag: 'SyncManager');
  }

  Future<void> stop() async {
    if (completer != null && !completer!.isCompleted) {
      status.value = SyncStatus.STOPPING;
      await completer!.future;
    }

    completeWithError('$name Sync was force stopped');
  }

  void setProgress(int amount, int total) {
    if (total <= 0) {
      progress.value = 0.0;
    } else if (amount >= total) {
      progress.value = 1.0;
    } else {
      progress.value = double.parse((amount / total).toStringAsFixed(2));
    }
  }

  void addToOutput(String log, {LogLevel level = LogLevel.INFO}) {
    output.add(Tuple2(level, log));

    if (level == LogLevel.ERROR) {
      Logger.error(log, tag: "SyncManager");
    } else if (level == LogLevel.WARN) {
      Logger.warn(log, tag: "SyncManager");
    } else {
      Logger.info(log, tag: "SyncManager");
    }
  }

  void complete() {
    if (completer != null && !completer!.isCompleted) {
      completer!.complete();
    }

    progress.value = 0.0;
    status.value = SyncStatus.COMPLETED_SUCCESS;
    endedAt = DateTime.now().toUtc();
    Logger.info(
        '$name Sync has completed. Elapsed Time: ${endedAt!.millisecondsSinceEpoch - startedAt!.millisecondsSinceEpoch} ms',
        tag: 'SyncManager');
  }

  void completeWithError(String errorMessage) {
    if (completer != null && !completer!.isCompleted) {
      completer!.completeError(errorMessage);
    }

    progress.value = 0.0;
    error = errorMessage;
    status.value = SyncStatus.COMPLETED_ERROR;
    endedAt = DateTime.now().toUtc();
    Logger.error(
        '$name Sync has errored! Elapsed Time: ${endedAt!.millisecondsSinceEpoch - startedAt!.millisecondsSinceEpoch} ms',
        tag: 'SyncManager');
    Logger.error('$name Sync Error: $error', tag: 'SyncManager');
  }
}
