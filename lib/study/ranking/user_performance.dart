import 'package:cloud_firestore/cloud_firestore.dart';

class UserPerformance {
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String topicId;
  final int correctAnswers;
  final DateTime timeTaken;
  final int completionCount;
  final DateTime lastStudied;

  UserPerformance({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.topicId,
    required this.correctAnswers,
    required this.timeTaken,
    required this.completionCount,
    required this.lastStudied,
  });

  factory UserPerformance.fromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>;
    return UserPerformance(
      userId: data['userId'],
      userName: data['userName'],
      userAvatar: data['userAvatar'],
      topicId: data['topicId'],
      correctAnswers: data['correctAnswers'] ?? 0,
      timeTaken: (data['timeTaken'] as Timestamp).toDate(),
      completionCount: data['completionCount'] ?? 0,
      lastStudied: (data['lastStudied'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'topicId': topicId,
      'correctAnswers': correctAnswers,
      'timeTaken': timeTaken,
      'completionCount': completionCount,
      'lastStudied': lastStudied,
    };
  }
}

Future<void> saveUserPerformance(
    String topicId,
    String userUid,
    String userName,
    String userAvatar,
    DateTime timeTaken,
    int numberOfCorrectAnswers,
    {bool updateCompletionCount = true}
    ) async {
  try {
    await FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .collection('access')
        .doc(userUid)
        .get()
        .then((DocumentSnapshot accessSnapshot) {
      if (accessSnapshot.exists) {
        UserPerformance userPerformance;

        Map<String, dynamic>? data = accessSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('completionCount') && data.containsKey('correctAnswers') && updateCompletionCount == true) {
          int currentCompletionCount = data['completionCount'] ?? 0;
          print('1');
          userPerformance = UserPerformance(
            userId: userUid,
            topicId: topicId,
            correctAnswers: numberOfCorrectAnswers,
            timeTaken: timeTaken,
            completionCount: currentCompletionCount + 1,
            lastStudied: DateTime.now(),
            userName: userName,
            userAvatar: userAvatar,
          );
        } else {
          int currentCompletionCount = data?['completionCount'];
          print(data?['lastStudied'].toDate());
          print('2');
          userPerformance = UserPerformance(
            userId: userUid,
            topicId: topicId,
            correctAnswers: numberOfCorrectAnswers,
            timeTaken: data?['timeTaken'].toDate(),
            completionCount: currentCompletionCount,
            lastStudied: data?['lastStudied'].toDate(),
            userName: userName,
            userAvatar: userAvatar,
          );
        }
        print('3');
        accessSnapshot.reference
            .set(userPerformance.toMap())
            .then((value) => print('User performance updated successfully'))
            .catchError(
                (error) => print('Failed to update user performance: $error'));
      } else {
        print('4');
        UserPerformance userPerformance = UserPerformance(
          userId: userUid,
          topicId: topicId,
          correctAnswers: 0, // Default value
          timeTaken: timeTaken,
          completionCount: 0,
          lastStudied: DateTime.now(),
          userName: userName,
          userAvatar: userAvatar,
        );

        CollectionReference accessCollection = FirebaseFirestore.instance
            .collection('topics')
            .doc(topicId)
            .collection('access');

        accessCollection
            .doc(userPerformance.userId)
            .set(userPerformance.toMap())
            .then((value) => print('User performance saved successfully'))
            .catchError(
                (error) => print('Failed to save user performance: $error'));
      }
    });
  } catch (e) {
    print('Error saving user performance: $e');
  }
}






