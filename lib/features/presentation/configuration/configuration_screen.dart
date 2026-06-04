import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../core/constants/constants.dart';
import 'config_bloc.dart';

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ConfigBloc, ConfigState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: displayHeight(context)/5,),
                SizedBox(
                  height: displayHeight(context) * 0.35,
                  child: Lottie.asset(
                    'assets/json/ic_loader.json',
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  "Setting up your experience",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: appPoppinFont
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please wait while we sync your preferences",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey,fontFamily: appPoppinFont),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

}
