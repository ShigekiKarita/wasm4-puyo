module board;

import w4 = wasm4;

enum unit = 8;
enum leftMargin = 5;

struct Puyo {
  ushort color;
  bool controllable;
  bool center;

  bool empty() const { return color == 0; }

  void draw(int x, int y) const {
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
    w4.blit(glyph.ptr, (x + leftMargin) * unit, y * unit, unit, unit,
            w4.blit1Bpp);
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
        matrix[tx][ty] = Puyo.init;
      }
    }
  }

  void draw() const {
    foreach (x, ref line; matrix) {
      foreach (y, ref puyo; line) {
        puyo.draw(x, y);
      }
    }
  }

  bool fall() {
    bool changed = false;
    foreach_reverse (y; 0 .. 20) {
      foreach (x; 0 .. 20 - leftMargin) {
        if (!empty(x, y) && empty(x, y + 1)) {
          swap(x, y, x, y + 1);
          changed = true;
        } else {
          matrix[x][y].controllable = false;
          matrix[x][y].center = false;
        }
      }
    }
    return changed;
  }

  // Wipes <= 4 consecutive puyos.
  int wipe() {
    int n;
    bool[nx][ny] del;
    foreach (x; 0 .. nx) {
      foreach (y; 0 .. ny) {
        if (numConsective(x, y, matrix[x][y].color) >= 4) {
          del[x][y] = true;
          ++n;
        }
      }
    }
    if (n == 0) return 0;
    foreach (x; 0 .. nx) {
      foreach (y; 0 .. ny) {
        if (del[x][y]) {
          matrix[x][y] = Puyo.init;
        }
      }
    }
    return n;
  }

  bool gameover() const {
    Puyo puyo = matrix[matrix.length / 2][0];
    if (!puyo.empty && !puyo.controllable) return true;
    puyo = matrix[matrix.length / 2 + 1][0];
    if (!puyo.empty && !puyo.controllable) return true;
    return false;
  }

  void newPuyo() {
    if (gameover) return;

    matrix[matrix.length / 2][0] = Puyo(
             /*color=*/color.front[0][0],
             /*controllable=*/true,
             /*center=*/true);
    matrix[matrix.length / 2 + 1][0] = Puyo(
             /*color=*/color.front[0][1],
             /*controllable=*/true,
             /*center=*/false);
    color.popFront();
  }

  void left() {
    foreach (x; 0 .. nx) {
      foreach (y; 0 .. ny) {
        if (matrix[x][y].controllable) {
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
        if (matrix[x][y].controllable) {
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
          if (swapControllableToEmpty(x - 1, y, x, y + 1)) return;
          if (swapControllableToEmpty(x + 1, y, x, y - 1)) return;
          if (swapControllableToEmpty(x, y - 1, x - 1, y)) return;
          if (swapControllableToEmpty(x, y + 1, x + 1, y)) return;
          // Controllable but cannot be rotated.
          return;
        }
      }
    }
  }

  auto nextColors() const { return color.front; }

 private:
  int numConsective(int x, int y, ushort color) {
    if (empty(x, y) || matrix[x][y].color != color) return 0;
    matrix[x][y].color = 0;
    auto count = 1
        + numConsective(x - 1, y, color)
        + numConsective(x + 1, y, color)
        + numConsective(x, y - 1, color)
        + numConsective(x, y + 1, color);
    matrix[x][y].color = color;
    return count;
  }

  bool empty(int x, int y) const {
    if (0 <= x && x < nx && 0 <= y && y < ny) {
      auto puyo = matrix[x][y];
      return puyo.empty;
    }
    return false;
  }

  void swap(int xa, int ya, int xb, int yb) {
    Puyo a = matrix[xa][ya];
    Puyo b = matrix[xb][yb];
    matrix[xa][ya] = b;
    matrix[xb][yb] = a;
  }

  /// Returns true if swapped.
  bool swapControllableToEmpty(int xsrc, int ysrc, int xdst, int ydst) {
    if (!empty(xsrc, ysrc) && matrix[xsrc][ysrc].controllable && empty(xdst, ydst)) {
      swap(xsrc, ysrc, xdst, ydst);
      return true;
    }
    return false;
  }

  enum ny = w4.screenSize / unit;
  enum nx = w4.screenSize / unit - leftMargin;
  Puyo[ny][nx] matrix;
  RandomColor color;
}
