import 'package:flutter/material.dart';

// ================== SecondPage ==================
class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _multiplications = [
    '((942÷3)+10)−18',      // 314
    '(3184÷2)×1',           // 1592
    '((13070÷2)+7)−2',      // 6535
    '((17958÷2)+1)−1',      // 8979
    '((647692÷2)+50)−50',   // 323846
    '((5286÷2)−7)×1',       // 2643
    '((766558÷2)−7)×1',     // 383279
    '((1005768÷2)+10)−10',  // 502884
    '((3942÷2)+2)−3',       // 1971
    '((1387986÷2)+1)−1',    // 693993
    '((15020÷2)−3)×1',      // 7510
  ];

  final List<int> _answers = [
    314, 1592, 6535, 8979, 323846, 2643, 383279, 502884, 1971, 693993, 7510
  ];

  int _currentMultiplicationIndex = 0;
  late DateTime _startTime;
  final List<int> _times = [];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _controller.clear();
      } else if (value == 'BS') {
        if (_controller.text.isNotEmpty) {
          _controller.text =
              _controller.text.substring(0, _controller.text.length - 1);
        }
      } else {
        _controller.text += value;

        Future.delayed(const Duration(milliseconds: 500), () {
          int? userAnswer = int.tryParse(_controller.text);
          if (userAnswer != null &&
              userAnswer == _answers[_currentMultiplicationIndex]) {
            _showTemporaryScreen(); // 正解画面を表示
          }
        });
      }
    });
  }

  void _showTemporaryScreen() async {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
            const TemporaryScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    Navigator.pop(context);

    setState(() {
      _times.add(DateTime.now().difference(_startTime).inSeconds);
      _controller.clear();

      if (_currentMultiplicationIndex >= _multiplications.length - 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FinishPage(times: _times),
          ),
        );
      } else {
        _startTime = DateTime.now();
      }
    });

    // インデックス更新
    if (_currentMultiplicationIndex < _multiplications.length - 1) {
      _currentMultiplicationIndex++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('計算画面'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _multiplications[_currentMultiplicationIndex],
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.calculate, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  mainAxisExtent: MediaQuery.of(context).size.width / 5.5,
                ),
                itemCount: 12,
                itemBuilder: (BuildContext context, int index) {
                  List<String> buttons = [
                    '1', '2', '3',
                    '4', '5', '6',
                    '7', '8', '9',
                    'C', '0', 'BS'
                  ];
                  return ElevatedButton(
                    onPressed: () => _onButtonPressed(buttons[index]),
                    child: Text(
                      buttons[index],
                      style: const TextStyle(fontSize: 24),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== TemporaryScreen ==================
class TemporaryScreen extends StatelessWidget {
  const TemporaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '正解!',
          style: const TextStyle(fontSize: 54),
        ),
      ),
    );
  }
}

// ================== FinishPage ==================
class FinishPage extends StatelessWidget {
  final List<int> times;

  const FinishPage({super.key, required this.times});

  @override
  Widget build(BuildContext context) {
    int totalTime = times.fold(0, (sum, time) => sum + time);
    double averageTime = totalTime / times.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('終了'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'お疲れ様だね',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StartPage(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('スタートに戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== StartPage ==================
class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // ここで SecondPage に遷移
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecondPage()),
            );
          },
          child: const Text(
            'スタート',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

// ================== main() & MyApp ==================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '計算ゲーム',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StartPage(),
    );
  }
}
