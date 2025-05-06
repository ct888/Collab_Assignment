class UserRecordsService {
  // Singleton implementation
  static final UserRecordsService _instance = UserRecordsService._internal();
  factory UserRecordsService() => _instance;
  UserRecordsService._internal();
  
  // Shared data between view models
  Map<String, List<dynamic>>? _recordsData;
  
  // Setter for records data
  void setRecordsData(Map<String, List<dynamic>> records) {
    _recordsData = records;
  }
  
  // Getter for records data
  Map<String, List<dynamic>>? getRecordsData() {
    return _recordsData;
  }
}
