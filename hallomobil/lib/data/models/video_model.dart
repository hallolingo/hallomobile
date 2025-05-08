class Video {
  String? id; // Firestore document ID (optional, set after retrieval)
  String language; // Language of the video
  String videoUrl; // URL of the video in Firebase Storage
  int key; // Lesson order or sequence number
  List<String>? notes; // Optional list of notes
  List<String>? questions; // Optional list of questions

  // Constructor
  Video({
    this.id,
    required this.language,
    required this.videoUrl,
    required this.key,
    this.notes = const [],
    this.questions = const [],
  });

  // Factory method to create a Video object from JSON
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String?,
      language: json['language'] as String,
      videoUrl: json['videoUrl'] as String,
      key: json['key'] as int,
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // Method to convert Video object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'videoUrl': videoUrl,
      'key': key,
      'notes': notes ?? [],
      'questions': questions ?? [],
    };
  }
}
