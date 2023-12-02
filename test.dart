import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Flutter Blackjack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlackjackPage(),
    );
  }
}

final blackjackProvider =
    StateNotifierProvider<BlackjackNotifier, BlackjackState>((ref) {
  return BlackjackNotifier();
});

class BlackjackNotifier extends StateNotifier<BlackjackState> {
  BlackjackNotifier() : super(BlackjackState.initial());

  void startGame() {
    state = BlackjackState.initial();
    hit();
    hit();
    // ディーラーのカードを2枚追加（裏面表示）
    state = state.copyWith(dealerCards: List.filled(2, CardModel.back()));
  }

  void hit() {
    final random = Random();
    CardModel newCard = CardModel(
      suit: CardSuit.values[random.nextInt(CardSuit.values.length)],
      value: CardValue.values[random.nextInt(CardValue.values.length)],
      faceUp: true,
    );
    state = state.copyWith(
      cards: [...state.cards, newCard],
      score: calculateScore([...state.cards, newCard]),
    );
    if (state.score > 21) {
      state = state.copyWith(status: GameStatus.busted);
    }
  }

  void stand() {
    // プレイヤーが降りる処理
    // ここではディーラーのカードを公開するシンプルな処理にしています
    state = state.copyWith(
        dealerCards:
            state.dealerCards.map((c) => c.copyWith(faceUp: true)).toList());
  }

  void reset() {
    state = BlackjackState.initial();
  }

  int calculateScore(List<CardModel> cards) {
    int score = 0;
    int aceCount = 0;

    for (var card in cards) {
      if (!card.faceUp) continue; // カードが裏向きの場合はスキップ

      if (card.value == CardValue.ace) {
        aceCount++;
        score += 11;
      } else if (card.value != null) {
        // CardValueがnullでない場合のみスコアに加算
        score += card.value!.value;
      }
    }

    while (score > 21 && aceCount > 0) {
      score -= 10;
      aceCount--;
    }

    return score;
  }
}

enum CardSuit { hearts, diamonds, clubs, spades }

enum CardValue {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace
}

extension CardValueExtension on CardValue {
  String get label {
    switch (this) {
      case CardValue.ace:
        return 'A';
      case CardValue.two:
        return '2';
      case CardValue.three:
        return '3';
      case CardValue.four:
        return '4';
      case CardValue.five:
        return '5';
      case CardValue.six:
        return '6';
      case CardValue.seven:
        return '7';
      case CardValue.eight:
        return '8';
      case CardValue.nine:
        return '9';
      case CardValue.ten:
        return '10';
      case CardValue.jack:
        return 'J';
      case CardValue.queen:
        return 'Q';
      case CardValue.king:
        return 'K';
      default:
        return '';
    }
  }

  int get value {
    switch (this) {
      case CardValue.ace:
        return 11;
      case CardValue.jack:
      case CardValue.queen:
      case CardValue.king:
        return 10;
      default:
        return index + 2;
    }
  }
}

extension CardSuitExtension on CardSuit {
  String get symbol {
    switch (this) {
      case CardSuit.hearts:
        return '\u2665'; // ハート
      case CardSuit.diamonds:
        return '\u2666'; // ダイヤ
      case CardSuit.clubs:
        return '\u2663'; // クラブ
      case CardSuit.spades:
        return '\u2660'; // スペード
      default:
        return '';
    }
  }
}

class CardModel {
  final CardSuit? suit;
  final CardValue? value;
  final bool faceUp;

  CardModel({this.suit, this.value, this.faceUp = false});

  CardModel.back()
      : suit = null,
        value = null,
        faceUp = false;

  @override
  String toString() {
    if (!faceUp) return 'Card Back';
    return '${value!.label} of ${suit!.name}';
  }

  CardModel copyWith({CardSuit? suit, CardValue? value, bool? faceUp}) {
    return CardModel(
      suit: suit ?? this.suit,
      value: value ?? this.value,
      faceUp: faceUp ?? this.faceUp,
    );
  }
}

enum GameStatus { playing, busted }

class BlackjackState {
  final List<CardModel> cards;
  final List<CardModel> dealerCards;
  final int score;
  final GameStatus status;

  BlackjackState(
      {required this.cards,
      required this.dealerCards,
      required this.score,
      required this.status});

  factory BlackjackState.initial() {
    return BlackjackState(
        cards: [], dealerCards: [], score: 0, status: GameStatus.playing);
  }

  BlackjackState copyWith(
      {List<CardModel>? cards,
      List<CardModel>? dealerCards,
      int? score,
      GameStatus? status}) {
    return BlackjackState(
      cards: cards ?? this.cards,
      dealerCards: dealerCards ?? this.dealerCards,
      score: score ?? this.score,
      status: status ?? this.status,
    );
  }
}

class BlackjackPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blackjackProvider);
    final notifier = ref.read(blackjackProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Blackjack'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Your Cards:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  state.cards.map((card) => CardWidget(card: card)).toList(),
            ),
            Text('Score: ${state.score}'),
            Text('Dealer Cards:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: state.dealerCards
                  .map((card) => CardWidget(card: card))
                  .toList(),
            ),
            if (state.status == GameStatus.playing)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => notifier.hit(),
                    child: Text('Hit'),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => notifier.stand(),
                    child: Text('Stand'),
                  ),
                ],
              ),
            ElevatedButton(
              onPressed: () => notifier.reset(),
              child: Text('Reset'),
            ),
            if (state.status == GameStatus.busted) Text('Busted!'),
          ],
        ),
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final CardModel card;

  const CardWidget({Key? key, required this.card}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 100,
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: card.faceUp ? Colors.white : Colors.grey,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: card.faceUp
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text(card.value?.label ?? '',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(card.suit?.symbol ?? '',
                    style: TextStyle(fontSize: 18)), // Unicode記号を使用
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationX(pi), // 上下反転
                  child: Text(card.value?.label ?? '',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          : Center(child: Text('Card Back', style: TextStyle(fontSize: 18))),
    );
  }
}
