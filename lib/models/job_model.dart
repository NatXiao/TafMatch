import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final String address;
  final String domainName;
  final String degree;
  final int? workPercentage;
  final String languages;
  final double? salaryChfPerHour;
  final DateTime? endDate;
  final String pictureUrl;
  final String status;               // "live", "closed"
  final DateTime? createdAt;

  Job({
    required this.id,
    required this.employerId,
    required this.title,
    this.description = '',
    this.address = '',
    this.domainName = '',
    this.degree = '',
    this.languages = '',
    this.salaryChfPerHour,
    this.workPercentage, 
    this.endDate,
    this.pictureUrl = '',
    this.status = 'live',
    this.createdAt,
  });

bool get isLive {
  if (endDate == null) return status == 'live';
  return status == 'live' && !endDate!.isBefore(DateTime.now());
}

  Map<String, dynamic> toMap() {
    return {
      'employerId': employerId,
      'title': title,
      'description': description,
      'address': address,
      'domainName': domainName,
      'degree': degree,
      'languages': languages,
      'salaryChfPerHour': salaryChfPerHour,
      'workPercentage': workPercentage,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'pictureUrl': pictureUrl,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Job.fromMap(String id, Map<String, dynamic> map) {
    return Job(
      id: id,
      employerId: map['employerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      domainName: map['domainName'] ?? '',
      degree: map['degree'] ?? '',
      languages: map['languages'] ?? '',
      salaryChfPerHour: (map['salaryChfPerHour'] as num?)?.toDouble(),
      workPercentage: (map['workPercentage'] as num?)?.toInt(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      pictureUrl: map['pictureUrl'] ?? '',
      status: map['status'] ?? 'live',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}


