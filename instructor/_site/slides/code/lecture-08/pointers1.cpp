// CPSC 221 -- lecture 8, demo 1
// A pointer holds the location of another variable.

#include <iostream>
using namespace std;

int main() {
    int  x;
    int *p;

    p = &x;        // p now holds the LOCATION of x
    *p = 6;        // write 6 to whatever p points at -- that is x

    cout << "x   = " << x   << endl;   // 6
    cout << "*p  = " << *p  << endl;   // 6  -- same int, two names
    cout << endl;

    cout << "&x  = " << &x  << endl;   // an address
    cout << "p   = " << p   << endl;   // the same address
    cout << "&p  = " << &p  << endl;   // p is a variable too, and it has a location

    x = 11;                            // change it through the other name
    cout << endl << "*p  = " << *p << endl;   // 11

    return 0;
}
