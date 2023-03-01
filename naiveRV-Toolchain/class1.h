
class class1 {
    
public:
    class1() {
        val = 0.0;
    }

    virtual ~class1() {
    }

    static void doSomething();
    
    static double getVal();
    
private:

    static class1 theOneAndOnly;
    
    double val;
};
        
