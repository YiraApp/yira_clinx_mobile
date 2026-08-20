class URLs {
  /*Authentication*/
  static const registrationUrl = "/v1/api/auth/register";
  static const loginUrl = "/v1/api/auth/login";
  static const sendOtpUrl = "/v1/api/auth/sendotp";
  static const updateFcmTokenUrl = "/v1/api/auth/device-token";
  static const getVersionAndTokenStatus = "/v1/api/auth/app-version/status";

  /*Work Space*/
  static const workspaceDetailsUrl = "/v1/api/auth/roles/details";
  static const updateLatestOrgDetails = "/v1/api/auth/latest-context";

  /*User Data*/
  static const getUserDataUrl = "/v1/api/auth/user-data";

  /*Forget Password*/
  static const forgetSendOtpURl = "/v1/api/auth/forgot_password";
  static const forgetVerifyOtpURl = "/v1/api/auth/verify_otp";
  static const saveResetPasswordURl = "/v1/api/auth/change_password";

  /*Dashboard*/
  static const doctorDashBoardUrl = "/v1/api/auth/dashboard";
  static const appointmentDashboardUrl = "/v1/api/auth/appointment-dashboard";
  static const bookAppointmentUrl = "/v1/api/auth/book-appointment";
  static const updateAppointmentStatusUrl = "/v1/api/auth/update-appointment-status";
  static const doctorSlotsUrl = "/v1/api/auth/doctor-slots";
  static const doctorSlotsDeployUrl = "/v1/api/auth/doctor-slots/deploy";
  static const doctorSlotBlockUrl = "/v1/api/auth/doctor-slots/block";
  static const patientsListUrl = "/v1/api/auth/patients";
  static const dashboardPatientDetailsUrl = "/v1/api/auth/patient/details";
  static const dashboardPatientClinicalDetailsUrl = "/v1/api/auth/clinical-data";

  /*Side menu*/
  static const sideMenuUrl = "/v1/api/auth/sidebar";

  /*Patient Profile*/
  static const patientOverViewUrl = "/v1/api/auth/patient/overview";

  /*SNOMED CT Search*/
  static const snomedSearchUrl = "/v1/api/auth/snomed/search";

  /*Clinical Notes*/
  static const clinicalNotesUrl = "/v1/api/auth/clinical-notes";

  /*Medical Records*/
  static const medicalRecordsUrl = "/v1/api/auth/medical-records";

  /*Prescriptions*/
  static const prescriptionsUrl = "/v1/api/auth/prescriptions";

  /*Provider Profile*/
  static const providerProfileUrl = "/v1/api/auth/provider/profile";
  static const providerProfileUpdateUrl = "/v1/api/auth/provider/profile/update";
  static const providerProfileUploadPhotoUrl = "/v1/api/auth/provider/profile/upload-photo";

  /*Medical Documents*/
  static const medicalDocumentsUrl = "/v1/api/auth/medical-documents";

  /*Patient Medical Record Access Consents*/
  static const patientAccessRequestUrl = "/v1/api/auth/patient-access/request";
  static const patientAccessCheckUrl = "/v1/api/auth/patient-access/check";
  static const patientConsentsListUrl = "/v1/api/auth/patient-access/patient-consents";
  static const patientConsentRespondUrl = "/v1/api/auth/patient-access/respond";
}
