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
  final DateTime? contractStartDate;                                         
  final DateTime? contractEndDate;                                          
  final String pictureUrl;
  final String status;
  final DateTime? createdAt;

  // Saisies du formulaire sans équivalent ailleurs : elles restent stockées.
  final double experienceMin;
  final double experienceMax;
  final String companySize;
  final String canton;
  final String role;
  final double holidays;

  final double? predictedSalaryChf;
  final String? predictionModelVersion;

  /// Ancien champ `IsPermanent`, lu pour les annonces créées avant que les
  /// dates de contrat ne soient enregistrées. Ne sert plus qu'au repli.
  final bool? _legacyIsPermanent;                                           

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
    this.contractStartDate,                                                 
    this.contractEndDate,                                                   
    this.pictureUrl = '',
    this.status = '',
    this.createdAt,

    this.experienceMin = 0,
    this.experienceMax = 0,
    this.companySize = 'Startup (<50)',
    this.canton = '',
    this.role = 'Junior',
    this.holidays = 25,

    this.predictedSalaryChf,
    this.predictionModelVersion,
    bool? legacyIsPermanent,                                                
  }) : _legacyIsPermanent = legacyIsPermanent;                              

  // ------------------------------------------------------------------
  // Colonnes du modèle dérivées de la saisie, jamais stockées.
  // ------------------------------------------------------------------

  String get industry => domainName;                                         
  String get diploma => degree;                                              
  double get workloadPercent => (workPercentage ?? 100).toDouble();          

  /// Permanent = un début de contrat, pas de fin. Les annonces antérieures
  /// n'ont pas les dates : on retombe sur l'ancien booléen stocké.
  bool get isPermanent => contractStartDate != null                         
      ? contractEndDate == null                                             
      : (_legacyIsPermanent ?? false);                                      

  /// `'French, English'` -> `{French, English}`, tolérant aux espaces.
  Set<String> get languageSet => languages                                  
      .split(',')                                                           
      .map((l) => l.trim())                                                 
      .where((l) => l.isNotEmpty)                                           
      .toSet();                                                             

  double get languagesEnglish => languageSet.contains('English') ? 1 : 0;    
  double get languagesFrench => languageSet.contains('French') ? 1 : 0;      
  double get languagesItalian => languageSet.contains('Italian') ? 1 : 0;   

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
      'contractStartDate': contractStartDate != null                        
          ? Timestamp.fromDate(contractStartDate!)                          
          : null,                                                           
      'contractEndDate': contractEndDate != null                            
          ? Timestamp.fromDate(contractEndDate!)                            
          : null,                                                           
      'pictureUrl': pictureUrl,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),

      'ExperienceMin': experienceMin,
      'ExperienceMax': experienceMax,
      'CompanySize': companySize,
      'Canton': canton,
      'Role': role,
      'Holidays': holidays,

      'predictedSalaryChf': predictedSalaryChf,
      'predictionModelVersion': predictionModelVersion,
    };
  }

  factory Job.fromMap(String id, Map<String, dynamic> map) {
    return Job(
      id: id,
      employerId: map['employerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      domainName: map['domainName'] ?? map['Industry'] ?? '',               
      degree: map['degree'] ?? map['Diploma'] ?? '',                        
      languages: map['languages'] ?? '',
      salaryChfPerHour: (map['salaryChfPerHour'] as num?)?.toDouble(),
      workPercentage: (map['workPercentage'] as num?)?.toInt() ??           
          (map['WorkloadPercent'] as num?)?.toInt(),                        
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      contractStartDate: (map['contractStartDate'] as Timestamp?)?.toDate(),
      contractEndDate: (map['contractEndDate'] as Timestamp?)?.toDate(),    
      pictureUrl: map['pictureUrl'] ?? '',
      status: map['status'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),

      experienceMin: (map['ExperienceMin'] as num?)?.toDouble() ?? 0,
      experienceMax: (map['ExperienceMax'] as num?)?.toDouble() ?? 0,
      companySize: map['CompanySize'] ?? 'Startup (<50)',
      canton: map['Canton'] ?? '',
      role: map['Role'] ?? 'Junior',
      holidays: (map['Holidays'] as num?)?.toDouble() ?? 25,

      predictedSalaryChf: (map['predictedSalaryChf'] as num?)?.toDouble(),
      predictionModelVersion: map['predictionModelVersion'] as String?,
      legacyIsPermanent: map['IsPermanent'] as bool?,                       
    );
  }
}