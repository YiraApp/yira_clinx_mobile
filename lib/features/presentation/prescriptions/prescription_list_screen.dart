import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/prescription_record_fab.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/single_prescription_card.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../di/dependency_injection.dart';

class PrescriptionListScreen extends StatelessWidget {
  const PrescriptionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
final bool isTab= isTablet(context);
    return BlocProvider(
      create: (context) => sl<PrescriptionBloc>()..add(LoadPrescriptionData()),
      child: SafeArea(
        child: BlocConsumer<PrescriptionBloc, PrescriptionState>(
          buildWhen: (previous, current) =>
              current is! AddPrescriptionRecordNavState ||
              current is! SinglePrescriptionDetailsNavState,
          listener: (context, state) {
            if (state is AddPrescriptionRecordNavState) {
              Navigator.pushNamed(context, AppRoutes.addPrescriptionScreen);
            } else if (state is SinglePrescriptionDetailsNavState) {
              Navigator.pushNamed(
                context,
                AppRoutes.prescriptionViewDetailsScreen,
              );
            }
          },
          builder: (context, state) {
            if (state.status == PrescriptionStatus.loading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (state.medications.isEmpty && state.diagnoses.isEmpty) {
              return Center(
                child: CommonText(
                  'No prescriptions records found.',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.035,
                    color: Colors.grey,
                  ),
                ),
              );
            }
            final prescriptionItems = [
              {
                'title': state.diagnoses.isNotEmpty
                    ? state.diagnoses.last
                    : 'Index hypermetropia',
                'subtitle':
                    '${state.diagnoses.isNotEmpty ? state.diagnoses.last : 'Index hypermetropia'} • 1 medication',
                'date': 'JUN 03, 2026',
              },
              {
                'title': state.diagnoses.join(', ').isNotEmpty
                    ? state.diagnoses.join(', ')
                    : 'Hyperoxia, Hypermetropia',
                'subtitle': state.diagnoses.join(', ').isNotEmpty
                    ? '${state.diagnoses.join(', ')} • ${state.medications.length} medications'
                    : 'Hyperoxia, Hypermetropia • 3 medications',
                'date': 'JUN 03, 2026',
              },
            ];

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              floatingActionButton: PrescriptionRecordFab(
                onAddRecordTapped: () {
                  context.read<PrescriptionBloc>().add(
                    AddPrescriptionRecordNavEvent(),
                  );
                },
              ),
              body: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: prescriptionItems.length,
                itemBuilder: (context, index) {
                  final itemData = prescriptionItems[index];

                  return SinglePrescriptionCard(
                    title: itemData['title']!,
                    subtitle: itemData['subtitle']!,
                    date: itemData['date']!,
                    onEdit: () {},
                    onDelete: () {},
                    onView: () {
                      context.read<PrescriptionBloc>().add(
                        SinglePrescriptionDetailsNavEvent(),
                      );
                    },
                    isTab:isTab
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
