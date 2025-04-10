import 'package:flutter/material.dart';

class PiDigitsScreen extends StatefulWidget {
  final int highScore;
  const PiDigitsScreen({Key? key, required this.highScore}) : super(key: key);

  @override
  State<PiDigitsScreen> createState() => _PiDigitsScreenState();
}

class _PiDigitsScreenState extends State<PiDigitsScreen> {
  String? _rawDigits;
  int _displayLimit = 5000;
  static const int _chunkSize = 5000;

  Future<void> _loadDigits() async {
    final raw = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/pi_digits.txt');
    setState(() {
      _rawDigits = raw.replaceAll(RegExp(r'\s+'), '');
    });
  }

  String _formatDigits(String raw, int limit) {
    final buffer = StringBuffer();
    int count = 0;

    for (int i = 0; i < raw.length && i < limit; i++) {
      buffer.write(raw[i]);
      count++;

      if (count % 10 == 0 && count % 20 != 0) {
        buffer.write(' ');
      }
      if (count % 20 == 0) {
        buffer.write('\n');
      }
      if (count % 100 == 0) {
        buffer.write('\n\n\n');
      }
    }

    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadDigits();
  }

  @override
  Widget build(BuildContext context) {
    if (_rawDigits == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final formatted = _formatDigits(_rawDigits!, _displayLimit);
    int nonSpaceCount = 0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white10,
            border: Border(bottom: BorderSide(color: Colors.white24)),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 子の高さを広げる
            children: [
              // 戻るボタン（左側）
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // 戻る先がない場合の処理をここに記述
                  }
                },
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8), // 縦方向の微調整
                  alignment: Alignment.bottomLeft,
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              // タイトルテキスト（中央）
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter, // テキストを下寄せに配置
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8), // テキスト下に余白を追加
                    child: const Text(
                      '(｡ )( ｡)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.pinkAccent,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              // 右側に同じ幅のスペースを確保（中央寄せのため）
              const SizedBox(width: 28),
            ],
          ),
        ),
      ),

      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: RichText(
                text: TextSpan(
                  children:
                      formatted.characters.map((char) {
                        bool isCorrect = false;
                        if (!RegExp(r'\s').hasMatch(char)) {
                          isCorrect = nonSpaceCount < widget.highScore;
                          nonSpaceCount++;
                        }
                        return TextSpan(
                          text: char,
                          style: TextStyle(
                            color:
                                isCorrect
                                    ? Colors.lightBlueAccent
                                    : Colors.white,
                            fontSize: 18,
                            fontFamily: 'Courier',
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
          if (_displayLimit < _rawDigits!.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _displayLimit += _chunkSize;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[900],
                  foregroundColor: Colors.lightBlueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 12.0,
                  ),
                ),
                child: const Text("もっと表示する"),
              ),
            ),
        ],
      ),
    );
  }
}
