
volatile long x = 0;
volatile long y = 123;

int main () {
    
    int i;
    
    for (i=0;i<1000;i++) {
        x += i;
    }
    
    return x;
}
