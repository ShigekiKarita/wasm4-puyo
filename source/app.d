import w4 = wasm4;
import board : Board, Puyo, unit, leftMargin;

extern(C) void start() {
  board.reset();
}

extern(C) void update() {
  static uint frameCount;
  ++frameCount;

  if (board.gameover()) {
    w4.palette[0] = 0xfff6d3;
    w4.palette[1] = 0xf9a875;
    w4.palette[2] = 0xeb6b6f;
    w4.palette[3] = 0x7c3f58;
    w4.text("GAME OVER", 8 * unit, 10 * unit);
  } else if (rensa == 0) input();

  if (frameCount % frameRate == 0) {
    if (!board.fall()) {
      auto dscore = board.wipe();
      score += (rensa + 1) * dscore;
      rensa = dscore == 0 ? 0 : rensa + 1;
      if (rensa == 0) board.newPuyo();
    }
  }

  board.draw();

  // Draw boundary.
  *w4.drawColors = 0x02;
  w4.vline(leftMargin * unit, 0, 20 * unit);

  // Draw infomation.
  *w4.drawColors = 0x4;
  w4.text("Score", 0, 0);
  w4.text(itoa(score), 0, unit);

  w4.text("Rensa", 0, unit * 3);
  w4.text(itoa(rensa), 0, unit * 4);

  w4.text("Next", 0, unit * 6);
  foreach (i, colors; board.nextColors) {
    foreach (j, c; colors) {
      Puyo(j - leftMargin, 7 + i * 2, c).draw();
    }
  }
}

private:

// Global variables.
Board board;
int score = 0;
uint frameRate = 10;
int rensa = 0;

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
