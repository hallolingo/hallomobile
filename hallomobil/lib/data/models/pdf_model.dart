class Pdf {
  String? id;
  String language;
  String pdfUrl;
  String name; // New field for the PDF file name
  List<String>? notes;
  List<String>? questions;

  Pdf({
    this.id,
    required this.language,
    required this.pdfUrl,
    required this.name,
    this.notes,
    this.questions,
  });

  // Convert Pdf object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'pdfUrl': pdfUrl,
      'name': name,
      'notes': notes ?? [],
      'questions': questions ?? [],
    };
  }

  // Create Pdf object from Firestore document
  factory Pdf.fromMap(String id, Map<String, dynamic> map) {
    return Pdf(
      id: id,
      language: map['language'] ?? '',
      pdfUrl: map['pdfUrl'] ?? '',
      name: map['name'] ?? 'Untitled',
      notes: List<String>.from(map['notes'] ?? []),
      questions: List<String>.from(map['questions'] ?? []),
    );
  }
}
