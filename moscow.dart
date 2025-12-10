import 'dart:io';
import 'dart:async';
import 'dart:math';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: moscow <path_to_mp3_file>');
    exit(1);
  }

  final mp3Path = args[0];
  
  // Playback
  await playMp3(mp3Path);
  
  // Fire animation
  final animator = FireAnimator();
  await animator.animate();
}

Future<void> playMp3(String path) async {
  try {
    // Different audio players for different platforms
    if (Platform.isWindows) {
      Process.start('powershell', ['-c', '(New-Object Media.SoundPlayer "$path").PlaySync()'], runInShell: true);
    } else if (Platform.isMacOS) {
      Process.start('afplay', [path]);
    } else if (Platform.isLinux) {
      // Multiple Linux players
      try {
        await Process.start('mpg123', [path]);
      } catch (e) {
        try {
          await Process.start('ffplay', ['-nodisp', '-autoexit', path]);
        } catch (e) {
          await Process.start('play', [path]);
        }
      }
    }
  } catch (e) {
    print('Could not play the MP3 file. Install mpg123, ffplay, or play command.');
    print('Continuing with animation only...\n');
  }
}

class FireAnimator {
  static const asciiArt = '''
                            .
                            T
                           ( )
                          <===>
                           F|J
                           ===
                          J|||F
                          F|||J
                         /\\/ \\/\\
                         F+++++J
                        J{}{|}{}F         .
                     .  F{}{|}{}J         T
          .          T J{}{}|{}{}F        ;;
          T         /|\\F/\\/\\|/\\/\\J  .   ,;;;;.
         /:\\      .'/|\\\\:=========F T ./;;;;;;\\ 
       ./:/:/.   ///|||\\\\\\"""""""" /x\\T\\;;;;;;/
      //:/:/:/\\  \\\\\\|////..[ ]...xXXXx.|====|
      \\:/:/:/:T7 :.:.:.:.:||[ ]|/xXXXXXx\\|||||
      ::.:.:.:A. `;:;:;:;'=== ==\\XXXXXXX/=====.
      `;""::/xxx\\.|,|,|,| ( ) ( )| | | |.=..=.|
       :. :`\\xxx/(_)(_)(_) _   _ | | | |'-''-'|
       :T-'-.:"":|"""""""|/ \\ / \\|=====|======|
       .A."""||_|| ,. .. || | | |/\\/\\/\\/ | | ||
   :;:////\\:::.'.| || || ||-| |-|/\\/\\/\\+|+| | |
  ;:;;\\\\/////::::,='======='=============/\\/\\=====.
 :;:::;""":::::;:|__..,__|============/||\\|\\====|
 :::::;|=:::;:;::|,;:::::          |========|   |
 ::l42::::::(}:::::;::::::_________|========|___|__
''';

  final random = Random();
  final fireChars = ['░', '▒', '▓', '█', '*', '◆', '◇', '●'];
  final colors = [33, 31, 91, 93, 97]; // Yellow, Red, Bright Red, Bright Yellow, White
  
  List<String> lines = [];
  int frame = 0;

  FireAnimator() {
    lines = asciiArt.split('\n');
  }

  Future<void> animate() async {
    // Hide cursor
    stdout.write('\x1B[?25l');
    
    // Ctrl-C handler to restore cursor
    ProcessSignal.sigint.watch().listen((_) {
      stdout.write('\x1B[?25h'); // Show cursor
      exit(0);
    });
    
    try {
      while (true) {
        clearScreen();
        drawFrame();
        await Future.delayed(Duration(milliseconds: 150));
        frame++;
      }
    } finally {
      // Show cursor again
      stdout.write('\x1B[?25h');
    }
  }

  void clearScreen() {
    stdout.write('\x1B[2J\x1B[H');
  }

  void drawFrame() {
    for (int y = 0; y < lines.length; y++) {
      final line = lines[y];
      final buffer = StringBuffer();
      
      for (int x = 0; x < line.length; x++) {
        final char = line[x];
        final intensity = calculateFireIntensity(x, y);
        
        if (shouldBurn(char, intensity)) {
          final fireChar = getFireChar(intensity);
          final color = getFireColor(intensity);
          buffer.write('\x1B[${color}m$fireChar\x1B[0m');
        } else {
          if (intensity > 0.3 && char != ' ') {
            buffer.write('\x1B[${colors[min(intensity * colors.length, colors.length - 1).toInt()]}m$char\x1B[0m');
          } else {
            buffer.write(char);
          }
        }
      }
      
      print(buffer.toString());
    }
    
    // Bottom text
    print('\n   Wishing you a Christmas so bright that even state propaganda can\'t extinguish it.');
    print('   Přejeme tak zářivé Vánoce, že je ani státní propaganda nedokáže uhasit.');
  }

  double calculateFireIntensity(int x, int y) {
    final totalHeight = lines.length;
    // More intense at bottom and top (candle flame)
    final heightFactor = y > totalHeight * 0.15 ? (totalHeight - y) / totalHeight : 1.0;
    
    // Flickering effect using sine waves
    final flicker = sin(frame * 0.3 + x * 0.5) * 0.3 + 0.7;
    final shimmer = sin(frame * 0.5 + y * 0.3) * 0.2 + 0.8;
    
    // Random intensity variation
    final noise = random.nextDouble() * 0.4;
    
    return (heightFactor * flicker * shimmer + noise).clamp(0.0, 1.0);
  }

  bool shouldBurn(String char, double intensity) {
    if (char == ' ') return false;
    
    // Higher chance to show fire effect in certain characters
    final burnableChars = ['.', 'T', ':', ';', '/', '\\', '|', '-', '='];
    if (burnableChars.contains(char)) {
      return random.nextDouble() < intensity * 0.4;
    }
    
    return random.nextDouble() < intensity * 0.15;
  }

  String getFireChar(double intensity) {
    final idx = (intensity * (fireChars.length - 1)).floor();
    return fireChars[idx.clamp(0, fireChars.length - 1)];
  }

  int getFireColor(double intensity) {
    if (intensity > 0.8) return 97; // White
    if (intensity > 0.6) return 93; // Bright Yellow
    if (intensity > 0.4) return 33; // Yellow
    if (intensity > 0.2) return 91; // Bright Red
    return 31; // Red
  }
}
