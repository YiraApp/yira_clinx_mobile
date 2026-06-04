
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/presentation/close_account/widgets/close_account_header.dart';
import 'package:yiraclinics/features/presentation/close_account/widgets/close_action_button.dart';
import 'package:yiraclinics/features/presentation/close_account/widgets/confirmation_code_section.dart';
import 'package:yiraclinics/features/presentation/close_account/widgets/terms_and_conditions_check_box.dart';
import 'package:yiraclinics/features/presentation/close_account/widgets/unsynced_dialogue.dart';

import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/constants/constants.dart';
import 'close_account_bloc/close_account_bloc.dart';

class CloseAccountScreen extends StatefulWidget {
  const CloseAccountScreen({super.key});

  @override
  State<CloseAccountScreen> createState() => _CloseAccountScreenState();
}

class _CloseAccountScreenState extends State<CloseAccountScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);

    return BlocProvider(
      create: (context) => CloseAccountBloc()..add(const InitializeCloseAccountEvent()),
      child: BlocConsumer<CloseAccountBloc, CloseAccountState>(
        listener: (context, state) {
          if (state.hasUnsyncedData && state.status == CloseAccountStatus.initial) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => UnSyncedDataDialog(
                onSyncAndClose: () => context.read<CloseAccountBloc>().add(const SyncAndCloseAccountEvent()),
                onForceClose: () => context.read<CloseAccountBloc>().add(const ForceCloseAccountEvent()),
              ),
            );
          }

          if (state.status == CloseAccountStatus.success) {
            Navigator.pushReplacementNamed(context, '/successfully_deleted_screen');
          }

          if (state.status == CloseAccountStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<CloseAccountBloc>();

          return PopScope(
            canPop: state.status != CloseAccountStatus.submitting,
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  onPressed: state.status == CloseAccountStatus.submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    size: 20,
                  ),
                ),
                actions: [

                ],
              ),
              bottomNavigationBar: CloseAccountButtonSection(
                isSubmitting: state.status == CloseAccountStatus.submitting,
                isButtonEnabled: state.isCodeValid && state.isTCOnchecked,
                onConfirmTap: () => bloc.add(const SubmitCloseAccountEvent()),
                onCancelTap: () => Navigator.of(context).pop(),
              ),
              body: SafeArea(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenHorizontalSpacePadding,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CloseAccountHeader(),
                        SizedBox(height: displayHeight(context) * 0.06),
                        ConfirmationCodeSection(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          generatedCode: state.generatedVerificationCode,
                          onChanged: (value) {
                            bloc.add(ConfirmationCodeChangedEvent(value));
                          },
                        ),
                        const SizedBox(height: 20),
                        TermsAndPrivacyCheckbox(
                          isChecked: state.isTCOnchecked,
                          onChanged: (checked) {
                            bloc.add(ToggleTermsCheckboxEvent(isChecked: checked ?? false));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}