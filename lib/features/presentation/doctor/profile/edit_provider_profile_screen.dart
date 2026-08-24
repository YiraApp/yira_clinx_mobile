import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';
import 'provider_profile_bloc/provider_profile_bloc.dart';

class EditProviderProfileScreen extends StatefulWidget {
  final ProviderProfileEntity profile;
  final ProviderProfileBloc bloc;

  const EditProviderProfileScreen({
    super.key,
    required this.profile,
    required this.bloc,
  });

  @override
  State<EditProviderProfileScreen> createState() => _EditProviderProfileScreenState();
}

class _EditProviderProfileScreenState extends State<EditProviderProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Personal controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  String? _selectedGender;
  String? _selectedBloodGroup;

  // Professional controllers
  late TextEditingController _specialtyController;
  late TextEditingController _subSpecialtyController;
  late TextEditingController _departmentController;
  late TextEditingController _qualificationController;
  late TextEditingController _regNumberController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;

  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final p = widget.profile;
    _firstNameController = TextEditingController(text: p.firstName);
    _lastNameController = TextEditingController(text: p.lastName);
    _emailController = TextEditingController(text: p.email);
    _phoneController = TextEditingController(text: p.phoneNumber);
    _dobController = TextEditingController(text: p.dob);
    _selectedGender = p.gender != null && _genders.contains(p.gender) ? p.gender : 'Male';
    _selectedBloodGroup = p.bloodGroup != null && _bloodGroups.contains(p.bloodGroup) ? p.bloodGroup : 'O+';

    _specialtyController = TextEditingController(text: p.specialty);
    _subSpecialtyController = TextEditingController(text: p.subSpecialty);
    _departmentController = TextEditingController(text: p.department);
    _qualificationController = TextEditingController(text: p.qualification);
    _regNumberController = TextEditingController(text: p.registrationNumber);
    _experienceController = TextEditingController(text: p.experience);
    _bioController = TextEditingController(text: p.bio);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _specialtyController.dispose();
    _subSpecialtyController.dispose();
    _departmentController.dispose();
    _qualificationController.dispose();
    _regNumberController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 30));
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final p = widget.profile;
    final updated = p.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      name: "Dr. ${_firstNameController.text.trim()} ${_lastNameController.text.trim()}".trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      gender: _selectedGender,
      dob: _dobController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      specialty: _specialtyController.text.trim(),
      subSpecialty: _subSpecialtyController.text.trim(),
      department: _departmentController.text.trim(),
      qualification: _qualificationController.text.trim(),
      registrationNumber: _regNumberController.text.trim(),
      experience: _experienceController.text.trim(),
      consultationFee: widget.profile.consultationFee,
      bio: _bioController.text.trim(),
    );

    widget.bloc.add(UpdateDoctorProfileEvent(profile: updated));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text("Profile updated successfully!"),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    return BlocProvider.value(
      value: widget.bloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CommonAppBar(
          titleText: "Edit Doctor Profile",
          showBackButton: true,
          actions: [
            TextButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
              label: const Text(
                "Save",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Enhanced Custom Segmented Tab Bar Header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2538) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                  labelStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 14 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 14 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_rounded, size: 16),
                          SizedBox(width: 6),
                          Text("Personal Details"),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.medical_services_rounded, size: 16),
                          SizedBox(width: 6),
                          Text("Specialization"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Full-Screen Scrollable Tab Form Body
              Expanded(
                child: Form(
                  key: _formKey,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Personal Details Tab
                      _buildPersonalTab(context, isDark, primaryColor, isTab),
                      // Tab 2: Specialization & Qualifications Tab
                      _buildSpecializationTab(context, isDark, primaryColor, isTab),
                    ],
                  ),
                ),
              ),

              // 3. Bottom Action Bar with Glowing "Save Changes" Button
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2234) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 15 : 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 4,
                          shadowColor: primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Save Changes",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalTab(BuildContext context, bool isDark, Color primaryColor, bool isTab) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildSectionHeader("Doctor Identity", Icons.badge_outlined, primaryColor, isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: "First Name *",
                controller: _firstNameController,
                icon: Icons.person_outline_rounded,
                isDark: isDark,
                primaryColor: primaryColor,
                hint: "e.g. Rahul",
                validator: (val) => val == null || val.trim().isEmpty ? "Required" : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: "Last Name",
                controller: _lastNameController,
                icon: Icons.person_outline_rounded,
                isDark: isDark,
                primaryColor: primaryColor,
                hint: "e.g. Sharma",
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildSectionHeader("Contact Information", Icons.contact_phone_outlined, primaryColor, isDark),
        const SizedBox(height: 12),
        _buildTextField(
          label: "Email Address *",
          controller: _emailController,
          icon: Icons.email_outlined,
          isDark: isDark,
          primaryColor: primaryColor,
          keyboardType: TextInputType.emailAddress,
          hint: "doctor@hospital.com",
          validator: (val) {
            if (val == null || val.trim().isEmpty) return "Email is required";
            if (!val.contains('@')) return "Enter a valid email address";
            return null;
          },
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: "Phone Number *",
          controller: _phoneController,
          icon: Icons.phone_outlined,
          isDark: isDark,
          primaryColor: primaryColor,
          keyboardType: TextInputType.phone,
          hint: "+91 98765 43210",
          validator: (val) => val == null || val.trim().isEmpty ? "Phone number is required" : null,
        ),
        const SizedBox(height: 18),
        _buildSectionHeader("Personal Demographics", Icons.accessibility_new_rounded, primaryColor, isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectDateOfBirth,
                child: AbsorbPointer(
                  child: _buildTextField(
                    label: "Date of Birth",
                    controller: _dobController,
                    icon: Icons.cake_outlined,
                    isDark: isDark,
                    primaryColor: primaryColor,
                    hint: "YYYY-MM-DD",
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdownField(
                label: "Blood Group",
                value: _selectedBloodGroup,
                items: _bloodGroups,
                icon: Icons.bloodtype_outlined,
                isDark: isDark,
                primaryColor: primaryColor,
                onChanged: (val) => setState(() => _selectedBloodGroup = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildDropdownField(
          label: "Gender",
          value: _selectedGender,
          items: _genders,
          icon: Icons.wc_rounded,
          isDark: isDark,
          primaryColor: primaryColor,
          onChanged: (val) => setState(() => _selectedGender = val),
        ),
      ],
    );
  }

  Widget _buildSpecializationTab(BuildContext context, bool isDark, Color primaryColor, bool isTab) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildSectionHeader("Clinical Specialty", Icons.medical_services_outlined, const Color(0xFF10B981), isDark),
        const SizedBox(height: 12),
        _buildTextField(
          label: "Specialty / Designation *",
          controller: _specialtyController,
          icon: Icons.medical_services_outlined,
          isDark: isDark,
          primaryColor: primaryColor,
          hint: "e.g. Senior Cardiologist, Dentist",
          validator: (val) => val == null || val.trim().isEmpty ? "Specialty is required" : null,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: "Sub-Specialty",
                controller: _subSpecialtyController,
                icon: Icons.local_hospital_outlined,
                isDark: isDark,
                primaryColor: primaryColor,
                hint: "e.g. Interventional",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: "Department",
                controller: _departmentController,
                icon: Icons.apartment_rounded,
                isDark: isDark,
                primaryColor: primaryColor,
                hint: "e.g. Cardiology",
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildSectionHeader("Medical Registration & Credentials", Icons.verified_user_outlined, const Color(0xFF6366F1), isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: "Qualification",
                controller: _qualificationController,
                icon: Icons.school_outlined,
                isDark: isDark,
                primaryColor: primaryColor,
                hint: "e.g. MBBS, MD",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: "Registration No.",
                controller: _regNumberController,
                icon: Icons.badge_outlined,
                isDark: isDark,
                primaryColor: primaryColor,
                hint: "e.g. REG-12345",
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: "Experience",
          controller: _experienceController,
          icon: Icons.timeline_rounded,
          isDark: isDark,
          primaryColor: primaryColor,
          hint: "e.g. 10+ Years",
        ),
        const SizedBox(height: 18),
        _buildSectionHeader("About & Clinical Bio", Icons.description_outlined, Colors.orange, isDark),
        const SizedBox(height: 12),
        _buildTextField(
          label: "Doctor Summary",
          controller: _bioController,
          icon: Icons.description_outlined,
          isDark: isDark,
          primaryColor: primaryColor,
          maxLines: 4,
          hint: "Brief summary about clinical expertise, medical background, and patient care commitment...",
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 19, color: primaryColor.withOpacity(0.8))
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E2538) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2538) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
              dropdownColor: isDark ? const Color(0xFF1E2538) : Colors.white,
              items: items.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: primaryColor.withOpacity(0.8)),
                      const SizedBox(width: 10),
                      Text(
                        e,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
