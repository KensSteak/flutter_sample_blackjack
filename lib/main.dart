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
  BlackjackNotifier() : super(BlackjackState.initial()) {
    startGame(); // コンストラクタでゲームを開始
  }

  void startGame() {
    state = BlackjackState.initial();
    // ディーラーのカードを2枚追加（裏面表示）
    state = state.copyWith(dealerCards: [
      state.deck.draw(true),
      state.deck.draw(false),
    ]);
    hit();
    hit();
  }

  void hit() {
    final newCard = state.deck.draw(true);
    final newCards = [...state.cards, newCard];
    final newScore = calculateScore(newCards);

    if (newScore >= 21) {
      var dealerCards =
          state.dealerCards.map((c) => c.copyWith(faceUp: true)).toList();
      var dealerScore = calculateScore(dealerCards);
      endGame(newCards, newScore, dealerCards, dealerScore);
    } else {
      state = state.copyWith(
        cards: newCards,
        score: newScore,
      );
    }
  }

  void stand() {
    // ディーラーの非公開のカードを公開
    var dealerCards =
        state.dealerCards.map((c) => c.copyWith(faceUp: true)).toList();
    var dealerScore = calculateScore(dealerCards);

    // ディーラーのスコアが17以上になるまでカードを引く
    while (dealerScore < 17) {
      dealerCards.add(_createRandomCard(faceUp: true));
      dealerScore = calculateScore(dealerCards);
    }

    endGame(state.cards, state.score, dealerCards, dealerScore);
  }

  void endGame(List<CardModel> playerCards, int playerScore,
      [List<CardModel>? dealerCards, int? dealerScore]) {
    GameStatus status;
    if (playerScore > 21) {
      status = GameStatus.busted;
    } else if (dealerScore != null &&
        (dealerScore > 21 || dealerScore < playerScore)) {
      status = GameStatus.won;
    } else if (dealerScore != null && dealerScore > playerScore) {
      status = GameStatus.lost;
    } else {
      status = GameStatus.draw;
    }

    state = state.copyWith(
      cards: playerCards,
      score: playerScore,
      dealerCards: dealerCards ?? state.dealerCards,
      dealerScore:
          dealerScore ?? calculateScore(state.dealerCards), // ディーラーのスコアを更新
      status: status,
    );
  }

  CardModel _createRandomCard({bool faceUp = true}) {
    final random = Random();
    return CardModel(
      suit: CardSuit.values[random.nextInt(CardSuit.values.length)],
      value: CardValue.values[random.nextInt(CardValue.values.length)],
      faceUp: faceUp,
    );
  }

  void reset() {
    startGame();
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
  bool faceUp;

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

class Deck {
  final List<CardModel> _cards = [];

  Deck() {
    CardSuit.values.forEach((suit) {
      CardValue.values.forEach((value) {
        _cards.add(CardModel(suit: suit, value: value));
      });
    });
  }

  void shuffle() {
    final random = Random();
    for (int i = _cards.length - 1; i > 0; i--) {
      int n = random.nextInt(_cards.length);
      var temp = _cards[i];
      _cards[i] = _cards[n];
      _cards[n] = temp;
    }
  }

  CardModel draw(bool? faceUp) {
    CardModel card = _cards.removeLast();
    card.faceUp = faceUp ?? true;
    return card;
  }
}

enum GameStatus { playing, busted, won, lost, draw }

class BlackjackState {
  final List<CardModel> cards;
  final List<CardModel> dealerCards;
  final int score;
  final int dealerScore; // ディーラーのスコアを追加
  final GameStatus status;
  final Deck deck;

  BlackjackState({
    required this.cards,
    required this.dealerCards,
    required this.score,
    required this.dealerScore, // 初期化リストに追加
    required this.status,
    required this.deck,
  });

  factory BlackjackState.initial() {
    return BlackjackState(
      cards: [],
      dealerCards: [],
      score: 0,
      dealerScore: 0, // 初期値を0に設定
      status: GameStatus.playing,
      deck: Deck()..shuffle(),
    );
  }

  BlackjackState copyWith({
    List<CardModel>? cards,
    List<CardModel>? dealerCards,
    int? score,
    int? dealerScore, // メソッドシグネチャに追加
    GameStatus? status,
    Deck? deck,
  }) {
    return BlackjackState(
      cards: cards ?? this.cards,
      dealerCards: dealerCards ?? this.dealerCards,
      score: score ?? this.score,
      dealerScore: dealerScore ?? this.dealerScore, // 値を更新
      status: status ?? this.status,
      deck: deck ?? this.deck,
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
            Text('Dealer Cards:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: state.dealerCards
                  .map((card) => CardWidget(card: card))
                  .toList(),
            ),
            Text(
                'Dealer Score: ${state.status != GameStatus.playing ? state.dealerScore : 'XX'}'),
            // 横線を表示
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              height: 1,
              width: 100,
              rolor: Colors.black,
            ),
            Text('Your Cards:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  state.cards.map((card) => CardWidget(card: card)).toList(),
            ),
            Text('Score: ${state.score}'),
            SizedBox(height: 20),
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
            if (state.status != GameStatus.playing)
              _buildResultText(state.status),
          ],
        ),
      ),
    );
  }

  Widget _buildResultText(GameStatus status) {
    String text;
    switch (status) {
      case GameStatus.won:
        text = 'You Won!';
        break;
      case GameStatus.lost:
        text = 'You Lost!';
        break;
      case GameStatus.draw:
        text = 'Draw!';
        break;
      case GameStatus.busted:
        text = 'Busted!';
        break;
      default:
        text = '';
    }
    return Text(text,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
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
                Text(card.suit?.symbol ?? '', style: TextStyle(fontSize: 18))
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text(' ', style: TextStyle(fontSize: 18)),
                Text(' ', style: TextStyle(fontSize: 18))
              ],
            ),
    );
  }
}
