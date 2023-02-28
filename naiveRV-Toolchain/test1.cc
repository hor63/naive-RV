
#include "class1.h"

volatile long x = 0;
volatile long y = 123;

int main () {
    
    int i;
    
    for (i=0;i<1000;i++) {
        x += i;
        class1::doSomething();
    }
    
    return static_cast<int>(class1::getVal()) + x;
}
