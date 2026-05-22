#include <stdio.h>
#include "lib.h"

int main(int argc, char *argv[]) {
    const char *name = (argc > 1) ? argv[1] : "world";
    greet(name);
    return 0;
}
