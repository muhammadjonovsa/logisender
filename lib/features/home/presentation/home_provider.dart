import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logisender/core/di/providers.dart';
import 'package:logisender/features/home/data/home_repository.dart';
import 'package:logisender/features/home/domain/home_state.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;

  HomeNotifier(this._repository) : super(const HomeState());

  Future<void> loadData() async {
    try {
      final userName = await _repository.getMyFirstName();
      if (!mounted) return;
      state = state.copyWith(userName: userName ?? 'User');
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(userName: 'User');
    }
  }

  void toggleRunning() {
    state = state.copyWith(isRunning: !state.isRunning);
  }

  void incrementSent() {
    state = state.copyWith(
      todaySent: state.todaySent + 1,
      lastSentTime: DateTime.now(),
    );
  }

  void incrementError() {
    state = state.copyWith(todayErrors: state.todayErrors + 1);
  }

  void setFloodWait(bool hasWait) {
    state = state.copyWith(hasFloodWait: hasWait);
  }

  Future<void> refresh() async {
    await loadData();
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(homeRepositoryProvider));
});
