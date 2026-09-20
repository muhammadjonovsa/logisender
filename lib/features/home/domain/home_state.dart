import 'package:equatable/equatable.dart';

/// Dashboard home state.
class HomeState extends Equatable {
  final bool isRunning;
  final int todaySent;
  final int todayErrors;
  final bool hasFloodWait;
  final DateTime? lastSentTime;
  final String? userName;

  const HomeState({
    this.isRunning = false,
    this.todaySent = 0,
    this.todayErrors = 0,
    this.hasFloodWait = false,
    this.lastSentTime,
    this.userName,
  });

  HomeState copyWith({
    bool? isRunning,
    int? todaySent,
    int? todayErrors,
    bool? hasFloodWait,
    DateTime? lastSentTime,
    String? userName,
  }) {
    return HomeState(
      isRunning: isRunning ?? this.isRunning,
      todaySent: todaySent ?? this.todaySent,
      todayErrors: todayErrors ?? this.todayErrors,
      hasFloodWait: hasFloodWait ?? this.hasFloodWait,
      lastSentTime: lastSentTime ?? this.lastSentTime,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props =>
      [isRunning, todaySent, todayErrors, hasFloodWait, lastSentTime, userName];
}
