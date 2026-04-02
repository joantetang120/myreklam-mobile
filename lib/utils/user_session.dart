class UserSession {
  static final UserSession _instance = UserSession._internal();

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();

  String _userType = 'particulier'; // Default to particulier
  String? _id;
  String? _email;
  bool _isEmailVerified = false;
  bool _profileCompleted = false;
  Map<String, dynamic>? _subscription;
  String? _parrainageCode;
  int _mys = 0;

  String get userType => _userType;
  String? get id => _id;
  String? get email => _email;
  bool get isEmailVerified => _isEmailVerified;
  bool get profileCompleted => _profileCompleted;
  Map<String, dynamic>? get subscription => _subscription;
  String? get subscriptionPlan => _subscription?['plan'];
  String? get subscriptionStatus => _subscription?['status'];
  bool get hasActiveSubscription => _subscription != null && _subscription!.isNotEmpty;
  String? get parrainageCode => _parrainageCode;
  int get mys => _mys;

  void setUserType(String type) {
    _userType = type;
  }

  bool get isParticulier => _userType == 'particulier';
  bool get isPro => _userType == 'pro';

  void updateFromApi({
    String? id,
    String? email,
    String? accountType,
    bool? isEmailVerified,
    bool? profileCompleted,
    Map<String, dynamic>? subscription,
    String? parrainageCode,
    int? mys,
  }) {
    if (id != null) _id = id;
    if (email != null) _email = email;
    if (accountType != null) _userType = accountType;
    if (isEmailVerified != null) _isEmailVerified = isEmailVerified;
    if (profileCompleted != null) _profileCompleted = profileCompleted;
    _subscription = subscription;
    if (parrainageCode != null) _parrainageCode = parrainageCode;
    if (mys != null) _mys = mys;
  }

  void updateMys(int mys) {
    _mys = mys;
  }

  void updateParrainageCode(String? code) {
    _parrainageCode = code;
  }

  void clear() {
    _userType = 'particulier';
    _id = null;
    _email = null;
    _isEmailVerified = false;
    _profileCompleted = false;
    _subscription = null;
    _parrainageCode = null;
    _mys = 0;
  }

  bool get needsAccountType => _userType.isEmpty || _userType == 'particulier' && _id != null && !_profileCompleted;
  bool get needsProfileCompletion => !_profileCompleted;
  bool get needsSubscription => isPro && !hasActiveSubscription;
}
