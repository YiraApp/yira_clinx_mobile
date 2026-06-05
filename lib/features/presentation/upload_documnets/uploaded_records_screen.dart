import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/widgets/upload_record_fab.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/widgets/uploaded_record_card.dart';
import '../../../core/common_widgets/common_text.dart';

class UploadedRecordsScreen extends StatefulWidget {
  const UploadedRecordsScreen({super.key});

  @override
  State<UploadedRecordsScreen> createState() => _UploadedRecordsScreenState();
}

class _UploadedRecordsScreenState extends State<UploadedRecordsScreen> {
  final List<String> categories = const [
    'All',
    'Appointments',
    'General',
    'Self(Patient)',
  ];

  @override
  void initState() {
    super.initState();
    context.read<UploadedBloc>().add(FetchUploadedRecords());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<UploadedBloc, UploadedBlocState>(
      buildWhen: (previous, current)=> current is! UploadRecordScreenNavState,
      listener: (context, state) {
        if(state is UploadRecordScreenNavState){
          Navigator.pushNamed(context, AppRoutes.uploadRecordScreen);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          floatingActionButton: UploadRecordFab(
            onDocumentUploaded: () {
              context.read<UploadedBloc>().add(UploadRecordScreenNavEvent());
            },
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: screenHorizontalSpacePadding,
                vertical: 0.0,
              ),
              child: Column(
                children: [
                  _buildCategoryFilter(context, state),
                  const SizedBox(height: 20),
                  Expanded(child: _buildRecordsList(context, state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter(BuildContext context, UploadedBlocState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected =
              state.selectedCategory.toLowerCase() == cat.toLowerCase();
          final labelText = cat.toLowerCase() == 'all'
              ? 'All (${state.allRecords.length})'
              : cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                context.read<UploadedBloc>().add(FilterCategoryChanged(cat));
              },
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: screenHorizontalSpacePadding,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white10 : Colors.white),
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? Colors.transparent : Colors.grey.shade300),
                  ),
                ),
                alignment: Alignment.center,
                child: CommonText(
                  labelText,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.w600,
                    fontSize: displayWidth(context) * 0.03,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, UploadedBlocState state) {
    if (state.status == UploadedStatus.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (state.filteredRecords.isEmpty) {
      return const Center(
        child: CommonText("No files matches this selection criteria."),
      );
    }

    return ListView.builder(
      itemCount: state.filteredRecords.length,
      itemBuilder: (context, index) {
        final record = state.filteredRecords[index];
        return UploadedRecordCard(
          record: record,
          onDelete: () {
            context.read<UploadedBloc>().add(
              DeleteUploadedRecordItem(record.id),
            );
          },
          onDownload: () {},
          onView: () {},
        );
      },
    );
  }
}
