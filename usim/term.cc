//
//
//	term.cc
//
//	(C) R.P.Bellis 1994
//

#include <stdlib.h>
#include "term.h"

//------------------------------------------------------------------------
// Machine dependent Terminal implementations
//------------------------------------------------------------------------

//------------------------------------------------------------------------
#if defined(__unix)

#include <unistd.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/time.h>
#include <stdio.h>

#ifdef sun
extern "C" int select(int, fd_set *, fd_set *, fd_set *,
                      const struct timeval *);
#else
extern "C" int select(int, fd_set *, fd_set *, fd_set *, struct timeval *);
#endif

extern "C" void bzero(char *, int);

Terminal::Terminal()
{
  input = stdin;
  output = stdout;
  input_fd = fileno(input);

  // Set input and output to be unbuffered
  setbuf(input, (char *)0);
  setbuf(output, (char *)0);

  // Get copies of current terminal attributes
  tcgetattr(input_fd, &oattr);
  tcgetattr(input_fd, &nattr);

  cfmakeraw(&nattr);

  tcsetattr(input_fd, TCSANOW, &nattr);
}

Terminal::~Terminal()
{
  tcsetattr(input_fd, TCSANOW, &oattr);
}

int Terminal::poll()
{
  fd_set fds;

  // Uses minimal (1ms) delay in select(2) call to
  // ensure that idling simulations don't chew
  // up masses of CPU time
  static struct timeval	tv = { 0L, 0L };

  FD_ZERO(&fds);
  FD_SET(input_fd, &fds);
  int nready = select(FD_SETSIZE, &fds, NULL, NULL, &tv);

  return nready > 0;
}

Byte Terminal::read()
{
  return (Byte)fgetc(input);
}

void Terminal::write(Byte ch)
{
  fputc(ch, output);
  fflush(output);
}

//------------------------------------------------------------------------
#elif defined(__MSDOS__) || defined(__BORLANDC__)

#include <conio.h>

Terminal::Terminal()
{
}

Terminal::~Terminal()
{
}

int Terminal::poll()
{
  return kbhit();
}

Byte Terminal::read()
{
  return (Byte)getch();
}

void Terminal::write(Byte ch)
{
  putch(ch);
}

#endif
//------------------------------------------------------------------------
