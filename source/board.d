module board;

import w4 = wasm4;

enum unit = 8;
enum leftMargin = 5;

struct Puyo {
  int x;
  int y;
  ushort color;
  bool canControl = false;

  bool empty() const { return color == 0; }

  void draw() const {
    if (empty) return;

    static immutable ubyte[] puyoGlyph = [
        0b11000011,
        0b10100101,
        0b00100100,
        0b00100100,
        0b11000011,
        0b00000000,
        0b10000001,
        0b11000011,
                                          ];
    *w4.drawColors = color;
    w4.blit(puyoGlyph.ptr, (x + leftMargin) * unit, y * unit, unit, unit, w4.blit1Bpp);
  }
}

// Requires WASI_SDK_PATH env in dub.json.
extern(C) int rand();

struct RandomColor {
  bool empty = false;
  ushort[2] front, next;

  void popFront() {
    front = next;
    next[0] = randColor();
    next[1] = randColor();

    if (front[0] == 0 || front[1] == 0) {
      front[0] = randColor();
      front[1] = randColor();
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
    // TODO(karita): rotate two puyos.
  }

  RandomColor nextColor() const { return color; }

 private:
  enum ny = w4.screenSize / unit;
  enum nx = w4.screenSize / unit - leftMargin;

  Puyo[ny][nx] matrix;
  RandomColor color;

  void add(Puyo puyo) {
    matrix[puyo.x][puyo.y] = puyo;
  }

  void newPuyo() {
    add(Puyo(matrix.length / 2, 0, color.front[0], true));
    add(Puyo(matrix.length / 2 + 1, 0, color.front[1], true));
    color.popFront();
  }

  bool empty(int x, int y) const {
    if (0 <= x && x < nx && 0 <= y && y < ny) {
      auto puyo = matrix[x][y];
      return puyo.empty;
    }
    return false;
  }
}
