void print32(char* vga, char* s, int row, int col);

int main() {
    char* vga = (char*)0xb8000;
    print32(vga, "Hello from the kernel.", 10, 1);

    while (1);
    return 0;
}

void print32(char* vga, char* s, int row, int col) {
    vga += 2 * (row * 80 + col) + 2;
    while (*s != 0) {
        *vga = *s;
        vga++;
        *vga = 0x0f;
        vga++;
        s++;
    }
}

