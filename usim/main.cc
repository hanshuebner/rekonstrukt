//
//	main.cc
//

#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#ifdef X11
#include "mc6809_X.h"
#else
#include "mc6809.h"
#endif
#include "mc6850.h"

#ifdef __unix
#include <unistd.h>
#endif

#ifdef __osf__
extern "C" unsigned int alarm(unsigned int);
#endif

#define UART_ADDR 0xB000

//#ifndef sun
//typedef void SIG_FUNC_TYP(int);
//typedef SIG_FUNC_TYPE *SIG_FP;
//#endif

class sys
  : virtual public
#ifdef X11
mc6809_X
#else
mc6809
#endif
{

protected:

  virtual Byte			 read(Word);
  virtual void			 write(Word, Byte);

protected:

  mc6850			 uart;

} sys;

Byte sys::read(Word addr)
{
  Byte		ret = 0;

  if ((addr & 0xfffe) == UART_ADDR) {
    ret = uart.read(addr);
  } else {
    ret = mc6809::read(addr);
  }

  return ret;
}

void sys::write(Word addr, Byte x)
{
  if ((addr & 0xfffe) == UART_ADDR) {
    uart.write(addr, x);
  } else {
    mc6809::write(addr, x);
  }
}

#ifdef SIGALRM
#ifdef sun
void update(int, ...)
#else
  void update(int)
#endif
{
  sys.status();
  (void)signal(SIGALRM, update);
  alarm(1);
}
#endif // SIGALRM

int main(int argc, char *argv[])
{
  if (argc != 2) {
    fprintf(stderr, "usage: usim <hexfile>\n");
    return EXIT_FAILURE;
  }

  (void)signal(SIGINT, SIG_IGN);
#ifdef SIGALRM
  (void)signal(SIGALRM, update);
  alarm(1);
#endif

  sys.load_intelhex(argv[1]);
  sys.run();

  return EXIT_SUCCESS;
}
