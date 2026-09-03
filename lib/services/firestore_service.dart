import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // CATEGORIES (Dynamic Worker Categories)
  // ==========================================
  Future<void> createCategory(WorkerCategory category) async {
    await _db.collection('categories').doc(category.id).set(category.toMap());
  }

  Stream<List<WorkerCategory>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => WorkerCategory.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    await _db.collection('categories').doc(categoryId).update(data);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.collection('categories').doc(categoryId).delete();
  }

  // Complete List of Kerala Top Categories
  List<WorkerCategory> get keralaDefaultCategories => [
    WorkerCategory(id: 'electrician', name: 'Electrician (ഇലക്ട്രീഷ്യൻ)', icon: 'electric_bolt', colorValue: 0xFFEAB308),
    WorkerCategory(id: 'plumber', name: 'Plumber (പ്ലംബർ)', icon: 'plumbing', colorValue: 0xFF0284C7),
    WorkerCategory(id: 'driver', name: 'Driver (ഡ്രൈവർ)', icon: 'directions_car', colorValue: 0xFF06B6D4),
    WorkerCategory(id: 'mason', name: 'Mason (മേസൻ / തേപ്പ്)', icon: 'foundation', colorValue: 0xFFD97706),
    WorkerCategory(id: 'painter', name: 'Painter (പെയിന്റർ)', icon: 'format_paint', colorValue: 0xFFEC4899),
    WorkerCategory(id: 'carpenter', name: 'Carpenter (ആശാരി / കാർപെന്റർ)', icon: 'carpenter', colorValue: 0xFF8B5CF6),
    WorkerCategory(id: 'welder', name: 'Welder (വെൽഡർ / ഫാബ്രിക്കേഷൻ)', icon: 'construction', colorValue: 0xFF64748B),
    WorkerCategory(id: 'cleaning', name: 'Cleaning & Housemaid (ക്ലീനിംഗ്)', icon: 'cleaning_services', colorValue: 0xFF10B981),
    WorkerCategory(id: 'helper', name: 'Helper (ഹെൽപ്പർ / ചുമട്ടുതൊഴിലാളി)', icon: 'pan_tool_alt', colorValue: 0xFFF97316),
    WorkerCategory(id: 'ac_mechanic', name: 'AC & Fridge Mechanic (എ.സി റിപ്പയർ)', icon: 'ac_unit', colorValue: 0xFF3B82F6),
    WorkerCategory(id: 'cctv_technician', name: 'CCTV Technician (സി.സി.ടി.വി)', icon: 'videocam', colorValue: 0xFF6366F1),
    WorkerCategory(id: 'tile_layer', name: 'Tiles & Granite (ടൈൽസ് പണിക്കാരൻ)', icon: 'grid_view', colorValue: 0xFF0D9488),
    WorkerCategory(id: 'coconut_climber', name: 'Coconut Climber (തെങ്ങുകയറ്റം / മരംവെട്ട്)', icon: 'park', colorValue: 0xFF16A34A),
    WorkerCategory(id: 'home_nurse', name: 'Home Nurse & Caretaker (ഹോം നഴ്സ്)', icon: 'medical_services', colorValue: 0xFFE11D48),
    WorkerCategory(id: 'gardener', name: 'Gardener (തോട്ടപ്പണി / ഗാർഡനർ)', icon: 'yard', colorValue: 0xFF65A30D),
    WorkerCategory(id: 'car_mechanic', name: 'Auto / Car Mechanic (വർക്ക്ഷോപ്പ് മെക്കാനിക്ക്)', icon: 'build', colorValue: 0xFF78716C),
    WorkerCategory(id: 'cook', name: 'Cook & Catering (പാചകക്കാരൻ / കുക്ക്)', icon: 'restaurant', colorValue: 0xFFEA580C),
    WorkerCategory(id: 'delivery', name: 'Delivery Boy (ഡെലിവറി ബോയ്)', icon: 'two_wheeler', colorValue: 0xFF4F46E5),
  ];

  // Seed default categories
  Future<void> seedAllKeralaCategories() async {
    for (var cat in keralaDefaultCategories) {
      await createCategory(cat);
    }
  }

  Future<void> seedDefaultCategoriesIfEmpty() async {
    final snap = await _db.collection('categories').limit(1).get();
    if (snap.docs.isEmpty) {
      await seedAllKeralaCategories();
    }
  }

  // ==========================================
  // DISTRICTS (Dynamic Kerala Districts)
  // ==========================================
  List<String> get keralaDefaultDistricts => [
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

  Stream<List<String>> getDistrictsStream() {
    return _db
        .collection('system_settings')
        .doc('districts')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final List<dynamic>? list = snapshot.data()?['list'];
        if (list != null && list.isNotEmpty) {
          return list.map((e) => e.toString()).toList();
        }
      }
      return keralaDefaultDistricts;
    });
  }

  Future<void> updateDistricts(List<String> districts) async {
    await _db.collection('system_settings').doc('districts').set({
      'list': districts,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addDistrict(String newLocation) async {
    final clean = newLocation.trim();
    if (clean.isEmpty) return;
    final doc = await _db.collection('system_settings').doc('districts').get();
    List<String> current = [];
    if (doc.exists && doc.data() != null && doc.data()?['list'] != null) {
      current = List<String>.from(doc.data()!['list']);
    } else {
      current = List<String>.from(keralaDefaultDistricts);
    }
    if (!current.contains(clean)) {
      current.add(clean);
      await updateDistricts(current);
    }
  }

  Future<void> deleteDistrict(String location) async {
    final doc = await _db.collection('system_settings').doc('districts').get();
    List<String> current = [];
    if (doc.exists && doc.data() != null && doc.data()?['list'] != null) {
      current = List<String>.from(doc.data()!['list']);
    } else {
      current = List<String>.from(keralaDefaultDistricts);
    }
    current.remove(location);
    await updateDistricts(current);
  }

  Future<void> resetDistrictsToDefault() async {
    await updateDistricts(keralaDefaultDistricts);
  }

  // ==========================================
  // BOOKINGS
  // ==========================================
  Future<void> createBooking(Booking booking) async {
    await _db.collection('bookings').doc(booking.id).set(booking.toMap());
  }

  Stream<List<Booking>> getBookings() {
    return _db
        .collection('bookings')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({'status': status});
  }

  Future<void> assignWorkerToBooking(String bookingId, String workerName) async {
    await _db.collection('bookings').doc(bookingId).update({
      'assignedWorkerId': workerName,
      'status': 'Worker Assigned',
    });
  }

  Future<void> markCustomerPaid(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({'isCustomerPaid': true});
  }

  Future<void> markWorkerPaid(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({'isWorkerPaid': true});
  }

  Future<void> deleteBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).delete();
  }

  Future<void> updateBooking(String bookingId, Map<String, dynamic> data) async {
    await _db.collection('bookings').doc(bookingId).update(data);
  }

  // ==========================================
  // JOBS
  // ==========================================
  Future<void> createJob(Job job) async {
    await _db.collection('jobs').doc(job.id).set(job.toMap());
  }

  Stream<List<Job>> getJobs() {
    return _db.collection('jobs').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Job.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await _db.collection('jobs').doc(jobId).update({'status': status});
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    await _db.collection('jobs').doc(jobId).update(data);
  }

  Future<void> deleteJob(String jobId) async {
    await _db.collection('jobs').doc(jobId).delete();
  }

  // ==========================================
  // JOB APPLICATIONS
  // ==========================================
  Future<void> createJobApplication(JobApplication application) async {
    await _db.collection('job_applications').doc(application.id).set(application.toMap());
  }

  Stream<List<JobApplication>> getJobApplications() {
    return _db.collection('job_applications').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => JobApplication.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateJobApplicationStatus(String applicationId, String status) async {
    await _db.collection('job_applications').doc(applicationId).update({'status': status});
  }

  Future<void> deleteJobApplication(String applicationId) async {
    await _db.collection('job_applications').doc(applicationId).delete();
  }

  // ==========================================
  // WORKERS DIRECTORY
  // ==========================================
  Future<void> createWorker(Worker worker) async {
    await _db.collection('workers').doc(worker.id).set(worker.toMap());
  }

  Stream<List<Worker>> getWorkers() {
    return _db.collection('workers').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Worker.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateWorker(String workerId, Map<String, dynamic> data) async {
    await _db.collection('workers').doc(workerId).update(data);
  }

  Future<void> toggleWorkerStatus(String workerId, bool currentStatus) async {
    await _db.collection('workers').doc(workerId).update({'isActive': !currentStatus});
  }

  Future<void> deleteWorker(String workerId) async {
    await _db.collection('workers').doc(workerId).delete();
  }

  // ==========================================
  // SYSTEM SETTINGS & CONTACT INFO
  // ==========================================
  Stream<ContactInfo> getContactInfoStream() {
    return _db
        .collection('system_settings')
        .doc('contact_info')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return ContactInfo.fromMap(snapshot.data()!);
      }
      return ContactInfo();
    });
  }

  Future<ContactInfo> getContactInfo() async {
    final doc = await _db.collection('system_settings').doc('contact_info').get();
    if (doc.exists && doc.data() != null) {
      return ContactInfo.fromMap(doc.data()!);
    }
    return ContactInfo();
  }

  Future<void> updateContactInfo(ContactInfo info) async {
    await _db
        .collection('system_settings')
        .doc('contact_info')
        .set(info.toMap(), SetOptions(merge: true));
  }

  // ==========================================
  // REVIEWS & RATINGS
  // ==========================================
  Future<void> createReview(UserReview review) async {
    final docRef = review.id.isNotEmpty
        ? _db.collection('reviews').doc(review.id)
        : _db.collection('reviews').doc();
    final updated = UserReview(
      id: docRef.id,
      userName: review.userName,
      district: review.district,
      rating: review.rating,
      comment: review.comment,
      serviceCategory: review.serviceCategory,
      createdAt: review.createdAt,
    );
    await docRef.set(updated.toMap());
  }

  Stream<List<UserReview>> getReviewsStream() {
    return _db
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserReview.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteReview(String reviewId) async {
    await _db.collection('reviews').doc(reviewId).delete();
  }

  Future<void> seedDefaultReviewsIfEmpty() async {
    final snap = await _db.collection('reviews').limit(1).get();
    if (snap.docs.isEmpty) {
      final defaultReviews = [
        UserReview(
          id: 'rev_1',
          userName: 'Faizal Rahman',
          district: 'Kozhikode',
          rating: 5.0,
          comment: 'വീട്ടിലെ പ്ലംബിംഗ് പ്രശ്നം അരമണിക്കൂറിൽ പരിഹരിച്ചു തന്നു. വളരെ നല്ല സേവനം!',
          serviceCategory: 'Plumber (പ്ലംബർ)',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        UserReview(
          id: 'rev_2',
          userName: 'Anil Kumar',
          district: 'Ernakulam (Kochi)',
          rating: 5.0,
          comment: 'പെയിന്റിംഗ് ജോലിക്കായി 4 ആളുകളെ എടുത്തു. കൃത്യസമയത്ത് വന്ന് പണി തീർത്തു.',
          serviceCategory: 'Painter (പെയിന്റർ)',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        UserReview(
          id: 'rev_3',
          userName: 'Shameer K.',
          district: 'Malappuram',
          rating: 4.8,
          comment: 'ഇലക്ട്രിക്കൽ വയറിംഗ് മാറ്റാൻ ആളെ കിട്ടാൻ വലിയ ഉപകാരമായി. ന്യായമായ കൂലി.',
          serviceCategory: 'Electrician (ഇലക്ട്രീഷ്യൻ)',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];

      for (var r in defaultReviews) {
        await createReview(r);
      }
    }
  }
}


