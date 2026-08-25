class WorkExperience {
  final String id;
  final String userId;
  final String? jobId;

  WorkExperience({
    required this.id,
    required this.userId,
    this.jobId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'jobId': jobId,
    };
  }

  factory WorkExperience.fromMap(String id, Map<String, dynamic> map) {
    return WorkExperience(
      id: id,
      userId: map['userId'],
      jobId: map['jobId'],
    );
  }
}