class Video {
  String? id;
  final String language;
  final String videoUrl;
  final int key;
  final List<String>? notes;
  final List<String>? questions;
  final List<String>? fileUrls; // Ek dosyalar için

  Video({
    this.id,
    required this.language,
    required this.videoUrl,
    required this.key,
    this.notes,
    this.questions,
    this.fileUrls,
  });

  // Firestore'dan veri çekerken kullanılacak
  factory Video.fromMap(Map<String, dynamic> map, String documentId) {
    return Video(
      id: documentId,
      language: map['language'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      key: map['key'] ?? 0,
      notes: map['notes'] != null ? List<String>.from(map['notes']) : [],
      questions:
          map['questions'] != null ? List<String>.from(map['questions']) : [],
      fileUrls:
          map['fileUrls'] != null ? List<String>.from(map['fileUrls']) : [],
    );
  }

  // JSON'dan dönüştürmek için (eski kod uyumluluğu)
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'],
      language: json['language'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      key: json['key'] ?? 0,
      notes: json['notes'] != null ? List<String>.from(json['notes']) : [],
      questions:
          json['questions'] != null ? List<String>.from(json['questions']) : [],
      fileUrls:
          json['fileUrls'] != null ? List<String>.from(json['fileUrls']) : [],
    );
  }

  // Firestore'a kaydetmek için
  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'videoUrl': videoUrl,
      'key': key,
      'notes': notes ?? [],
      'questions': questions ?? [],
      'fileUrls': fileUrls ?? [],
    };
  }

  // JSON'a dönüştürmek için
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'videoUrl': videoUrl,
      'key': key,
      'notes': notes ?? [],
      'questions': questions ?? [],
      'fileUrls': fileUrls ?? [],
    };
  }

  // Video kopyalama metodları
  Video copyWith({
    String? id,
    String? language,
    String? videoUrl,
    int? key,
    List<String>? notes,
    List<String>? questions,
    List<String>? fileUrls,
  }) {
    return Video(
      id: id ?? this.id,
      language: language ?? this.language,
      videoUrl: videoUrl ?? this.videoUrl,
      key: key ?? this.key,
      notes: notes ?? this.notes,
      questions: questions ?? this.questions,
      fileUrls: fileUrls ?? this.fileUrls,
    );
  }

  @override
  String toString() {
    return 'Video{id: $id, language: $language, key: $key, videoUrl: ${videoUrl.length > 50 ? '${videoUrl.substring(0, 50)}...' : videoUrl}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Video &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          language == other.language &&
          key == other.key;

  @override
  int get hashCode => id.hashCode ^ language.hashCode ^ key.hashCode;
}
