class WorkerCategory {
  final String id;
  final String name;
  final String icon; // Icon identifier e.g. 'electrician', 'plumber', etc.
  final int colorValue;

  WorkerCategory({
    required this.id,
    required this.name,
    this.icon = 'handyman',
    this.colorValue = 0xFF2563EB,
  });

  factory WorkerCategory.fromMap(Map<String, dynamic> data, String id) {
    return WorkerCategory(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'handyman',
      colorValue: data['colorValue'] ?? 0xFF2563EB,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'icon': icon, 'colorValue': colorValue};
  }
}

class Worker {
  final String id;
  final String name;
  final String category; // e.g., Mason, Plumber
  final String phone;
  final String location;
  final double rating;
  final bool isActive;
  final double expectedWage;

  Worker({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.location,
    this.rating = 0.0,
    this.isActive = true,
    this.expectedWage = 0.0,
  });

  factory Worker.fromMap(Map<String, dynamic> data, String id) {
    return Worker(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      expectedWage: (data['expectedWage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'phone': phone,
      'location': location,
      'rating': rating,
      'isActive': isActive,
      'expectedWage': expectedWage,
    };
  }
}

class Booking {
  final String id;
  final String customerName;
  final String customerPhone;
  final String requiredWorkerCategory;
  final DateTime date;
  final String time;
  final String location;
  final String? gpsCoordinates; // e.g. "11.2588, 75.7804"
  final String?
  mapsUrl; // e.g. "https://www.google.com/maps/search/?api=1&query=11.2588,75.7804"
  final String status;
  final String? assignedWorkerId;
  final int numberOfWorkers;
  final bool isCustomerPaid;
  final bool isWorkerPaid;

  Booking({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.requiredWorkerCategory,
    required this.date,
    required this.time,
    required this.location,
    this.gpsCoordinates,
    this.mapsUrl,
    this.status = 'New',
    this.assignedWorkerId,
    this.numberOfWorkers = 1,
    this.isCustomerPaid = false,
    this.isWorkerPaid = false,
  });

  factory Booking.fromMap(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      requiredWorkerCategory: data['requiredWorkerCategory'] ?? '',
      date: data['date'] != null
          ? DateTime.parse(data['date'])
          : DateTime.now(),
      time: data['time'] ?? '',
      location: data['location'] ?? '',
      gpsCoordinates: data['gpsCoordinates'],
      mapsUrl: data['mapsUrl'],
      status: data['status'] ?? 'New',
      assignedWorkerId: data['assignedWorkerId'],
      numberOfWorkers: data['numberOfWorkers'] ?? 1,
      isCustomerPaid: data['isCustomerPaid'] ?? false,
      isWorkerPaid: data['isWorkerPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'requiredWorkerCategory': requiredWorkerCategory,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'gpsCoordinates': gpsCoordinates,
      'mapsUrl': mapsUrl,
      'status': status,
      'assignedWorkerId': assignedWorkerId,
      'numberOfWorkers': numberOfWorkers,
      'isCustomerPaid': isCustomerPaid,
      'isWorkerPaid': isWorkerPaid,
    };
  }
}

class Employer {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String location;

  Employer({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    required this.location,
  });

  factory Employer.fromMap(Map<String, dynamic> data, String id) {
    return Employer(
      id: id,
      companyName: data['companyName'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'contactPerson': contactPerson,
      'phone': phone,
      'location': location,
    };
  }
}

class Job {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final String category;
  final String location;
  final double salary;
  final int vacancies;
  final String status;

  Job({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.salary = 0.0,
    this.vacancies = 1,
    this.status = 'Open',
  });

  factory Job.fromMap(Map<String, dynamic> data, String id) {
    return Job(
      id: id,
      employerId: data['employerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      salary: (data['salary'] ?? 0.0).toDouble(),
      vacancies: data['vacancies'] ?? 1,
      status: data['status'] ?? 'Open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employerId': employerId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'salary': salary,
      'vacancies': vacancies,
      'status': status,
    };
  }
}

class JobApplication {
  final String id;
  final String jobId;
  final String applicantName;
  final String phone;
  final String skills;
  final String status;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.applicantName,
    required this.phone,
    required this.skills,
    this.status = 'Pending',
  });

  factory JobApplication.fromMap(Map<String, dynamic> data, String id) {
    return JobApplication(
      id: id,
      jobId: data['jobId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      phone: data['phone'] ?? '',
      skills: data['skills'] ?? '',
      status: data['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'applicantName': applicantName,
      'phone': phone,
      'skills': skills,
      'status': status,
    };
  }
}

class ContactInfo {
  final String appName;
  final String appTagline;
  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String workingHours;
  final String emergencyNumber;
  final String adminSmsNumber;
  final bool enableSmsAlerts;
  final String smsGatewayProvider; // 'fast2sms', 'twofactor', 'twilio', 'custom_api', 'direct_intent'
  final String smsApiKey;
  final String smsSenderId;
  final String smsCustomUrl;

  ContactInfo({
    this.appName = 'WorkConnect Kerala',
    this.appTagline = 'Instant Worker Booking & Kerala Jobs Portal',
    this.phone = '+91 8129540062',
    this.whatsapp = '918129540062',
    this.email = 'support@workconnectkerala.in',
    this.address = 'Mavoor Road, Kozhikode, Kerala - 673001',
    this.workingHours = 'Mon - Sun: 7:00 AM - 10:00 PM',
    this.emergencyNumber = '+91 8129540062',
    this.adminSmsNumber = '+91 8129540062',
    this.enableSmsAlerts = true,
    this.smsGatewayProvider = 'fast2sms',
    this.smsApiKey = '',
    this.smsSenderId = 'WKCONN',
    this.smsCustomUrl = '',
  });

  factory ContactInfo.fromMap(Map<String, dynamic> data) {
    return ContactInfo(
      appName: data['appName'] ?? 'WorkConnect Kerala',
      appTagline: data['appTagline'] ?? 'Instant Worker Booking & Kerala Jobs Portal',
      phone: data['phone'] ?? '+91 8129540062',
      whatsapp: data['whatsapp'] ?? '918129540062',
      email: data['email'] ?? 'support@workconnectkerala.in',
      address: data['address'] ?? 'Mavoor Road, Kozhikode, Kerala - 673001',
      workingHours: data['workingHours'] ?? 'Mon - Sun: 7:00 AM - 10:00 PM',
      emergencyNumber: data['emergencyNumber'] ?? '+91 8129540062',
      adminSmsNumber: data['adminSmsNumber'] ?? (data['phone'] ?? '+91 8129540062'),
      enableSmsAlerts: data['enableSmsAlerts'] ?? true,
      smsGatewayProvider: data['smsGatewayProvider'] ?? 'fast2sms',
      smsApiKey: data['smsApiKey'] ?? '',
      smsSenderId: data['smsSenderId'] ?? 'WKCONN',
      smsCustomUrl: data['smsCustomUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'appTagline': appTagline,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'workingHours': workingHours,
      'emergencyNumber': emergencyNumber,
      'adminSmsNumber': adminSmsNumber,
      'enableSmsAlerts': enableSmsAlerts,
      'smsGatewayProvider': smsGatewayProvider,
      'smsApiKey': smsApiKey,
      'smsSenderId': smsSenderId,
      'smsCustomUrl': smsCustomUrl,
    };
  }
}

class UserReview {
  final String id;
  final String userName;
  final String district;
  final double rating;
  final String comment;
  final String? serviceCategory;
  final DateTime createdAt;

  UserReview({
    required this.id,
    required this.userName,
    required this.district,
    required this.rating,
    required this.comment,
    this.serviceCategory,
    required this.createdAt,
  });

  factory UserReview.fromMap(Map<String, dynamic> data, String id) {
    return UserReview(
      id: id,
      userName: data['userName'] ?? 'Customer',
      district: data['district'] ?? 'Kerala',
      rating: (data['rating'] ?? 5.0).toDouble(),
      comment: data['comment'] ?? '',
      serviceCategory: data['serviceCategory'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'district': district,
      'rating': rating,
      'comment': comment,
      'serviceCategory': serviceCategory,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

