import 'package:flutter/material.dart';
import 'package:flutter_flip_card/controllers/flip_card_controllers.dart';
import 'package:flutter_flip_card/flipcard/flip_card.dart';
import 'package:flutter_flip_card/modal/flip_side.dart';
import 'package:quizlet_final_flutter/study/firebase_study_page.dart';
import 'package:quizlet_final_flutter/study/word/text_to_speech.dart';

class WordItem extends StatefulWidget {
  final String word;
  final String definition;
  final String status;
  final String isFavorited;
  final String wordId;
  final String topicId;

  const WordItem({
    Key? key,
    required this.word,
    required this.definition,
    required this.wordId,
    required this.topicId,
    required this.status,
    required this.isFavorited,
  }) : super(key: key);

  @override
  State<WordItem> createState() => _WordItemState();
}

class _WordItemState extends State<WordItem> {
  final flip = FlipCardController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: FlipCard(
        controller: flip,
        onTapFlipping: true,
        rotateSide: RotateSide.bottom,
        frontWidget: _buildFront(),
        backWidget: _buildBack(),
      ),
    );
  }

  Widget _buildFront() {
    return Card(
      key: const ValueKey('front'),
      color: const Color.fromARGB(255, 0, 191, 255),
      elevation: 10,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () {
                  speak(widget.word);
                  print("volume_down_rounded icon clicked");
                },
                child: const Icon(
                  Icons.volume_down_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            Center(
              child: Text(
                widget.word,
                style: const TextStyle(fontSize: 35, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Card(
      key: const ValueKey('back'),
      color: const Color.fromARGB(255, 0, 191, 255),
      elevation: 10,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: Text(
                widget.definition,
                style: const TextStyle(fontSize: 35, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
