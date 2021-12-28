module board;

import w4 = wasm4;

enum unit = 8;
enum leftMargin = 5;

struct Puyo {
  int x;
  int y;
  ushort color;
  bool canControl;
  bool center;

  bool empty() const { return color == 0; }

  void draw() const {
    if (empty) return;

    static immutable ubyte[] glyph = [
        0b11000011,
        0b10100101,
        0b00100100,
        0b00100100,
        0b11000011,
        0b00000000,
        0b10000001,
        0b11000011];
    *w4.drawColors = color;
    w4.blit(glyph.ptr, (x + leftMargin) * unit, y * unit, unit, unit, w4.blit1Bpp);
  }
}

// Requires WASI_SDK_PATH env in dub.json.
extern(C) int rand();

struct RandomColor {
  bool empty = false;
  ushort[2][2] front;

  void popFront() {
    front[0] = front[1];
    front[1][0] = randColor();
    front[1][1] = randColor();
    // For initial popFront.
    if (front[0][0] == 0) {
      front[0][0] = randColor();
      front[1][1] = randColor();
    }
  }

 private:
  static ushort randColor() {
    return cast(ushort) rand() % 3 + 2;
  }
}

struct Board {
  void reset() {
    foreach (ty; 0 .. ny) {
      foreach (tx; 0 .. nx) {
        with (matrix[tx][ty]) {
          x = tx;
          y = ty;
          color = 0;
        }
      }
      newPuyo();
    }
  }

  void draw() const {
    foreach (ref line; matrix) {
      foreach (ref puyo; line) {
        puyo.draw();
      }
    }
  }

  void update() {
    bool changed = false;
    foreach_reverse (y; 0 .. 20) {
      foreach (x; 0 .. 20 - leftMargin) {
        if (!empty(x, y) && empty(x, y + 1)) {
          swap(x, y, x, y + 1);
          changed = true;
        } else {
          matrix[x][y].canControl = false;
          matrix[x][y].center = false;
        }
      }
    }
    if (!changed) newPuyo;
  }

  void swap(int xa, int ya, int xb, int yb) {
    Puyo a = matrix[xa][ya];
    a.x = xb;
    a.y = yb;

    Puyo b = matrix[xb][yb];
    b.x = xa;
    b.y = ya;

    matrix[xa][ya] = b;
    matrix[xb][yb] = a;
  }

  void left() {
    foreach (x; 0 .. nx) {
      foreach (y; 0 .. ny) {
        if (matrix[x][y].canControl) {
          if (empty(x - 1, y)) {
            swap(x, y, x - 1, y);
          }
        }
      }
    }
  }
  void right() {
    foreach_reverse (x; 0 .. nx) {
      foreach (y; 0 .. ny) {
        if (matrix[x][y].canControl) {
          if (empty(x + 1, y)) {
            swap(x, y, x + 1, y);
          }
        }
      }
    }
  }

  void rotate() {
    foreach (x; 0 .. nx) {
      foreach (y; 0 .. ny) {
        if (matrix[x][y].center) {
          // Rotate clockwise.
          if (swapInControlToEmpty(x - 1, y, x, y + 1)) return;
          if (swapInControlToEmpty(x + 1, y, x, y - 1)) return;
          if (swapInControlToEmpty(x, y - 1, x - 1, y)) return;
          if (swapInControlToEmpty(x, y + 1, x + 1, y)) return;
          // Controllable but cannot be rotated.
          return;
        }
      }
    }
  }

  auto nextColors() const { return color.front; }

 private:
  enum ny = w4.screenSize / unit;
  enum nx = w4.screenSize / unit - leftMargin;

  Puyo[ny][nx] matrix;
  RandomColor color;

  void add(Puyo puyo) {
    matrix[puyo.x][puyo.y] = puyo;
  }

  void newPuyo() {
    add(Puyo(/*x=*/matrix.length / 2,
             /*y=*/0,
             /*color=*/color.front[0][0],
             /*canControl=*/true,
             /*center=*/true));
    add(Puyo(/*x=*/matrix.length / 2 + 1,
             /*y=*/0,
             /*color=*/color.front[0][1],
             /*canControl=*/true,
             /*center=*/false));
    color.popFront();
  }

  bool empty(int x, int y) const {
    if (0 <= x && x < nx && 0 <= y && y < ny) {
      auto puyo = matrix[x][y];
      return puyo.empty;
    }
    return false;
  }

  /// Returns true if swapped.
  bool swapInControlToEmpty(int xsrc, int ysrc, int xdst, int ydst) {
    if (!empty(xsrc, ysrc) && matrix[xsrc][ysrc].canControl && empty(xdst, ydst)) {
      swap(xsrc, ysrc, xdst, ydst);
      return true;
    }
    return false;
  }
}
