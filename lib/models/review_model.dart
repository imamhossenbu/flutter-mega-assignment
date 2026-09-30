class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReviewModel.fromMap(Map<String, dynamic> map, [String? docId]) => ReviewModel(
        id: docId ?? map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? 'Anonymous',
        rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
        comment: map['comment'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
