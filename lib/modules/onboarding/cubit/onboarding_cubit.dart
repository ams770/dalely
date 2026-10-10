import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/cubits/location/location_cubit.dart';
import '../../../shared/cubits/settings/settings_cubit.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required this.settingsCubit,
    required this.locationCubit,
  })  : pageController = PageController(),
        super(const OnboardingState());

  final SettingsCubit settingsCubit;
  final LocationCubit locationCubit;
  final PageController pageController;

  void onPageChanged(int index) {
    if (state.currentPage != index && !isClosed) {
      emit(state.copyWith(currentPage: index));
    }
  }

  void nextPage() {
    if (state.currentPage < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> allowLocationAndComplete() async {
    if (state.isCompleting) return;
    emit(state.copyWith(isCompleting: true));
    try {
      await locationCubit.requestPermission();
    } catch (_) {
      // Continue even if permission request fails
    }
    await settingsCubit.completeOnboarding();
  }

  Future<void> completeWithoutLocation() async {
    if (state.isCompleting) return;
    emit(state.copyWith(isCompleting: true));
    await settingsCubit.completeOnboarding();
  }

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}
