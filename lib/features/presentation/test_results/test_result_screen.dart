import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/features/presentation/test_results/test_result_bloc/test_result_bloc.dart';
import 'package:yiraclinics/features/presentation/test_results/widgets/ai_insites_widget.dart';
import 'package:yiraclinics/features/presentation/test_results/widgets/badge_widget.dart';
import 'package:yiraclinics/features/presentation/test_results/widgets/health_overview_card.dart';
import 'package:yiraclinics/features/presentation/test_results/widgets/quick_started_grid.dart';
import 'package:yiraclinics/features/presentation/test_results/widgets/test_result_card.dart';
import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_border_button.dart';
import '../../../core/constants/constants.dart';

class TestResultsScreen extends StatelessWidget {
  const TestResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (context) => TestResultsBloc()..add(LoadTestResults()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CommonAppBar(
        ),
        body: BlocConsumer<TestResultsBloc, TestResultsState>(
          builder: (context, state) {
            if (state is TestResultsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TestResultsLoaded) return _buildUI(context, state);
            return const SizedBox();
          },
          listener: (BuildContext context, TestResultsState state) {},
        ),
      ),
    );
  }

  Widget _buildUI(BuildContext context, TestResultsLoaded state) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              CommonText(
                "Test Results",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: appPoppinFont,
                  fontSize: displayWidth(context) * 0.045,
                ),
              ),
              CommonBorderButton(
                height: 35,
                icon: Icons.file_download_outlined,
                text: 'Download All',
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: fieldSpace),

          CommonText(
            "View your laboratory and diagnostic test results",
            style: TextStyle(
              color: Colors.grey,
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.03,
            ),
          ),
          const SizedBox(height: fieldSpace),
          HealthOverviewCard(state: state),
          const SizedBox(height: fieldSpace),
          _AIPoweredAnalysisSection(),
          const SizedBox(height: fieldSpace),
          QuickStatsGrid(state: state),
          const SizedBox(height: fieldSpace),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (val) {},
                    style: TextStyle(
                      decorationThickness: 0,
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context) * 0.03,
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: displayWidth(context) * 0.03,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      hintText: "Search test results...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.blueGrey,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: displayWidth(context) * 0.33,
                child: CommonDropdown(
                  title: "Filter by Status",
                  selectedValue: state.selectedStatus ?? "All",
                  options: const [
                    "All",
                    "Blood Tests",
                    "Urine Tests",
                    "Imaging",
                  ],
                  onSelected: (value) {
                    context.read<TestResultsBloc>().add(FilterByStatus(value));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: fieldSpace),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.labResults.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => ReusableTestCard(
              title: state.labResults[i]['title'],
              doctorName: state.labResults[i]['doctor'],
              date: state.labResults[i]['date'],
              parameters: List<String>.from(state.labResults[i]['params']),
              statusText: state.labResults[i]['status'],
              isAbnormal: state.labResults[i]['isAbnormal'],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _AIPoweredAnalysisSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.blue),
            title: CommonText(
              "AI Lab Analysis",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: displayWidth(context) * 0.034,
                fontFamily: appPoppinFont,
              ),
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                TestBadge(text: "AI-Powered", color: Colors.blue),
                TestBadge(text: "2 Urgent", color: Colors.red),
              ],
            ),
          ),
          AIInsightItem(
            title: "LDL cholesterol at 142 mg/dL (borderline high)",
            desc: "Discuss statin therapy with your cardiologist.",
            tag: "HIGH ACTION NEEDED",
            color: Colors.orange,
            val: "142",
          ),
          AIInsightItem(
            title: "HbA1c improved from 7.8% to 7.2%",
            desc: "Excellent progress on diabetes management.",
            tag: "LOW OPTIMIZATION",
            color: Colors.teal,
          ),
           Padding(
            padding: EdgeInsets.all(12),
            child: CommonText(
              "Ask MedAssist AI for more details",
              style: TextStyle(color: Colors.blue, fontSize: displayWidth(context)*0.028,fontFamily: appPoppinFont),
            ),
          ),
        ],
      ),
    );
  }
}
