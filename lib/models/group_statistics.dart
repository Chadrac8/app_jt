class GroupStatistics {
  final int totalMembers;
  final int totalMeetings;
  final double averageAttendance;
  final Map<String, MemberAttendance> memberAttendance;
  final Map<String, double> monthlyAttendance;
  final int activeMembers;

  GroupStatistics({
    required this.totalMembers,
    required this.totalMeetings,
    required this.averageAttendance,
    required this.memberAttendance,
    required this.monthlyAttendance,
    required this.activeMembers,
  });

  factory GroupStatistics.empty() {
    return GroupStatistics(
      totalMembers: 0,
      totalMeetings: 0,
      averageAttendance: 0.0,
      memberAttendance: {},
      monthlyAttendance: {},
      activeMembers: 0,
    );
  }
}

class MemberAttendance {
  final String personName;
  final double attendanceRate;
  final int consecutiveAbsences;
  final int totalMeetings;
  final int presentCount;
  final int absentCount;
  final DateTime? lastAttendance;

  MemberAttendance({
    required this.personName,
    required this.attendanceRate,
    required this.consecutiveAbsences,
    required this.totalMeetings,
    required this.presentCount,
    required this.absentCount,
    this.lastAttendance,
  });

  String get attendanceLabel {
    if (attendanceRate >= 0.9) {
      return 'Excellente';
    } else if (attendanceRate >= 0.7) {
      return 'Bonne';
    } else if (attendanceRate >= 0.5) {
      return 'Moyenne';
    } else {
      return 'Faible';
    }
  }
}
