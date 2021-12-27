import w4 = wasm4;
import board : Board, Puyo, unit, leftMargin;

Board board;
int score = 0;
uint frameRate = 10;

void input() {
  static ubyte prevState;
  const gamepad = *w4.gamepad1;

  // Fall faster if down is pressed.
  frameRate = gamepad & w4.buttonDown ? 3 : 10;

  const justPressed = gamepad & (gamepad ^ prevState);
  if (justPressed & w4.buttonLeft) board.left();
  if (justPressed & w4.buttonRight) board.right();
  if (justPressed & w4.buttonUp) board.rotate();

  prevState = gamepad;
}

char* itoaHelper(char* dest, int i) {
  if (i <= -10) {
    dest = itoaHelper(dest, i/10);
  }
  *dest++ = '0' - i % 10;
  return dest;
}

char* itoa(int i) {
  static char[20] buf;
  char* s = buf.ptr;
  if (i < 0) {
    *s++ = '-';
  } else {
    i = -i;
  }
  *itoaHelper(s, i) = '\0';
  return buf.ptr;
}

extern(C) void start() {
  board.reset();
}

extern(C) void update() {
  static uint frameCount;
  ++frameCount;

  input();

  if (frameCount % frameRate == 0) {
    board.update();
    ++score;
  }

  board.draw();

  // Draw boundary.
  *w4.drawColors = 0x02;
  w4.vline(leftMargin * unit, 0, 20 * unit);

  // Draw infomation.
  *w4.drawColors = 0x4;
  w4.text("Score", 0, 0);
  w4.text(itoa(score), 0, unit);
  w4.text("Next", 0, unit * 3);
  foreach (i, color; board.nextColor.front) {
    Puyo(i - leftMargin, 4, color).draw();
  }
  foreach (i, color; board.nextColor.next) {
    Puyo(i - leftMargin, 6, color).draw();
  }
}
