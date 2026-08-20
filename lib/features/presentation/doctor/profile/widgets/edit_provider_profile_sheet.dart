import 'package:flutter/material.dart';
import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';
import '../edit_provider_profile_screen.dart';
import '../provider_profile_bloc/provider_profile_bloc.dart';

/// Backward-compatible router to full-screen EditProviderProfileScreen
class EditProviderProfileSheet {
  static Future<void> show(BuildContext context, ProviderProfileEntity profile, ProviderProfileBloc bloc) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProviderProfileScreen(profile: profile, bloc: bloc),
      ),
    );
  }
}
