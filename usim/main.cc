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
  if ((addr & 0xF000) == 0xC000) {
    printf("\r\ninvalid write to 0x%04x\r\n", addr);
  }
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

char *progname;
void usage()
{
  fprintf(stderr, "usage: usim [ -r ] <hexfile>\n");
  exit(EXIT_FAILURE);
}

int main(int argc, char *argv[])
{
  progname = argv[0];

  (void)signal(SIGINT, SIG_IGN);
#ifdef SIGALRM
  (void)signal(SIGALRM, update);
  alarm(1);
#endif

  bool read_start_from_file = false;
  int c;
  const char* trace = 0;

  while ((c = getopt(argc, argv, "rt:")) != -1) {
    switch (c) {
    case 'r':
      read_start_from_file = true;
      break;
    case 't':
      trace = optarg;
      break;
    default:
      usage();
    }
  }

  if (argc == optind) {
    usage();
  }

  sys.load_intelhex(argv[optind], read_start_from_file);
  sys.reset();
  if (trace) {
    sys.trace(trace);
  }
  sys.run();

  return EXIT_SUCCESS;
}
