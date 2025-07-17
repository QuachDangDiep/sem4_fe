class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String sentBy;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.sentBy,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['sentAt']),
      sentBy: json['sentBy'],
    );
  }
}
