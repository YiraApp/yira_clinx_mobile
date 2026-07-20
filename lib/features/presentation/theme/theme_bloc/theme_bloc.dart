import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../use_cases/cached_theme_use_case.dart';
import '../../../use_cases/get_theme_use_case.dart';

part 'theme_event.dart';
part 'theme_state.dart';


class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final GetThemeUseCase getThemeUseCase;
  final CacheThemeUseCase cacheThemeUseCase;

  ThemeBloc({
    required this.getThemeUseCase,
    required this.cacheThemeUseCase,
  }) : super(const ThemeState(ThemeMode.system)) {

    on<LoadThemeEvent>((event, emit) async {
      final themeMode = await getThemeUseCase();
      emit(ThemeState(themeMode));
    });

    on<SetThemeEvent>((event, emit) async {
      emit(ThemeState(event.themeMode));
      await cacheThemeUseCase(event.themeMode);
    });
  }
}