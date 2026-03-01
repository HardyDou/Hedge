import 'package:flutter/cupertino.dart';

class AlphabetIndexBar extends StatefulWidget {
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
  State<AlphabetIndexBar> createState() => _AlphabetIndexBarState();
}

class _AlphabetIndexBarState extends State<AlphabetIndexBar> {
  String? _currentLetter;
  bool _isActive = false;

  static const _allLetters = [
    '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 放大镜覆盖层
          if (_isActive && _currentLetter != null)
            Positioned(
              left: -60,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildMagnifier(),
              ),
            ),
          // 字母索引列
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  const double itemHeight = 16.0;
                  return GestureDetector(
                    onVerticalDragStart: (details) {
                      _handleDragStart(details.localPosition.dy, itemHeight);
                    },
                    onVerticalDragUpdate: (details) {
                      _handleDragUpdate(details.localPosition.dy, itemHeight);
                    },
                    onVerticalDragEnd: (_) => _handleDragEnd(),
                    onVerticalDragCancel: _handleDragEnd,
                    child: Container(
                      color: CupertinoColors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildIndexItems(itemHeight),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMagnifier() {
    return AnimatedOpacity(
      opacity: _isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: widget.isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            _currentLetter ?? '',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: widget.isDark
                  ? CupertinoColors.white
                  : CupertinoColors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _handleDragStart(double dy, double itemHeight) {
    setState(() => _isActive = true);
    _updateLetter(dy, itemHeight);
  }

  void _handleDragUpdate(double dy, double itemHeight) {
    _updateLetter(dy, itemHeight);
  }

  void _handleDragEnd() {
    setState(() {
      _isActive = false;
      _currentLetter = null;
    });
  }

  void _updateLetter(double dy, double itemHeight) {
    final index = (dy / itemHeight).floor().clamp(0, _allLetters.length - 1);
    final letter = _allLetters[index];
    
    if (_currentLetter != letter) {
      setState(() => _currentLetter = letter);
      widget.onLetterSelected(letter);
    }
  }

  List<Widget> _buildIndexItems(double itemHeight) {
    return _allLetters.map((letter) {
      final isActive = widget.letters.contains(letter);
      final isSelected = _currentLetter == letter;
      
      return SizedBox(
        height: itemHeight,
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? (widget.isDark ? CupertinoColors.white : CupertinoColors.black)
                  : (widget.isDark
                      ? CupertinoColors.white.withValues(alpha: 0.3)
                      : CupertinoColors.black.withValues(alpha: 0.3)),
            ),
          ),
        ),
      );
    }).toList();
  }
}
