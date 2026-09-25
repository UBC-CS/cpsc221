// CPSC 221 -- lecture 8, demo 3
// Three things that go wrong. The last one crashes ON PURPOSE.

#include <iostream>
using namespace std;

int main() {
    int *p, *q;

    p = new int;   *p = 8;
    q = new int;   *q = 9;

    cout << "*p = " << *p << "   *q = " << *q << endl;

    // ---- 1. MEMORY LEAK -------------------------------------------------
    // p was the only handle on that first int. Overwrite it and the memory
    // is still allocated, but nothing can reach it. It is gone until the
    // program exits.
    p = nullptr;
    cout << endl << "leaked one int -- no pointer to it any more" << endl;

    // ---- 2. DELETING A NULL POINTER (nullptr) -------------------------------------
    // Perfectly legal. Does nothing at all.
    delete p;
    cout << "delete on a null pointer: fine, did nothing" << endl;

    delete q;
    q = nullptr;      // q was dangling the instant delete returned. Fix it.

    // ---- 3. DEREFERENCING A NULL POINTER (nullptr) --------------------------------
    // Undefined behaviour. In practice: segmentation fault.
    cout << endl << "about to dereference nullptr ..." << endl;
    cout.flush();

    cout << *q << endl;       // <-- CRASH

    cout << "you will never see this line" << endl;
    return 0;
}
