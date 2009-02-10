//
//
//	mc6850.h
//
//	(C) R.P.Bellis 1994
//

#ifndef __mc6850_h__
#define __mc6850_h__

#include <stdio.h>
#ifdef THREADS
#include <pthread.h>
#endif
#include "misc.h"
#include "term.h"

class mc6850 {

  // Internal registers

 protected:

  Byte td, rd, cr, sr;

  // Access to real IO device

  Terminal term;

#ifdef THREADS
  // Internal polling routine
 private:
  pthread_t poll_thread;
  static void* poll_input(void* arg);
#endif
  void poll();

  // Initialisation functions

 protected:

  void reset();

  // Read and write functions
 public:

  Byte read(Word offset);
  void write(Word offset, Byte val);

  // Public constructor and destructor

  mc6850();
  ~mc6850();

};

#endif // __mc6850_h__
