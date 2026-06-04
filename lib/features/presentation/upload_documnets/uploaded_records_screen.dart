import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/widgets/uploaded_record_card.dart';

import '../../../core/common_widgets/common_text.dart';
import '../../../di/dependency_injection.dart';


class UploadedRecordsScreen extends StatelessWidget {
  const UploadedRecordsScreen({super.key});

  final List<String> categories = const [
    'All',
    'Appointments',
    'General',
    'Self(Patient)',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider<UploadedBloc>(
      create: (context) => sl<UploadedBloc>()..add(FetchUploadedRecords()),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Builder(
            builder: (blocContext) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: screenHorizontalSpacePadding,
                  vertical: 0.0,
                ),
                child: Column(
                  children: [
                    BlocBuilder<UploadedBloc, UploadedBlocState>(
                      buildWhen: (previous, current) => previous.selectedCategory != current.selectedCategory || previous.allRecords != current.allRecords,
                      builder: (context, state) {
                        return SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = state.selectedCategory.toLowerCase() == cat.toLowerCase();

                              final labelText = cat.toLowerCase() == 'all'
                                  ? 'All (${state.allRecords.length})'
                                  : cat;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    blocContext.read<UploadedBloc>().add(
                                      FilterCategoryChanged(cat),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: screenHorizontalSpacePadding,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryColor
                                          : (isDark ? Colors.white10 : Colors.white),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : (isDark
                                            ? Colors.transparent
                                            : Colors.grey.shade300),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: CommonText(
                                      labelText,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                        fontWeight: FontWeight.w600,
                                        fontSize: displayWidth(context)*0.03,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: BlocBuilder<UploadedBloc, UploadedBlocState>(
                        builder: (context, state) {
                          if (state.status == UploadedStatus.loading) {
                            return const Center(
                              child: CircularProgressIndicator.adaptive(),
                            );
                          }
                          if (state.filteredRecords.isEmpty) {
                            return const Center(
                              child: CommonText(
                                "No files matches this selection criteria.",
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: state.filteredRecords.length,
                            itemBuilder: (context, index) {
                              final record = state.filteredRecords[index];
                              return UploadedRecordCard(
                                record: record,
                                onDelete: () {
                                  blocContext.read<UploadedBloc>().add(
                                    DeleteUploadedRecordItem(record.id),
                                  );

                                },
                                onDownload: (){}, onView: () {  },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}