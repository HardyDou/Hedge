import 'package:flutter/cupertino.dart';

class AlphabetIndexBar extends StatelessWidget {
  final List<String> letters;
  final Function(String) onLetterSelected;
  final bool isDark;

  const AlphabetIndexBar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemHeight = constraints.maxHeight / 27;
                return GestureDetector(
                  onVerticalDragUpdate: (details) {
                    _handleDrag(details.localPosition.dy, itemHeight);
                  },
                  onVerticalDragStart: (details) {
                    _handleDrag(details.localPosition.dy, itemHeight);
                  },
                  child: Container(
                    color: CupertinoColors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: _buildIndexItems(itemHeight),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrag(double dy, double itemHeight) {
    final index = (dy / itemHeight).floor().clamp(0, letters.length - 1);
    onLetterSelected(letters[index]);
  }

  List<Widget> _buildIndexItems(double itemHeight) {
    const allLetters = [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#'
    ];

    return allLetters.map((letter) {
      final isActive = letters.contains(letter);
      return SizedBox(
        height: itemHeight,
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                  : (isDark
                      ? CupertinoColors.white.withValues(alpha: 0.3)
                      : CupertinoColors.black.withValues(alpha: 0.3)),
            ),
          ),
        ),
      );
    }).toList();
  }
}
