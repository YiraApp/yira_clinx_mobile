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
}
