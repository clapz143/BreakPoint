import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:audioplayers/audioplayers.dart';void main() => runApp(const MaterialApp(home: PoolGamePage()));class Ball {
  Offset position;
  Offset velocity;
  final Color color;
  final int number;
  bool isPocketed;
  bool isPocketing;
  double pocketAnimationProgress;  Ball(this.position, this.color, this.number, {this.velocity = Offset.zero, this.isPocketed = false})
      : isPocketing = false,
        pocketAnimationProgress = 0.0;
}class PoolGamePage extends StatefulWidget {
  const PoolGamePage({super.key});  @override
  State<PoolGamePage> createState() => _PoolGamePageState();
}class _PoolGamePageState extends State<PoolGamePage> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final double tableWidth = 610;
  final double tableHeight = 310;
  final double ballRadius = 10;
  final double pocketRadius = 17;
  final double railThickness = 12.0;
  final double friction = 0.983;
  final double restitution = 0.9;
  final double minVelocity = 0.1;
  List<Ball> balls = [];
  List<Offset> pockets = [];
  Offset cueVector = Offset.zero;
  bool isAiming = false;
  bool isPlacingCueBall = false;
  double cuePower = 0.05;
  double cueAngle = 0.0;
  Offset spinOffset = Offset.zero;
  String gameMessage = "Player 1: Break";
  bool isPlayer1Turn = true;
  String? player1Type;
  String? player2Type;
  bool gameOver = false;
  bool isTableOpen = true;
  int? firstBallHit;
  bool foulOccurred = false;
  bool hitRailAfterContact = false;
  bool isBreakShot = true;
  late AudioPlayer _audioPlayer;
  bool showSpinControl = false;
  DateTime? _lastCollisionSoundTime;
  List<Ball> pocketedSolids = [];
  List<Ball> pocketedStripes = [];
  bool ballsMoving = false;  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupGame();
    _ticker = createTicker(_update)..start();
  }  void _setupGame() {
    balls.clear();
    pocketedSolids.clear();
    pocketedStripes.clear();
    balls.add(Ball(Offset(tableWidth * 0.25, tableHeight / 2), Colors.white, 0));
    final rackCenter = Offset(tableWidth * 0.75, tableHeight / 2);
    final ballSpacing = ballRadius * 2.1;
    final solids = [Colors.red, Colors.blue, Colors.purple, Colors.orange, Colors.green, Colors.brown, Colors.yellow];
    final stripes = [Colors.red, Colors.blue, Colors.purple, Colors.orange, Colors.green, Colors.brown, Colors.yellow];
    final rack = [
      [1],
      [9, 2],
      [10, 8, 3],
      [4, 11, 12, 5],
      [13, 6, 14, 7, 15],
    ];
    int solidIdx = 0, stripeIdx = 0;
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col <= row; col++) {
        final ballNum = rack[row][col];
        final color = ballNum == 8
            ? Colors.black
            : (ballNum <= 7 ? solids[solidIdx++] : stripes[stripeIdx++]);
        final dx = rackCenter.dx + row * ballSpacing * cos(pi / 6);
        final dy = rackCenter.dy + (col - row / 2) * ballSpacing;
        final boundedDx = dx.clamp(railThickness + ballRadius, tableWidth - railThickness - ballRadius);
        final boundedDy = dy.clamp(railThickness + ballRadius, tableHeight - railThickness - ballRadius);
        balls.add(Ball(Offset(boundedDx, boundedDy), color, ballNum));
      }
    }
    pockets = [
      Offset(railThickness, railThickness),
      Offset(tableWidth / 2, railThickness),
      Offset(tableWidth - railThickness, railThickness),
      Offset(railThickness, tableHeight - railThickness),
      Offset(tableWidth / 2, tableHeight - railThickness),
      Offset(tableWidth - railThickness, tableHeight - railThickness),
    ];
    gameMessage = "Player 1: Break";
    isPlayer1Turn = true;
    isTableOpen = true;
    player1Type = null;
    player2Type = null;
    gameOver = false;
    firstBallHit = null;
    foulOccurred = false;
    hitRailAfterContact = false;
    isBreakShot = true;
    isPlacingCueBall = false;
    ballsMoving = false;
    _lastCollisionSoundTime = null;
  }  void _update(Duration delta) {
    if (gameOver) return;
    setState(() {
      ballsMoving = false;
      for (var ball in balls) {
        if (ball.isPocketed) continue;

        if (ball.isPocketing) {
          ball.pocketAnimationProgress += delta.inMilliseconds / 500.0;
          if (ball.pocketAnimationProgress >= 1.0) {
            ball.isPocketed = true;
            ball.isPocketing = false;
            ball.velocity = Offset.zero;
          }
        } else {
          ball.position += ball.velocity;
          ball.velocity *= friction;
          if (ball.velocity.distance < minVelocity) {
            ball.velocity = Offset.zero;
          } else {
            ballsMoving = true;
          }
          if (ball.position.dx - ballRadius < railThickness) {
            ball.position = Offset(railThickness + ballRadius, ball.position.dy);
            ball.velocity = Offset(-ball.velocity.dx * restitution, ball.velocity.dy);
            if (firstBallHit != null) hitRailAfterContact = true;
          } else if (ball.position.dx + ballRadius > tableWidth - railThickness) {
            ball.position = Offset(tableWidth - railThickness - ballRadius, ball.position.dy);
            ball.velocity = Offset(-ball.velocity.dx * restitution, ball.velocity.dy);
            if (firstBallHit != null) hitRailAfterContact = true;
          }
          if (ball.position.dy - ballRadius < railThickness) {
            ball.position = Offset(ball.position.dx, railThickness + ballRadius);
            ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy * restitution);
            if (firstBallHit != null) hitRailAfterContact = true;
          } else if (ball.position.dy + ballRadius > tableHeight - railThickness) {
            ball.position = Offset(ball.position.dx, tableHeight - railThickness - ballRadius);
            ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy * restitution);
            if (firstBallHit != null) hitRailAfterContact = true;
          }
        }
      }
      _handleCollisions();
      _checkPockets();
      if (!ballsMoving && !isAiming && !isPlacingCueBall) {
        _updateGameState();
      }
    });

  }  void _handleCollisions() {
    List<Map<String, dynamic>> collisions = [];
    for (int i = 0; i < balls.length; i++) {
      for (int j = i + 1; j < balls.length; j++) {
        Ball a = balls[i], b = balls[j];
        if (a.isPocketed || b.isPocketed || a.isPocketing || b.isPocketing) continue;
        final delta = b.position - a.position;
        final dist = delta.distance;
        final minDist = ballRadius * 2;
        if (dist < minDist) {
          final normal = delta / dist;
          final relativeVelocity = b.velocity - a.velocity;
          final speed = relativeVelocity.dx * normal.dx + relativeVelocity.dy * normal.dy;
          if (speed < 0) {
            collisions.add({
              'ballA': a,
              'ballB': b,
              'distance': dist,
              'normal': normal,
              'speed': speed,
            });
          }
        }
      }
    }

    collisions.sort((a, b) => a['distance'].compareTo(b['distance']));

    for (var collision in collisions) {
      Ball a = collision['ballA'];
      Ball b = collision['ballB'];
      final normal = collision['normal'];
      final speed = collision['speed'];
      final minDist = ballRadius * 2;

      final dist = (b.position - a.position).distance;
      if (dist < minDist) {
        final overlap = (minDist - dist) / 2;
        a.position -= normal * overlap;
        b.position += normal * overlap;
      }

      final impulse = normal * speed * restitution;
      a.velocity += impulse;
      b.velocity -= impulse;

      if (a.number == 0 && firstBallHit == null) {
        firstBallHit = b.number;
      } else if (b.number == 0 && firstBallHit == null) {
        firstBallHit = a.number;
      }

      final collisionStrength = (b.velocity - a.velocity).distance;
      const minThreshold = 1.0;
      const maxThreshold = 10.0;
      if (collisionStrength >= minThreshold) {
        final now = DateTime.now();
        if (_lastCollisionSoundTime == null ||
            now.difference(_lastCollisionSoundTime!).inMilliseconds >= 3000) {
          final volume = (collisionStrength - minThreshold) / (maxThreshold - minThreshold);
          _audioPlayer.setVolume(volume.clamp(0.1, 1.0));
          _audioPlayer.play(AssetSource('images/collision.mp3'));
          _lastCollisionSoundTime = now;
        }
      }
    }

  }  void _checkPockets() {
    bool cueBallPocketed = false;
    bool eightBallPocketed = false;
    List<int> pocketedThisTurn = [];
    for (var ball in balls) {
      if (ball.isPocketed || ball.isPocketing) continue;
      for (var pocket in pockets) {
        if ((ball.position - pocket).distance < pocketRadius) {
          ball.isPocketing = true;
          ball.velocity = Offset.zero;
          _audioPlayer.play(AssetSource('images/pocket.mp3'));
          if (ball.number == 0) {
            cueBallPocketed = true;
          } else if (ball.number == 8) {
            eightBallPocketed = true;
          } else {
            pocketedThisTurn.add(ball.number);
            if (ball.number <= 7) {
              pocketedSolids.add(ball);
            } else if (ball.number >= 9) {
              pocketedStripes.add(ball);
            }
          }
        }
      }
    }
    print('Check Pockets: cueBallPocketed=$cueBallPocketed, eightBallPocketed=$eightBallPocketed, pocketedThisTurn=$pocketedThisTurn, firstBallHit=$firstBallHit'); // Debug print
    // Always call _handlePocketedBalls to evaluate shot outcome
    _handlePocketedBalls(cueBallPocketed, eightBallPocketed, pocketedThisTurn);
  }  void _handlePocketedBalls(bool cueBallPocketed, bool eightBallPocketed, List<int> pocketed) {
    print('Handle Pocketed Balls: isBreakShot=$isBreakShot, cueBallPocketed=$cueBallPocketed, pocketed=$pocketed, firstBallHit=$firstBallHit'); // Debug print
    foulOccurred = false;
    final currentPlayerType = isPlayer1Turn ? player1Type : player2Type;
    bool correctTypePocketed = false;
    bool hitCorrectBall = true;

// Check if the first ball hit was correct (if table is not open)
    if (!isTableOpen && currentPlayerType != null && firstBallHit != null) {
      hitCorrectBall = (currentPlayerType == 'solids' && firstBallHit! <= 7 && firstBallHit! != 8) ||
          (currentPlayerType == 'stripes' && firstBallHit! >= 9);
      if (!hitCorrectBall) {
        foulOccurred = true;
      }
    }

// Handle cue ball scratch
    if (cueBallPocketed) {
      foulOccurred = true;
    }

// Handle 8-ball pocketing
    if (eightBallPocketed) {
      final currentPlayer = isPlayer1Turn ? 'Player 1' : 'Player 2';
      bool allPlayerBallsPocketed = true;
      if (currentPlayerType != null) {
        for (var ball in balls) {
          if (ball.isPocketed || ball.number == 0 || ball.number == 8) continue;
          if ((currentPlayerType == 'solids' && ball.number <= 7) ||
              (currentPlayerType == 'stripes' && ball.number >= 9)) {
            allPlayerBallsPocketed = false;
            break;
          }
        }
      }
      if (currentPlayerType == null || !allPlayerBallsPocketed || foulOccurred || !hitCorrectBall) {
        gameMessage = '$currentPlayer pocketed the 8-ball prematurely or fouled. ${isPlayer1Turn ? "Player 2" : "Player 1"} wins!';
        gameOver = true;
      } else {
        gameMessage = '$currentPlayer wins by pocketing the 8-ball!';
        gameOver = true;
      }
      print('Game Over: $gameMessage'); // Debug print
      return;
    }

// Handle break shot
    if (isBreakShot) {
      // Foul: no object ball hit
      if (firstBallHit == null && !cueBallPocketed) {
        foulOccurred = true;
        isPlayer1Turn = !isPlayer1Turn;
        isPlacingCueBall = true;
        gameMessage = "${isPlayer1Turn ? 'Player 1' : 'Player 2'}, place the cue ball due to foul (no ball hit on break).";
        print('Break: Foul (no ball hit), switched to isPlayer1Turn=$isPlayer1Turn, gameMessage=$gameMessage'); // Debug print
      } else if (pocketed.isEmpty && !cueBallPocketed) {
        // No balls pocketed, switch to Player 2
        isPlayer1Turn = !isPlayer1Turn;
        gameMessage = "${isPlayer1Turn ? 'Player 1' : 'Player 2'}'s turn (Table Open)";
        print('Break: No balls pocketed, switched to isPlayer1Turn=$isPlayer1Turn, gameMessage=$gameMessage'); // Debug print
      } else {
        // Balls pocketed, Player 1 continues, table remains open
        bool solidsPocketed = pocketed.any((n) => n <= 7);
        bool stripesPocketed = pocketed.any((n) => n >= 9);
        if (!foulOccurred && (solidsPocketed || stripesPocketed)) {
          if (solidsPocketed && !stripesPocketed) {
            player1Type = isPlayer1Turn ? 'solids' : 'stripes';
            player2Type = isPlayer1Turn ? 'stripes' : 'solids';
            isTableOpen = false;
            correctTypePocketed = true;
          } else if (stripesPocketed && !solidsPocketed) {
            player1Type = isPlayer1Turn ? 'stripes' : 'solids';
            player2Type = isPlayer1Turn ? 'solids' : 'stripes';
            isTableOpen = false;
            correctTypePocketed = true;
          }
        }
        gameMessage = "${isPlayer1Turn ? 'Player 1' : 'Player 2'}'s turn${isTableOpen ? ' (Table Open)' : ' (${isPlayer1Turn ? player1Type : player2Type})'}";
        print('Break: Balls pocketed, isPlayer1Turn=$isPlayer1Turn, isTableOpen=$isTableOpen, gameMessage=$gameMessage'); // Debug print
      }
    } else {
      // Non-break shot logic
      bool solidsPocketed = pocketed.any((n) => n <= 7);
      bool stripesPocketed = pocketed.any((n) => n >= 9);
      if (isTableOpen && (solidsPocketed || stripesPocketed) && !foulOccurred) {
        if (solidsPocketed && !stripesPocketed) {
          player1Type = isPlayer1Turn ? 'solids' : 'stripes';
          player2Type = isPlayer1Turn ? 'stripes' : 'solids';
          isTableOpen = false;
          correctTypePocketed = true;
        } else if (stripesPocketed && !solidsPocketed) {
          player1Type = isPlayer1Turn ? 'stripes' : 'solids';
          player2Type = isPlayer1Turn ? 'solids' : 'stripes';
          isTableOpen = false;
          correctTypePocketed = true;
        }
      } else if (!isTableOpen && currentPlayerType != null) {
        correctTypePocketed = (currentPlayerType == 'solids' && solidsPocketed) ||
            (currentPlayerType == 'stripes' && stripesPocketed);
      } else if (isTableOpen) {
        correctTypePocketed = true;
      }

      if (firstBallHit == null && !cueBallPocketed && !isTableOpen) {
        foulOccurred = true;
        isPlayer1Turn = !isPlayer1Turn;
        isPlacingCueBall = true;
        gameMessage = "${isPlayer1Turn ? 'Player 1' : 'Player 2'}, place the cue ball due to foul (no ball hit).";
        print('Non-break: Foul (no ball hit), switched to isPlayer1Turn=$isPlayer1Turn, gameMessage=$gameMessage'); // Debug print
      } else if (foulOccurred || cueBallPocketed || !hitCorrectBall) {
        isPlayer1Turn = !isPlayer1Turn;
        isPlacingCueBall = true;
        gameMessage = "${isPlayer1Turn ? 'Player 1' : 'Player 2'}, place the cue ball due to foul.";
        print('Non-break: Foul occurred, switched to isPlayer1Turn=$isPlayer1Turn, gameMessage=$gameMessage'); // Debug print
      } else if (correctTypePocketed) {
        gameMessage = "${isPlayer1Turn ? 'Player 1' : 'Player 2'}'s turn${currentPlayerType != null ? ' ($currentPlayerType)' : ' (Table Open)'}";
        print('Non-break: Correct type pocketed, isPlayer1Turn=$isPlayer1Turn, gameMessage=$gameMessage'); // Debug print
      } else {
        isPlayer1Turn = !isPlayer1Turn;
        gameMessage = "${isPlayer1Turn ? 'Player 1' : 'Player 2'}'s turn${isPlayer1Turn ? (player1Type ?? ' (Table Open)') : (player2Type ?? ' (Table Open)')}";
        print('Non-break: No correct type pocketed, switched to isPlayer1Turn=$isPlayer1Turn, gameMessage=$gameMessage'); // Debug print
      }
    }

// Handle cue ball scratch
    if (cueBallPocketed) {
      balls[0].isPocketed = false;
      balls[0].isPocketing = false;
      balls[0].position = Offset(tableWidth * 0.25, tableHeight / 2);
      balls[0].velocity = Offset.zero;
      isPlacingCueBall = true;
    }

// Reset turn-based variables
    firstBallHit = null;
    hitRailAfterContact = false;
    isBreakShot = false;
    print('End of handlePocketedBalls: isPlayer1Turn=$isPlayer1Turn, gameMessage=$gameMessage, isPlacingCueBall=$isPlacingCueBall'); // Debug print

  }  void _updateGameState() {
    if (gameOver) return;
    if (isPlacingCueBall) {
      gameMessage = "${isPlayer1Turn ? 'Player 1' : 'Player 2'}, place the cue ball.";
    } else {
      final currentPlayerType = isPlayer1Turn ? player1Type : player2Type;
      gameMessage = "${isPlayer1Turn ? 'Player 1' : 'Player 2'}'s turn${currentPlayerType != null ? ' ($currentPlayerType)' : ' (Table Open)'}";
    }
  }  void _onPanStart(DragStartDetails details) {
    if (gameOver || ballsMoving) return;
    setState(() {
      if (isPlacingCueBall) {
        final newPos = details.localPosition;
        final boundedPos = Offset(
          newPos.dx.clamp(railThickness + ballRadius, tableWidth - railThickness - ballRadius),
          newPos.dy.clamp(railThickness + ballRadius, tableHeight - railThickness - ballRadius),
        );
        balls[0].position = boundedPos;
        print('Placing cue ball at: $boundedPos'); // Debug print
      } else {
        isAiming = true;
        cueVector = details.localPosition - balls[0].position;
        cueAngle = atan2(cueVector.dy, cueVector.dx);
        print('Started aiming: cueVector = $cueVector, cueAngle = $cueAngle'); // Debug print
      }
    });
  }  void _onPanUpdate(DragUpdateDetails details) {
    if (gameOver || ballsMoving) return;
    setState(() {
      if (isPlacingCueBall) {
        final newPos = details.localPosition;
        final boundedPos = Offset(
          newPos.dx.clamp(railThickness + ballRadius, tableWidth - railThickness - ballRadius),
          newPos.dy.clamp(railThickness + ballRadius, tableHeight - railThickness - ballRadius),
        );
        balls[0].position = boundedPos;
        print('Updated cue ball position: $boundedPos'); // Debug print
      } else if (showSpinControl) {
        // Calculate the relative position within the spin control
        final spinControlCenter = balls[0].position; // Center of the cue ball
        final newSpinOffset = details.localPosition - spinControlCenter;
        // Clamp the spin offset to the range [-ballRadius, ballRadius]
        spinOffset = Offset(
          newSpinOffset.dx.clamp(-ballRadius, ballRadius),
          newSpinOffset.dy.clamp(-ballRadius, ballRadius),
        );
        print('Updated spinOffset: $spinOffset'); // Debug print
      } else {
        cueVector = details.localPosition - balls[0].position;
        cueAngle = atan2(cueVector.dy, cueVector.dx);
        print('Updated aiming: cueVector = $cueVector, cueAngle = $cueAngle'); // Debug print
      }
    });
  }  void _onPanEnd(DragEndDetails _) {
    if (gameOver || ballsMoving) return;
    if (isPlacingCueBall) {
      setState(() {
        isPlacingCueBall = false;
      });
    }
  }  void _shoot() {
    if (!isAiming || gameOver || ballsMoving) return;
    setState(() {
      final velocity = -cueVector.normalized() * cuePower * 200;
      balls[0].velocity = velocity + spinOffset * 0.1;
      cueVector = Offset.zero;
      spinOffset = Offset.zero;
      isAiming = false;
      showSpinControl = false;
      print('Shot taken: isBreakShot=$isBreakShot, isPlayer1Turn=$isPlayer1Turn'); // Debug print
    });
  }  Offset _normalize(Offset vector) {
    final mag = vector.distance;
    return mag > 0 ? vector / mag : Offset.zero;
  }  void _toggleSpinControl() {
    if (ballsMoving) return;
    setState(() {
      showSpinControl = !showSpinControl;
      print('Toggled spin control: showSpinControl = $showSpinControl'); // Debug print
    });
  }  void _resetGame() {
    setState(() {
      _setupGame();
    });
  }  @override
  void dispose() {
    _ticker.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text('8-Ball Pool', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPlayerIndicator('Player 1', player1Type, isPlayer1Turn),
                      _buildPlayerIndicator('Player 2', player2Type, !isPlayer1Turn),
                    ],
                  ),
                ),
                Text(
                  gameMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: tableWidth,
                  height: tableHeight,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: PoolPainter(
                        balls,
                        cueVector,
                        isAiming,
                        pockets,
                        ballRadius,
                        pocketRadius,
                        balls[0].position,
                        cuePower,
                        cueAngle,
                        spinOffset,
                        tableWidth,
                        tableHeight,
                        railThickness,
                        friction,
                        restitution,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pocketed Solids',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8,
                            children: pocketedSolids.map((ball) {
                              return Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ball.color,
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Center(
                                  child: Text(
                                    ball.number.toString(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Pocketed Stripes',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8,
                            children: pocketedStripes.map((ball) {
                              return Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: ball.color,
                                      ),
                                    ),
                                    Text(
                                      ball.number.toString(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Slider(
                        value: cuePower,
                        min: 0.02,
                        max: 0.12,
                        label: "Power: ${(cuePower * 1000).round()}",
                        activeColor: Colors.amber,
                        inactiveColor: Colors.grey,
                        onChanged: gameOver || isPlacingCueBall || ballsMoving
                            ? null
                            : (v) => setState(() => cuePower = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: gameOver ? _resetGame : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Reset Game'),
                          ),
                          ElevatedButton(
                            onPressed: isAiming && !ballsMoving ? _toggleSpinControl : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(showSpinControl ? 'Set Spin' : 'Adjust Spin'),
                          ),
                          ElevatedButton(
                            onPressed: isAiming && !showSpinControl && !ballsMoving ? _shoot : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Shoot'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showSpinControl)
              Positioned(
                left: balls[0].position.dx - 50,
                top: balls[0].position.dy - 50,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final newSpinOffset = details.localPosition - const Offset(50, 50); // Center of the 100x100 spin control
                      spinOffset = Offset(
                        newSpinOffset.dx.clamp(-ballRadius, ballRadius),
                        newSpinOffset.dy.clamp(-ballRadius, ballRadius),
                      );
                      print('Spin control drag: spinOffset = $spinOffset'); // Debug print
                    });
                  },
                  onPanEnd: (details) {
                    print('Spin control drag ended: final spinOffset = $spinOffset'); // Debug print
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Positioned(
                          left: 40 + spinOffset.dx * 2,
                          top: 40 + spinOffset.dy * 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade900,
    );
  }  Widget _buildPlayerIndicator(String name, String? type, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.amber.withOpacity(0.8) : Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                type ?? 'Unassigned',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}class PoolPainter extends CustomPainter {
  final List<Ball> balls;
  final Offset cueVector;
  final bool isAiming;
  final List<Offset> pockets;
  final double ballRadius;
  final double pocketRadius;
  final Offset cueBallPos;
  final double cuePower;
  final double cueAngle;
  final Offset spinOffset;
  final double tableWidth;
  final double tableHeight;
  final double railThickness;
  final double friction;
  final double restitution;  PoolPainter(
      this.balls,
      this.cueVector,
      this.isAiming,
      this.pockets,
      this.ballRadius,
      this.pocketRadius,
      this.cueBallPos,
      this.cuePower,
      this.cueAngle,
      this.spinOffset,
      this.tableWidth,
      this.tableHeight,
      this.railThickness,
      this.friction,
      this.restitution,
      );  @override
  void paint(Canvas canvas, Size size) {
    final tablePaint = Paint()..color = Colors.blue.shade600;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tablePaint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = railThickness;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    final innerBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(railThickness, railThickness, size.width - 2 * railThickness, size.height - 2 * railThickness),
      innerBorderPaint,
    );

    for (var pocket in pockets) {
      canvas.drawCircle(
        pocket,
        pocketRadius,
        Paint()..color = Colors.black,
      );
    }

    for (var ball in balls) {
      if (ball.isPocketed) continue;

      double scale = 1.0;
      if (ball.isPocketing) {
        scale = 1.0 - ball.pocketAnimationProgress;
      }

      canvas.drawCircle(
        ball.position + const Offset(2, 2) * scale,
        ballRadius * scale,
        Paint()..color = Colors.black.withOpacity(0.3),
      );

      if (ball.number >= 9 && ball.number <= 15) {
        final gradient = RadialGradient(
          center: const Alignment(-0.5, -0.5),
          radius: 0.7,
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.white,
            Colors.white.withOpacity(0.7),
          ],
          stops: [0.0, 0.5, 1.0],
        );
        canvas.drawCircle(
          ball.position,
          ballRadius * scale,
          Paint()..shader = gradient.createShader(Rect.fromCircle(center: ball.position, radius: ballRadius * scale)),
        );
        final stripePaint = Paint()..color = ball.color;
        canvas.drawArc(
          Rect.fromCircle(center: ball.position, radius: ballRadius * scale),
          -pi / 2 - pi / 4,
          pi / 2,
          false,
          stripePaint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: ball.position, radius: ballRadius * scale),
          pi / 2 - pi / 4,
          pi / 2,
          false,
          stripePaint,
        );
      } else {
        final gradient = RadialGradient(
          center: const Alignment(-0.5, -0.5),
          radius: 0.7,
          colors: [
            Colors.white.withOpacity(0.8),
            ball.color,
            ball.color.withOpacity(0.7),
          ],
          stops: [0.0, 0.5, 1.0],
        );
        canvas.drawCircle(
          ball.position,
          ballRadius * scale,
          Paint()..shader = gradient.createShader(Rect.fromCircle(center: ball.position, radius: ballRadius * scale)),
        );
      }

      canvas.drawCircle(
        ball.position - Offset(ballRadius * 0.5, ballRadius * 0.5) * scale,
        ballRadius * 0.3 * scale,
        Paint()..color = Colors.white.withOpacity(0.5),
      );

      if (ball.number != 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: ball.number.toString(),
            style: TextStyle(
              color: ball.number == 8 ? Colors.white : Colors.black,
              fontSize: ballRadius * 0.8 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, ball.position - Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }

    if (isAiming && cueVector != Offset.zero) {
      final direction = -cueVector / cueVector.distance;
      final cuePaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 2;

      final cueStickLength = 100.0;
      final cueStickStart = cueBallPos - direction * (ballRadius + 10);
      final cueStickEnd = cueStickStart - direction * cueStickLength;
      canvas.drawLine(
        cueStickStart,
        cueStickEnd,
        Paint()
          ..color = Colors.brown.shade700
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        cueStickStart,
        3,
        Paint()..color = Colors.white,
      );

      // Cue ball trajectory prediction using geometric collision detection
      List<Offset> cueTrajectory = [cueBallPos];
      Offset cuePos = cueBallPos;
      Offset cueDir = direction;
      double cueVelocityMag = cuePower * 200;
      Offset? collisionPoint;
      Ball? hitBall;
      double minDist = double.infinity;

      // Find the first collision using geometric method
      for (var ball in balls) {
        if (ball.isPocketed || ball.number == 0 || ball.isPocketing) continue;

        final delta = ball.position - cuePos;
        final dirMag = cueDir.distance;
        final unitDir = dirMag > 0 ? cueDir / dirMag : Offset.zero;

        // Project delta onto the direction to find closest approach
        final projection = delta.dx * unitDir.dx + delta.dy * unitDir.dy;
        if (projection < 0) continue; // Ball is behind the cue ball's path

        final closestPoint = cuePos + unitDir * projection;
        final distToBall = (closestPoint - ball.position).distance;

        // Check if the cue ball will hit the target ball
        if (distToBall <= ballRadius * 2) {
          // Calculate the exact collision point
          final d = sqrt(pow(ballRadius * 2, 2) - pow(distToBall, 2));
          final collisionDist = projection - d;
          if (collisionDist < 0) continue; // Collision would occur behind the starting point

          if (collisionDist < minDist) {
            minDist = collisionDist;
            collisionPoint = cuePos + unitDir * collisionDist;
            hitBall = ball;
          }
        }
      }

      // Simulate cue ball trajectory until first collision or rail hit
      double remainingDistance = 1000;
      const int maxBounces = 3;
      int bounces = 0;
      if (collisionPoint != null) {
        cueTrajectory.add(collisionPoint);
      } else {
        while (remainingDistance > 0 && bounces < maxBounces) {
          double? tMin;
          Offset? nextPos;
          Offset? nextDir;

          if (cueDir.dx < 0) {
            final t = (railThickness + ballRadius - cuePos.dx) / cueDir.dx;
            if (t > 0) {
              final pos = cuePos + cueDir * t;
              if (pos.dy >= railThickness + ballRadius && pos.dy <= tableHeight - railThickness - ballRadius) {
                if (tMin == null || t < tMin) {
                  tMin = t;
                  nextPos = pos;
                  nextDir = Offset(-cueDir.dx, cueDir.dy);
                }
              }
            }
          }

          if (cueDir.dx > 0) {
            final t = (tableWidth - railThickness - ballRadius - cuePos.dx) / cueDir.dx;
            if (t > 0) {
              final pos = cuePos + cueDir * t;
              if (pos.dy >= railThickness + ballRadius && pos.dy <= tableHeight - railThickness - ballRadius) {
                if (tMin == null || t < tMin) {
                  tMin = t;
                  nextPos = pos;
                  nextDir = Offset(-cueDir.dx, cueDir.dy);
                }
              }
            }
          }

          if (cueDir.dy < 0) {
            final t = (railThickness + ballRadius - cuePos.dy) / cueDir.dy;
            if (t > 0) {
              final pos = cuePos + cueDir * t;
              if (pos.dx >= railThickness + ballRadius && pos.dx <= tableWidth - railThickness - ballRadius) {
                if (tMin == null || t < tMin) {
                  tMin = t;
                  nextPos = pos;
                  nextDir = Offset(cueDir.dx, -cueDir.dy);
                }
              }
            }
          }

          if (cueDir.dy > 0) {
            final t = (tableHeight - railThickness - ballRadius - cuePos.dy) / cueDir.dy;
            if (t > 0) {
              final pos = cuePos + cueDir * t;
              if (pos.dx >= railThickness + ballRadius && pos.dx <= tableWidth - railThickness - ballRadius) {
                if (tMin == null || t < tMin) {
                  tMin = t;
                  nextPos = pos;
                  nextDir = Offset(cueDir.dx, -cueDir.dy);
                }
              }
            }
          }

          if (tMin == null || nextPos == null || nextDir == null) break;

          cueTrajectory.add(nextPos);
          remainingDistance -= tMin * cueVelocityMag;
          cuePos = nextPos;
          cueDir = nextDir;
          cueVelocityMag *= restitution;
          bounces++;
        }
      }

      // Draw cue ball trajectory
      for (int i = 0; i < cueTrajectory.length - 1; i++) {
        canvas.drawLine(
          cueTrajectory[i],
          cueTrajectory[i + 1],
          cuePaint,
        );
      }

      // Hit ball trajectory prediction
      if (collisionPoint != null && hitBall != null) {
        // Calculate collision normal (line from cue ball to hit ball at collision point)
        final delta = hitBall.position - collisionPoint;
        final dist = delta.distance;
        if (dist == 0) return; // Avoid division by zero
        final normal = delta / dist;

        // Cue ball incoming velocity
        final cueBallVelocity = direction * cuePower * 200;
        final hitBallVelocity = Offset.zero; // Hit ball is initially stationary
        final relativeVelocity = hitBallVelocity - cueBallVelocity;
        final speed = relativeVelocity.dx * normal.dx + relativeVelocity.dy * normal.dy;

        if (speed < 0) {
          // Apply impulse along the normal
          final impulse = normal * speed * restitution;

          // Post-collision velocities
          final predictedCueBallVelocity = (cueBallVelocity + impulse) * friction;
          final predictedHitBallVelocity = (hitBallVelocity - impulse) * friction;

          // Simulate hit ball trajectory with rail collisions
          List<Offset> hitBallTrajectory = [hitBall.position];
          Offset hitBallPos = hitBall.position;
          Offset hitBallDir = normal; // Hit ball moves along the normal
          double hitBallVelocityMag = predictedHitBallVelocity.distance;
          remainingDistance = 500;
          bounces = 0;
          while (remainingDistance > 0 && bounces < maxBounces) {
            double? tMin;
            Offset? nextPos;
            Offset? nextDir;

            if (hitBallDir.dx < 0) {
              final t = (railThickness + ballRadius - hitBallPos.dx) / hitBallDir.dx;
              if (t > 0) {
                final pos = hitBallPos + hitBallDir * t;
                if (pos.dy >= railThickness + ballRadius && pos.dy <= tableHeight - railThickness - ballRadius) {
                  if (tMin == null || t < tMin) {
                    tMin = t;
                    nextPos = pos;
                    nextDir = Offset(-hitBallDir.dx, hitBallDir.dy);
                  }
                }
              }
            }

            if (hitBallDir.dx > 0) {
              final t = (tableWidth - railThickness - ballRadius - hitBallPos.dx) / hitBallDir.dx;
              if (t > 0) {
                final pos = hitBallPos + hitBallDir * t;
                if (pos.dy >= railThickness + ballRadius && pos.dy <= tableHeight - railThickness - ballRadius) {
                  if (tMin == null || t < tMin) {
                    tMin = t;
                    nextPos = pos;
                    nextDir = Offset(-hitBallDir.dx, hitBallDir.dy);
                  }
                }
              }
            }

            if (hitBallDir.dy < 0) {
              final t = (railThickness + ballRadius - hitBallPos.dy) / hitBallDir.dy;
              if (t > 0) {
                final pos = hitBallPos + hitBallDir * t;
                if (pos.dx >= railThickness + ballRadius && pos.dx <= tableWidth - railThickness - ballRadius) {
                  if (tMin == null || t < tMin) {
                    tMin = t;
                    nextPos = pos;
                    nextDir = Offset(hitBallDir.dx, -hitBallDir.dy);
                  }
                }
              }
            }

            if (hitBallDir.dy > 0) {
              final t = (tableHeight - railThickness - ballRadius - hitBallPos.dy) / hitBallDir.dy;
              if (t > 0) {
                final pos = hitBallPos + hitBallDir * t;
                if (pos.dx >= railThickness + ballRadius && pos.dx <= tableWidth - railThickness - ballRadius) {
                  if (tMin == null || t < tMin) {
                    tMin = t;
                    nextPos = pos;
                    nextDir = Offset(hitBallDir.dx, -hitBallDir.dy);
                  }
                }
              }
            }

            if (tMin == null || nextPos == null || nextDir == null) break;

            hitBallTrajectory.add(nextPos);
            remainingDistance -= tMin * hitBallVelocityMag;
            hitBallPos = nextPos;
            hitBallDir = nextDir;
            hitBallVelocityMag *= restitution;
            bounces++;
          }

          // Draw hit ball trajectory
          for (int i = 0; i < hitBallTrajectory.length - 1; i++) {
            canvas.drawLine(
              hitBallTrajectory[i],
              hitBallTrajectory[i + 1],
              Paint()
                ..color = Colors.yellow.withOpacity(0.5)
                ..strokeWidth = 2,
            );
          }

          // Simulate cue ball trajectory after collision
          List<Offset> cueTrajectoryAfterCollision = [collisionPoint];
          cuePos = collisionPoint;
          cueDir = predictedCueBallVelocity.normalized();
          cueVelocityMag = predictedCueBallVelocity.distance;
          remainingDistance = 500;
          bounces = 0;
          while (remainingDistance > 0 && bounces < maxBounces) {
            double? tMin;
            Offset? nextPos;
            Offset? nextDir;

            if (cueDir.dx < 0) {
              final t = (railThickness + ballRadius - cuePos.dx) / cueDir.dx;
              if (t > 0) {
                final pos = cuePos + cueDir * t;
                if (pos.dy >= railThickness + ballRadius && pos.dy <= tableHeight - railThickness - ballRadius) {
                  if (tMin == null || t < tMin) {
                    tMin = t;
                    nextPos = pos;
                    nextDir = Offset(-cueDir.dx, cueDir.dy);
                  }
                }
              }
            }

            if (cueDir.dx > 0) {
              final t = (tableWidth - railThickness - ballRadius - cuePos.dx) / cueDir.dx;
              if (t > 0) {
                final pos = cuePos + cueDir * t;
                if (pos.dy >= railThickness + ballRadius && pos.dy <= tableHeight - railThickness - ballRadius) {
                  if (tMin == null || t < tMin) {
                    tMin = t;
                    nextPos = pos;
                    nextDir = Offset(-cueDir.dx, cueDir.dy);
                  }
                }
              }
            }

            if (cueDir.dy < 0) {
              final t = (railThickness + ballRadius - cuePos.dy) / cueDir.dy;
              if (t > 0) {
                final pos = cuePos + cueDir * t;
                if (pos.dx >= railThickness + ballRadius && pos.dx <= tableWidth - railThickness - ballRadius) {
                  if (tMin == null || t < tMin) {
                    tMin = t;
                    nextPos = pos;
                    nextDir = Offset(cueDir.dx, -cueDir.dy);
                  }
                }
              }
            }

            if (cueDir.dy > 0) {
              final t = (tableHeight - railThickness - ballRadius - cuePos.dy) / cueDir.dy;
              if (t > 0) {
                final pos = cuePos + cueDir * t;
                if (pos.dx >= railThickness + ballRadius && pos.dx <= tableWidth - railThickness - ballRadius) {
                  if (tMin == null || t < tMin) {
                    tMin = t;
                    nextPos = pos;
                    nextDir = Offset(cueDir.dx, -cueDir.dy);
                  }
                }
              }
            }

            if (tMin == null || nextPos == null || nextDir == null) break;

            cueTrajectoryAfterCollision.add(nextPos);
            remainingDistance -= tMin * cueVelocityMag;
            cuePos = nextPos;
            cueDir = nextDir;
            cueVelocityMag *= restitution;
            bounces++;
          }

          // Draw cue ball trajectory after collision
          for (int i = 0; i < cueTrajectoryAfterCollision.length - 1; i++) {
            canvas.drawLine(
              cueTrajectoryAfterCollision[i],
              cueTrajectoryAfterCollision[i + 1],
              Paint()
                ..color = Colors.white.withOpacity(0.3)
                ..strokeWidth = 2,
            );
          }
        }
      }

      if (spinOffset != Offset.zero) {
        canvas.drawCircle(
          cueBallPos + spinOffset,
          3,
          Paint()..color = Colors.red,
        );
      }
    }

  }  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}extension OffsetExtension on Offset {
  Offset normalized() {
    final mag = distance;
    return mag > 0 ? this / mag : Offset.zero;
  }
}

