#include <conio.h>
#include <string>
#include <iostream>
#include <lua.h>

extern "C" {
    std::string ArrowKeyPress() {
        int c = _getch();
        if (c == 0 || c == 224) {
            switch ((_getch())) {
            case 72:
                return "up";
            case 80:
                return "down";
            case 75:
                return "left";
            case 77:
                return "right";
            default:
                return "other";
            }
        } else {
            if (c == 13) {
                return "enter";
            } else {
                return "other";
            }
        }
    }

    int main() {
        std::cout << ArrowKeyPress();
        return 0;
    }
}