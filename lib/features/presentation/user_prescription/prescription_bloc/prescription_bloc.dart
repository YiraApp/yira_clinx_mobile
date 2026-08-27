import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/features/domain/entities/medication/medication_entity.dart';
import 'package:yiraclinics/features/use_cases/ge_prescription_use_case.dart';


part 'prescription_event.dart';
part 'prescription_state.dart';

// prescription_bloc.dart
class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final GetPrescriptionUseCase getMedicationSummary;

  MedicationBloc({required this.getMedicationSummary}) : super(const MedicationState()) {
    on<LoadMedicationData>(_onLoadMedicationData);
    on<FilterByStatus>(_onFilterByStatus);
    on<LoadPrescriptionDetails>(_onLoadPrescriptionDetails);
  }

  Future<void> _onLoadMedicationData(LoadMedicationData event, Emitter<MedicationState> emit) async {
    emit(state.copyWith(status: MedicationStatus.loading));
    try {
      final data = await getMedicationSummary();
      final List<Map<String, dynamic>> mockList = [
        {"id": "1", "title": "Hypertension", "status": "Active", "date": "2024-01-18"},
        {"id": "2", "title": "Eczema", "status": "Completed", "date": "2024-01-15"},
      ];
      emit(state.copyWith(status: MedicationStatus.success, summary: data, allPrescriptions: mockList, filteredPrescriptions: mockList));
    } catch (e) {
      emit(state.copyWith(status: MedicationStatus.failure, error: e.toString()));
    }
  }

  void _onFilterByStatus(FilterByStatus event, Emitter<MedicationState> emit) {
    final filtered = event.status == "All"
        ? state.allPrescriptions
        : state.allPrescriptions.where((p) => p['status'].toString().toLowerCase() == event.status.toLowerCase()).toList();
    emit(state.copyWith(selectedStatus: event.status, filteredPrescriptions: filtered));
  }

  Future<void> _onLoadPrescriptionDetails(LoadPrescriptionDetails event, Emitter<MedicationState> emit) async {
    emit(state.copyWith(status: MedicationStatus.loading));

    // Simulating delay for realistic feel
    await Future.delayed(const Duration(milliseconds: 300));

    final mockDetail = {
      "doctor": "Dr. Rajesh Kumar",
      "specialty": "Cardiologist",
      "date": "2024-01-18",
      "condition": "Hypertension",
      "status": "Active",
      "pharmacy": "Yira Pharmacy, MG Road",
      "notes": "Monitor blood pressure daily. Follow-up in 4 weeks.",
      "medications": [
        {
          "name": "Lisinopril",
          "dosage": "10mg",
          "remaining": "25/30",
          "frequency": "Once daily",
          "duration": "30 days",
          "instructions": "Take with food in the morning",
          "refills": 2,
          "progress": 0.17
        },
        {
          "name": "Amlodipine",
          "dosage": "5mg",
          "remaining": "28/30",
          "frequency": "Once daily",
          "duration": "30 days",
          "instructions": "Take in the morning",
          "refills": 2,
          "progress": 0.07
        }
      ]
    };

    emit(state.copyWith(status: MedicationStatus.success, selectedPrescriptionDetail: mockDetail));
  }
}
