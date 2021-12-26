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
        }
    }

    void add(Puyo puyo) {
        matrix[puyo.x][puyo.y] = puyo;
    }

    void newPuyo() {
        add(Puyo(matrix.length / 2, 0, color.front[0]));
        add(Puyo(matrix.length / 2 + 1, 0, color.front[1]));
        color.popFront();
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
                if (canFall(matrix[x][y])) {
                    matrix[x][y + 1].color = matrix[x][y].color;
                    matrix[x][y].color = 0;
                    changed = true;
                }
            }
        }
        if (!changed) newPuyo;
    }

    void left() {}
    void right() {}
    void rotate() {}

    RandomColor nextColor() const { return color; }

  private:
    enum ny = w4.screenSize / unit;
    enum nx = w4.screenSize / unit - leftMargin;

    Puyo[ny][nx] matrix;
    RandomColor color;

    bool canFall(Puyo puyo) const {
        if (puyo.empty || puyo.y >= ny - 1) return false;
        return matrix[puyo.x][puyo.y + 1].empty;
    }
}
