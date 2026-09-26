/// Application wide strings (PDF section 7 - core/constants/app_strings.dart).
class AppStrings {
  AppStrings._();

  static const String appName = 'PanditIndia';
  static const String appNamePandit = 'PanditIndia Pandit';
  static const String tagline = 'VEDIC ENTERPRISE PLATFORM';
  static const String taglineShort = 'Vedic Enterprise Platform';

  // Splash
  static const String splashHeadline =
      'Authentic Vedic\nCeremonies\nDelivered to Your\nDoorstep';
  static const String loading = 'Loading...';

  // Welcome / role selection
  static const String welcomeTitle = 'Welcome to ';
  static const String welcomeSubtitle =
      'Login or create an account to continue booking your pooja services.';
  static const String customerRoleTitle = 'Customer / Devotee';
  static const String customerRoleSubtitle =
      'Book Puja, Homam, Wedding and other Vedic services.';
  static const String panditRoleTitle = 'Pandit / Acharya';
  static const String panditRoleSubtitle =
      'Manage bookings, set availability and grow your seva.';
  static const String benefitsTitle = 'Why devotees trust us';
  static const String benefitVerifiedTitle = 'Verified & Trusted Pandits';
  static const String benefitVerifiedSubtitle = '100% verified Vedic experts';
  static const String benefitBookingTitle = 'Easy Online Booking';
  static const String benefitBookingSubtitle = 'Puja at home, temple or online';
  static const String benefitSupportTitle = 'Dedicated Support';
  static const String benefitSupportSubtitle =
      'Assistance throughout your booking';
  static const String newToPanditIndia = 'New to PanditIndia?';
  static const String createCustomerAccount = 'Create Customer Account';
  static const String existingAccount = 'Already have an account?';
  static const String signIn = 'Sign In';
  static const String registerHere = 'Register Here';

  // Login
  static const String loginTitle = 'Customer Login';
  static const String loginSubtitle =
      'Sign in to book your puja and spiritual services';
  static const String identifierLabel = 'Email Address or Mobile Number';
  static const String identifierHint = 'Enter your email or mobile number';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String forgotPassword = 'Forgot Password?';
  static const String orDivider = 'OR';
  static const String continueGoogle = 'Continue with Google';
  static const String continueApple = 'Continue with Apple';
  static const String noAccountPrompt = "Don't have an account?";

  // Register
  static const String registerTitle = 'Create Customer Account';
  static const String registerSubtitle =
      'Join PanditIndia to book authentic Vedic ceremonies.';
  static const String fullNameLabel = 'Full Name';
  static const String fullNameHint = 'Enter your full name';
  static const String mobileLabel = 'Mobile Number';
  static const String mobileHint = 'Enter mobile number';
  static const String emailOptionalLabel = 'Email Address (Optional)';
  static const String emailOptionalHint = 'Enter your email address';
  static const String createPasswordHint = 'Create a password';
  static const String createAccount = 'Create Account';
  static const String termsPrefix = 'I agree to the ';
  static const String termsAndConditions = 'Terms & Conditions';
  static const String termsMiddle = ' and ';
  static const String privacyPolicy = 'Privacy Policy';

  // Forgot password
  static const String forgotTitle = 'Forgot Password';
  static const String forgotSubtitle =
      'Enter your registered email or mobile number and we will send a verification code.';
  static const String sendOtp = 'Send Verification Code';
  static const String resetTitle = 'Reset Password';
  static const String resetSubtitle =
      'Enter the 6 digit code we sent to {destination} and choose a new password.';
  static const String otpLabel = 'Verification Code';
  static const String newPasswordLabel = 'New Password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String resetPassword = 'Reset Password';
  static const String resendCode = 'Resend Code';

  // Home & navigation
  static const String greetingPrefix = 'Namaste, ';
  static const String homeLocation = 'Hyderabad, Telangana';
  static const String upcomingBookings = 'Upcoming Bookings';
  static const String noUpcomingTitle = 'No upcoming bookings';
  static const String noUpcomingSubtitle =
      'Your scheduled poojas will appear here.';
  static const String bookPujaNow = 'Book Puja Now';
  static const String viewDetails = 'View Details';
  static const String serviceCategories = 'Service Categories';
  static const String featuredServices = 'Featured Services';
  static const String featuredPandits = 'Featured Pandits';
  static const String promotions = 'Offers & Promotions';
  static const String bookAgain = 'Book Again';
  static const String viewAll = 'View All';
  static const String comingSoon = 'Coming Soon';
  static const String comingSoonSubtitle =
      'This section is being prepared as part of the next delivery stage.';

  // Drawer
  static const String menuHome = 'Home';
  static const String menuServices = 'Services';
  static const String menuPandits = 'Pandits';
  static const String menuEvents = 'Events';
  static const String menuGallery = 'Gallery';
  static const String menuBlogs = 'Blogs';
  static const String menuAbout = 'About';
  static const String menuContact = 'Contact';
  static const String menuBookings = 'My Bookings';
  static const String menuProfile = 'My Profile';
  static const String menuAddresses = 'Saved Addresses';
  static const String menuHelp = 'Help & Support';
  static const String menuLanguage = 'Language';
  static const String menuSettings = 'Settings';
  static const String menuLogout = 'Logout';
  static const String menuSignIn = 'Sign In / Register';

  // Bottom navigation
  static const String tabHome = 'Home';
  static const String tabServices = 'Services';
  static const String tabBookings = 'Bookings';
  static const String tabProfile = 'Profile';

  // Feedback
  static const String genericError =
      'Something went wrong. Please try again.';
  static const String networkError =
      'Unable to reach PanditIndia. Check your connection and retry.';
  static const String invalidCredentials =
      'The email/mobile or password you entered is incorrect.';
  static const String socialNotConfigured =
      'Google Sign-In will be enabled once the OAuth keys are added.';
  static const String socialAppleNotConfigured =
      'Apple Sign-In will be enabled once the OAuth keys are added.';
  static const String logoutSuccess = 'You have been signed out.';
  static const String panditAppMessage =
      'The Pandit / Acharya experience lives in the PanditIndia Pandit app.';

  // Validators
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Enter a valid email address';
  static const String invalidMobile = 'Enter a valid 10 digit mobile number';
  static const String weakPassword =
      'Password must be at least 8 characters with a letter and a number';
  static const String passwordMismatch = 'Passwords do not match';
  static const String invalidOtp = 'Enter the 6 digit code';
  static const String acceptTerms = 'Please accept the terms to continue';
}
