//
//	main.cc
//

#include <string>
#include <queue>
#include <iostream>
#include <fstream>
#include <sstream>

#include <errno.h>

#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#ifdef X11
#include "mc6809_X.h"
#else
#include "mc6809.h"
#endif
#include "mc6850.h"

#if defined(__unix) || defined(__APPLE__)
#include <unistd.h>
#endif

#ifdef __osf__
extern "C" unsigned int alarm(unsigned int);
#endif

#define UART_ADDR 0xB000

using namespace std;

class bad_stream {};

class sys
  : virtual public
#ifdef X11
mc6809_X
#else
mc6809
#endif
{
public:
  sys()
    : current_input_stream(0),
      suppress_serial_output(false),
      exit_on_error(false),
      himem(0x4000)
  {}

protected:
  virtual Byte read(Word);
  virtual void write(Word, Byte);

  virtual void sync() { uart.term.poll(); };
  virtual void swi2();

protected:
  mc6850 uart;

private:
  // The dumpfile member variable contains the name of the file to
  // dump the RAM contents to when the SWI2 DUMP-CORE instruction is
  // executed.
  string dumpfile;

  // In order to be able to load Forth code into the simulated system
  // from the command line, the emulator keeps a list of input
  // streams, each of which contains characters that the emulator
  // should read from the virtual terminal.  Once all these input
  // streams are exhausted, the terminal is read for further input.
  // The streams are owned by the "sys" object and are deleted once
  // their end has been reached.
  istream* current_input_stream;
  queue<istream*> input_streams;

public:
  void set_dumpfile(const string& dumpfile) { this->dumpfile = dumpfile; }
  void dump_ram();
  void read_ram_initfile(const char* ram_initfile);
  void add_input_stream(istream* is);

private:
  Byte read_next_from_streams();

  // suppress_serial_output can be set to suppress output to the
  // serial port, for batch compile operations.

private:
  bool suppress_serial_output;

public:
  void set_suppress_serial_output(bool state) { suppress_serial_output = state; }

  // exit_on_error can be set to make the emulator exit when Forth
  // signals an error.
private:
  bool exit_on_error;

public:
  void set_exit_on_error(bool state) { exit_on_error = state; }

  // himem is the amount of RAM that the simulated system has
private:
  long himem;

public:
  void set_himem(long addr) { himem = addr; }

} sys;

void
sys::add_input_stream(istream* is)
{
  if (!is->good() || is->peek() == is->eof()) {
    throw bad_stream();
  }
  input_streams.push(is);
}

Byte
sys::read_next_from_streams()
{
  if (!current_input_stream) {
    current_input_stream = input_streams.front();
    input_streams.pop();
  }
  char retval;
  current_input_stream->get(retval);
  if (current_input_stream->eof()) {
    cerr << "Error reading from initialization stream (unexpected eof)" << endl;
    throw bad_stream();
  }
  if (current_input_stream->peek() == EOF) {
    delete current_input_stream;
    current_input_stream = 0;
  }
  if (retval == '\n') {
    retval = '\r';
  }
  return (Byte) retval;
}

Byte sys::read(Word addr)
{
  Byte		ret = 0;

  if ((addr & 0xfffe) == UART_ADDR) {
    if (current_input_stream || input_streams.size()) {
      if (addr & 1) {
        ret = read_next_from_streams();
      } else {
        ret = 1 | uart.read(addr);                // indicate data available
      }
    } else {
      if (suppress_serial_output && (addr & 1)) {
        cerr << "cannot read from virtual serial port when output is suppressed" << endl;
        exit(1);
      }
      ret = uart.read(addr);
    }
  } else {
    ret = mc6809::read(addr);
  }

  return ret;
}

void sys::write(Word addr, Byte x)
{
  if ((addr & 0xC000) == 0xC000) {
    printf("\r\ninvalid write to 0x%04x\r\n", addr);
  }
  if ((addr & 0xfffe) == UART_ADDR) {
    if (!suppress_serial_output || !(addr & 1)) {
      uart.write(addr, x);
    }
  } else if (addr < himem) {
    mc6809::write(addr, x);
  }
}

void sys::swi2() {
  cout << "\r\n";
  // cout << "SWI2: a: " << (int) a << " b: " << (int) b << endl;
  switch (a) {
  case 0:
    // normal exit initiated from Forth
    exit(0);
  case 1:
    if (exit_on_error) {
      cerr << "Maisforth detected error, forced exit." << endl;
      if (suppress_serial_output) {
        cerr << "Run usim without -q to see diagnostic output." << endl;
      }
      exit(1);
    }
    break;
  case 2:
    dump_ram();
    break;
  }
}

void sys::dump_ram() {
  ofstream of(dumpfile.c_str(), ios::binary);
  for (int i = 0; i < himem; i++) {
    of.put(read(i));
  }
  cout << "dump file " << dumpfile << " has been created" << endl;
  exit(0);
}

void sys::read_ram_initfile(const char* ram_initfile) {
  ifstream initfile(ram_initfile, ios::binary);
  if (!initfile.good()) {
    cerr << "cannot open dump file " << ram_initfile << " (" << strerror(errno) << ")" << endl;
    exit(1);
  }
  char c;
  for (int i = 0; i < himem; i++) {
    if (initfile.eof()) {
      cerr << "premature EOF in dump file " << ram_initfile << endl;
      exit(1);
    }
    initfile.get(c);
    mc6809::write(i, c);
  }
  initfile.get(c);
  if (!initfile.eof()) {
    cerr << "excess bytes in dump file " << ram_initfile << endl;
    exit(1);
  }
  cout << "dump file " << ram_initfile << " read" << endl;
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
  fprintf(stderr, "usage: usim [ -r ] [ -q ] [ -x ] [ -t <traceopts> ] [ -d <dumpfile> ] [ -i <ram-initfile> ] [ -f <forth-file> ] [ -e <forth-expression> ] [ -h <himem> ] <rom-hexfile>\n");
  exit(EXIT_FAILURE);
}

int main(int argc, char *argv[])
{
  progname = argv[0];
  const char* dumpfile = "usim-core.bin";

  (void)signal(SIGINT, SIG_IGN);
#ifdef SIGALRM
  (void)signal(SIGALRM, update);
  alarm(1);
#endif

  bool read_start_from_file = false;
  const char* ram_initfile = 0;
  long himem = 0x4000;
  bool suppress_serial_output = false;
  bool exit_on_error = false;
  int c;
  const char* trace = 0;

  while ((c = getopt(argc, argv, "rt:d:i:f:e:h:qx")) != -1) {
    switch (c) {
    case 'r':
      read_start_from_file = true;
      break;
    case 't':
      trace = optarg;
      break;
    case 'd':
      dumpfile = optarg;
      break;
    case 'i':
      ram_initfile = optarg;
      break;
    case 'f':
      try {
        sys.add_input_stream(new ifstream(optarg));
      }
      catch (bad_stream&) {
        cerr << "invalid input file " << optarg << endl;
      }
      break;
    case 'e':
      try {
        sys.add_input_stream(new istringstream(string(optarg) + "\r"));
      }
      catch (bad_stream&) {
        cerr << "zero-length string to -e option not permitted" << endl;
      }
      break;
    case 'h':
      himem = strtol(optarg, 0, 0);
      if (himem == 0) {
        cerr << "invalid himem spec (not a number?)" << endl;
        exit(1);
      }
      if (himem < 1024) {
        cerr << "can't run with less than 1 kilobyte of RAM" << endl;
        exit(1);
      }
      if (himem % 1024) {
        cerr << "expected himem to be multiples of 1024" << endl;
        exit(1);
      }
      if (himem > 32*1024) {
        cerr << "more than 32 kilobytes of RAM are not supported" << endl;
        exit(1);
      }
      break;
    case 'q':
      suppress_serial_output = true;
      exit_on_error = true;
      break;
    case 'x':
      exit_on_error = true;
      break;
    default:
      usage();
    }
  }

  if (argc == optind) {
    usage();
  }

  sys.set_suppress_serial_output(suppress_serial_output);
  sys.set_exit_on_error(exit_on_error);
  sys.set_dumpfile(dumpfile);
  sys.set_himem(himem);
  if (ram_initfile) {
    sys.read_ram_initfile(ram_initfile);
  }
  sys.load_intelhex(argv[optind], read_start_from_file);
  sys.reset();
  if (trace) {
    sys.trace(trace);
  }
  sys.run();

  return EXIT_SUCCESS;
}
