
#include <cmath>

#include "class1.h"

class1 class1::theOneAndOnly;

void class1::doSomething() {
    
    theOneAndOnly.val += sin(theOneAndOnly.val);
    
}
    
double class1::getVal() {
    return theOneAndOnly.val;
}
