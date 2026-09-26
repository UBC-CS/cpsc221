// CPSC 221 -- lecture 8, demo 2
// new gives you memory with no name. Two pointers can share it.

#include <iostream>
using namespace std;

int main() {
    int *p, *q;

    p = new int;   // memory on the HEAP. Its only name is "whatever p points at"
    *p = 8;

    q = p;         // q and p are now two handles on ONE int
    cout << "*p = " << *p << "   *q = " << *q << endl;   // 8   8
    cout << " p = " <<  p << "    q = " <<  q << endl;   // identical addresses

    *q = 17;       // written through q ...
    cout << endl << "*p = " << *p << endl;               // ... and seen through p

    delete p;      // frees the int
    p = nullptr;
    q = nullptr;      // q pointed at the same thing, so it was dangling too

    cout << "freed, both pointers NULLed" << endl;
    return 0;
}
