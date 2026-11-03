import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/features/data/models/diet/patient_diet_plan_model.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_image.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

/// Minutes after midnight for a time like "08:30 AM"; unknown times sort last.
int dietSlotMinutes(String? time) {
  final match = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(time ?? '');
  if (match == null) return 24 * 60;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)?.toUpperCase();
  if (period == 'PM' && hour < 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return hour * 60 + minute;
}

/// One meal (Breakfast, Lunch…) of one plan day, in time order.
class DietPreviewSlot {
  final String name;
  final String time;
  final List<TodayDietMealItem> items;
  const DietPreviewSlot(this.name, this.time, this.items);

  int get calories => items.fold(0, (sum, m) => sum + m.effectiveCalories);
}

List<DietPreviewSlot> dietSlotsForDay(List<TodayDietMealItem> meals, int day) {
  final bySlot = <String, List<TodayDietMealItem>>{};
  for (final m in meals.where((m) => m.dayNumber == day)) {
    bySlot.putIfAbsent(m.mealSlot, () => []).add(m);
  }
  return bySlot.entries.map((e) => DietPreviewSlot(e.key, e.value.first.mealTime ?? '', e.value)).toList()
    ..sort((a, b) => dietSlotMinutes(a.time).compareTo(dietSlotMinutes(b.time)));
}

/// How long a plan runs, e.g. "31 days"; null for a plan with no end date.
int? dietPlanLengthDays(String? startDate, String? endDate) {
  final start = DateTime.tryParse(startDate ?? '');
  final end = DateTime.tryParse(endDate ?? '');
  if (start == null || end == null) return null;
  final days = DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays + 1;
  return days < 1 ? 1 : days;
}

/// Food names in the order they appear in the plan, without repeats.
List<String> dietUniqueFoods(List<TodayDietMealItem> meals) {
  final seen = <String>{};
  final names = <String>[];
  final ordered = [...meals]
    ..sort((a, b) {
      final byDay = a.dayNumber.compareTo(b.dayNumber);
      return byDay != 0 ? byDay : dietSlotMinutes(a.mealTime).compareTo(dietSlotMinutes(b.mealTime));
    });
  for (final m in ordered) {
    final name = m.foodName.trim();
    if (name.isNotEmpty && seen.add(name.toLowerCase())) names.add(name);
  }
  return names;
}

/// A read-only look at everything in a plan: how long it runs, and every
/// food of every day, grouped by meal.
class DietPlanPreviewSheet extends StatefulWidget {
  final PatientDietPlanSummary plan;
  final List<TodayDietMealItem> meals;
  final VoidCallback? onOpen;

  const DietPlanPreviewSheet({super.key, required this.plan, required this.meals, this.onOpen});

  static Future<void> show(
    BuildContext context, {
    required PatientDietPlanSummary plan,
    required List<TodayDietMealItem> meals,
    VoidCallback? onOpen,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DietPlanPreviewSheet(plan: plan, meals: meals, onOpen: onOpen),
    );
  }

  @override
  State<DietPlanPreviewSheet> createState() => _DietPlanPreviewSheetState();
}

class _DietPlanPreviewSheetState extends State<DietPlanPreviewSheet> {
  int _day = 1;
  static final DateFormat _date = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = widget.plan;
    final days = [
      for (var d = 1; d <= (plan.totalDays < 1 ? 1 : plan.totalDays); d++) d,
    ];
    final length = dietPlanLengthDays(plan.startDate, plan.endDate);
    final start = DateTime.tryParse(plan.startDate ?? '');
    final end = DateTime.tryParse(plan.endDate ?? '');
    final slots = dietSlotsForDay(widget.meals, _day);
    final dayItems = [for (final s in slots) ...s.items];
    final dayKcal = dayItems.fold<int>(0, (sum, m) => sum + m.effectiveCalories);
    final protein = dayItems.fold<double>(0, (sum, m) => sum + (m.proteinG ?? 0));
    final carbs = dayItems.fold<double>(0, (sum, m) => sum + (m.carbsG ?? 0));
    final fat = dayItems.fold<double>(0, (sum, m) => sum + (m.fatG ?? 0));
    final foods = dietUniqueFoods(widget.meals);

    Widget fact(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: DietUi.sunken(isDark),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DietUi.line(isDark)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: DietUi.blue),
              const SizedBox(width: 6),
              Text(text, style: DietUi.text(11.5, FontWeight.w600, DietUi.body(isDark))),
            ],
          ),
        );

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: DietUi.background(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: DietUi.line(isDark), borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  Text('Plan preview', style: DietUi.text(11.5, FontWeight.w700, DietUi.muted(isDark), spacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(plan.planName, style: DietUi.text(18, FontWeight.w700, DietUi.strong(isDark), height: 1.25)),
                  const SizedBox(height: 2),
                  Text(
                    plan.createdByPatient ? 'Made by you' : 'Dr. ${plan.doctorName} · ${plan.clinicName}',
                    style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark)),
                  ),
                  if ((plan.condition ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Goal: ${plan.condition!.trim()}', style: DietUi.text(12, FontWeight.w500, DietUi.body(isDark))),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      fact(
                        Icons.event_rounded,
                        length != null ? '$length days' : (start != null ? 'From ${_date.format(start)}' : 'No end date'),
                      ),
                      fact(Icons.repeat_rounded, plan.totalDays > 1 ? '${plan.totalDays}-day rotation' : 'Same menu daily'),
                      if (plan.targetCalories != null) fact(Icons.local_fire_department_rounded, '${plan.targetCalories} kcal/day goal'),
                      fact(Icons.eco_rounded, plan.dietType),
                      fact(Icons.restaurant_rounded, '${foods.length} ${foods.length == 1 ? 'food' : 'foods'}'),
                    ],
                  ),
                  if (start != null && end != null) ...[
                    const SizedBox(height: 8),
                    Text('${_date.format(start)} – ${_date.format(end)}', style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark))),
                  ],
                  if (plan.totalDays > 1) ...[
                    const SizedBox(height: 18),
                    Text(
                      'The menu repeats every ${plan.totalDays} days. Pick a day to see its meals.',
                      style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = days[i];
                          final selected = d == _day;
                          final kcal = dietSlotsForDay(widget.meals, d).fold<int>(0, (sum, s) => sum + s.calories);
                          return ChoiceChip(
                            label: Text(kcal > 0 ? 'Day $d · $kcal kcal' : 'Day $d'),
                            selected: selected,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _day = d),
                            labelStyle: DietUi.text(12, selected ? FontWeight.w700 : FontWeight.w500, selected ? Colors.white : DietUi.body(isDark)),
                            selectedColor: DietUi.blue,
                            backgroundColor: DietUi.card(isDark),
                            side: BorderSide(color: selected ? DietUi.blue : DietUi.line(isDark)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.totalDays > 1 ? 'Day $_day menu' : 'Daily menu',
                          style: DietUi.text(15, FontWeight.w700, DietUi.strong(isDark)),
                        ),
                      ),
                      if (dayKcal > 0) Text('$dayKcal kcal', style: DietUi.text(13, FontWeight.w700, DietUi.blue)),
                    ],
                  ),
                  if (dayItems.isNotEmpty && (protein + carbs + fat) > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Protein ${protein.round()} g · Carbs ${carbs.round()} g · Fat ${fat.round()} g',
                      style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (slots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: DietUi.cardDecoration(isDark),
                      child: Text(
                        widget.meals.isEmpty ? 'No foods have been added to this plan yet.' : 'No meals on this day.',
                        style: DietUi.text(12.5, FontWeight.w500, DietUi.muted(isDark)),
                      ),
                    )
                  else
                    for (final slot in slots) _slotCard(slot, isDark),
                ],
              ),
            ),
            if (widget.onOpen != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: DietUi.card(isDark),
                  border: Border(top: BorderSide(color: DietUi.line(isDark))),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onOpen!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DietUi.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Open plan', style: DietUi.text(14, FontWeight.w700, Colors.white)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _slotCard(DietPreviewSlot slot, bool isDark) {
    final style = DietUi.slotStyle(slot.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: DietUi.cardDecoration(isDark),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                DietUi.iconBadge(style.icon, style.color, isDark, size: 34, iconSize: 17),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slot.name, style: DietUi.text(13.5, FontWeight.w700, DietUi.strong(isDark))),
                      Text(
                        '${slot.time.trim().isEmpty ? 'Any time' : slot.time} · ${slot.items.length} ${slot.items.length == 1 ? 'item' : 'items'}',
                        style: DietUi.text(11, FontWeight.w400, DietUi.muted(isDark)),
                      ),
                    ],
                  ),
                ),
                DietUi.pill('${slot.calories} kcal', DietUi.blue, isDark),
              ],
            ),
          ),
          Divider(height: 1, color: DietUi.line(isDark)),
          for (var i = 0; i < slot.items.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 58, color: DietUi.line(isDark)),
            _foodRow(slot.items[i], isDark),
          ],
        ],
      ),
    );
  }

  Widget _foodRow(TodayDietMealItem meal, bool isDark) {
    final weight = formatDietWeight(meal.weightAmount, meal.weightUnit);
    final portion = [formatDietPortion(meal.quantity, meal.unit), ?weight].join(' · ');
    final kcal = meal.caloriesUnknown ? '—' : '${meal.caloriesEstimated ? '≈ ' : ''}${meal.effectiveCalories} kcal';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DietFoodImage(imageUrl: meal.imageUrl, category: meal.category ?? '', foodType: meal.foodType ?? '', size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.foodName, style: DietUi.text(13, FontWeight.w600, DietUi.strong(isDark), height: 1.3)),
                Text(portion, style: DietUi.text(11, FontWeight.w400, DietUi.muted(isDark))),
                if ((meal.notes ?? '').trim().isNotEmpty)
                  Text(
                    meal.notes!.trim(),
                    style: DietUi.text(11, FontWeight.w400, DietUi.muted(isDark)).copyWith(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(kcal, style: DietUi.text(12, FontWeight.w600, DietUi.body(isDark))),
        ],
      ),
    );
  }
}
