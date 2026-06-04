class ApiEndPoiunts {
  static const baseUrl = String.fromEnvironment(
    "DITTOX_API_BASE_URL",
    defaultValue: "https://dittox.in/xerox/v1",
  );
  static const requestTimeout = Duration(seconds: 20);
  static const backendUnavailableMessage =
      "Dittox server did not respond. Check the backend URL or your internet connection.";
  static const int maxUnpaidPayLaterOrders = 3;

  static const loginEndpoint = "$baseUrl/account/login";
  static const registerForOtp = "$baseUrl/account/registrationOtp";
  static const createUser = "$baseUrl/account/create";
  static const resetPasswordOtp = "$baseUrl/account/generateResetPasswordOtp";
  static const resetPasswordConfirm = "$baseUrl/account/resetForgotPassword";

  // UPI merchant details for direct GPay/UPI payment.
  // Override with --dart-define values in release.
  static const merchantUpiId = String.fromEnvironment(
    "DITTOX_MERCHANT_UPI_ID",
    defaultValue: "merchant@okhdfcbank",
  );
  static const merchantName = String.fromEnvironment(
    "DITTOX_MERCHANT_NAME",
    defaultValue: "Dittox",
  );
  static const gpaySubscriptionGatewayUrl = String.fromEnvironment(
    "DITTOX_GPAY_SUBSCRIPTION_URL",
    defaultValue: "https://razorpay.me/@durgavaraprasadvaddi",
  );
  static const razorpayCreateOrderUrl = String.fromEnvironment(
    "DITTOX_RAZORPAY_CREATE_ORDER_URL",
    defaultValue: "",
  );
  static const razorpayVerifyPaymentUrl = String.fromEnvironment(
    "DITTOX_RAZORPAY_VERIFY_URL",
    defaultValue: "",
  );
  static final double releaseSharePercent = double.tryParse(
        const String.fromEnvironment(
          "DITTOX_RELEASE_SHARE_PERCENT",
          defaultValue: "0",
        ),
      ) ??
      0;
  static const String releaseShareBeneficiary = String.fromEnvironment(
    "DITTOX_RELEASE_SHARE_BENEFICIARY",
    defaultValue: "",
  );

  //   endpoint: https://dittox.in/xerox/v1/account/login

  // payload: {
  //   email:string,
  // password: string
  // }

  // If user exist true →

  // {
  //     "responseCode": "OK",
  //     "message": "User logged in successfully.",
  //     "result": {
  //         "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7Il9pZCI6IjY1NGIzOGYwNmZiZDUzZThhZTg5NTQ5MiIsImVtYWlsIjoidmFyYXByYXNhZHZhZGRpMDRAZ21haWwuY29tIiwibmFtZSI6InZhcmFwcmFzYWQifSwiaWF0IjoxNzAyNDg2MjEyLCJleHAiOjE3MDI1NzI2MTJ9.ZwvREkEuEKRlzeoqNtwoMQFNlC0K-kdy-3JwNAUrxwg",
  //         "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7Il9pZCI6IjY1NGIzOGYwNmZiZDUzZThhZTg5NTQ5MiIsImVtYWlsIjoidmFyYXByYXNhZHZhZGRpMDRAZ21haWwuY29tIiwibmFtZSI6InZhcmFwcmFzYWQifSwiaWF0IjoxNzAyNDg2MjEyLCJleHAiOjE3MTgyOTc0MTJ9.BMabWWE9_hJBJNSIJ9ulxoJrU1V2VU-XZbPNHDY-Gvk",
  //         "user": {
  //             "_id": "654b38f06fbd53e8ae895492",
  //             "mobile": "9133931892",
  //             "email": {
  //                 "address": "varaprasadvaddi04@gmail.com",
  //                 "verified": true
  //             },
  //             "name": "varaprasad",
  //             "deleted": false,
  //             "designation": [],
  //             "location": [],
  //             "updatedAt": "2023-11-08T07:29:52.242Z",
  //             "createdAt": "2023-11-08T07:29:52.242Z",
  //             "lastLoggedInAt": "2023-11-09T14:17:56.050Z"
  //         }
  //     },
  //     "meta": {
  //         "correlation": "4c7d7e70-836d-4fad-8703-e90b32a5f95d"
  //     }
  // }

  // Password is wrong
  // {
  //     "responseCode": "CLIENT_ERROR",
  //     "message": "Username or password is invalid.",
  //     "error": [],
  //     "meta": {
  //         "correlation": "f7028309-a441-4393-aa7e-c61d573bf4ba"
  //     }
  // }

  // Mail is wrong
  // {
  //     "responseCode": "CLIENT_ERROR",
  //     "message": "Please enter the correct login ID and Password.",
  //     "error": [],
  //     "meta": {
  //         "correlation": "bb6713c6-4d9b-4876-b881-b549ef5cbb46"
  //     }
  // }

  // Document Upload Endpoints
  static const String uploadDocument = "$baseUrl/documents/upload";
  static const String getSignedUploadUrl = "$baseUrl/documents/signed-url";
  static const String saveDocument = "$baseUrl/documents/save";
  static const String getUserDocuments = "$baseUrl/documents/user";
  static const String deleteDocument = "$baseUrl/documents/delete";

  // Order Endpoints
  static const String createOrder = "$baseUrl/orders/create";
  static const String getOrders = "$baseUrl/orders";
  static const String getOrderById = "$baseUrl/orders";
  static const String updateOrderStatus = "$baseUrl/orders/status";
  static const String cancelOrder = "$baseUrl/orders/cancel";

  // Shop Endpoints
  static const String getShops = "$baseUrl/shops";
  static const String getShopById = "$baseUrl/shops";
  static const String registerShop = "$baseUrl/shops/register";

  // Payment Endpoints
  static const String initiatePayment = "$baseUrl/payments/initiate";
  static const String verifyPayment = "$baseUrl/payments/verify";
  static const String getPaymentStatus = "$baseUrl/payments/status";
}
