#!/bin/perl -w

use strict;
use Getopt::Std;

my %opt;

getopts('s:n:r', \%opt);

my $bin_filename = shift @ARGV;
my $instance_name = ($opt{n} or ($opt{r} ? "ROM" : "RAM"));

sub usage {
    die "usage: $0 [-s <size>] <input>.bin\n";
}

usage() unless ($bin_filename);

if ($bin_filename !~ /(.*)\.bin$/) {
    print STDERR "$0: Bad file suffix\n";
    usage();
}
my $vhdl_filename = "$1.vhd";

open(BIN, $bin_filename) or die "$0: can't open input file $bin_filename: $!\n";
open(VHDL, ">$vhdl_filename") or die "$0: can't open vhdl output file $vhdl_filename for writing: $!\n";

my $end = 0;

my $DATA;
my $length = read(BIN, $DATA, 10000000);

my $rom_size = ($opt{s} or $length);

die "empty rom" unless ($rom_size);

print VHDL "
-- Automatically generated ROM initialization definitions for System09
-- Converted from binary file $bin_filename
-- DO NOT EDIT!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ${instance_name} is
  Port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    cs    : in  std_logic;",
    ($opt{r} ? "" : "
    we    : in  std_logic;
    wdata : in  std_logic;"), "
    addr  : in  std_logic_vector (13 downto 0);
    rdata : out std_logic_vector (7 downto 0)
    );
end ${instance_name};

architecture rtl of ${instance_name} is

  signal dp    : std_logic_vector(7 downto 0);
  signal ce    : std_logic_vector(7 downto 0);
  signal data_0 : std_logic_vector(7 downto 0);
  signal data_1 : std_logic_vector(7 downto 0);
  signal data_2 : std_logic_vector(7 downto 0);
  signal data_3 : std_logic_vector(7 downto 0);
  signal data_4 : std_logic_vector(7 downto 0);
  signal data_5 : std_logic_vector(7 downto 0);
  signal data_6 : std_logic_vector(7 downto 0);
  signal data_7 : std_logic_vector(7 downto 0);

begin

";

for (my $page = 0; $page < 8; $page++) {
    print VHDL "
  ${instance_name}${page} : RAMB16_S9
    generic map (
";
    for (my $row = 0; $row < 0x40; $row++) {
        printf VHDL "      INIT_%02x => x\"", $row;
        for (my $byte = 31; $byte >= 0; $byte--) {
            printf VHDL "%02x", ord(substr($DATA, $page * 2048 + $row * 32 + $byte));
        }
        if ($row != 0x3f) {
            printf VHDL "\",\n";
        } else {
            printf VHDL "\")";
        }
    }
    print VHDL "
    port map (
      do   => data_${page},
      dop(0) => dp(${page}),
      addr => addr(10 downto 0),
      clk  => clk,
      di   => ", ($opt{r} ? "(others => '0')" : "wdata"), ",
      dip(0) => dp(${page}),
      en   => ce(${page}),
      ssr  => rst,
      we   => ", ($opt{r} ? "'0'" : "we"), "
      );
";
}

print VHDL "
  my_${instance_name} : process ( cs, addr,
                                  data_0, data_1, data_2, data_3,
                                  data_4, data_5, data_6, data_7)
  begin
    case addr(13 downto 11) is
      when \"000\" =>
        rdata <= data_0;
      when \"001\" =>
        rdata <= data_1;
      when \"010\" =>
        rdata <= data_2;
      when \"011\" =>
        rdata <= data_3;
      when \"100\" =>
        rdata <= data_4;
      when \"101\" =>
        rdata <= data_5;
      when \"110\" =>
        rdata <= data_6;
      when \"111\" =>
        rdata <= data_7;
      when others =>
        null;
    end case;

  end process;

  ce <= \"00000001\" when cs = '1' and addr(13 downto 11) = \"000\" else
        \"00000010\" when cs = '1' and addr(13 downto 11) = \"001\" else
        \"00000100\" when cs = '1' and addr(13 downto 11) = \"010\" else
        \"00001000\" when cs = '1' and addr(13 downto 11) = \"011\" else
        \"00010000\" when cs = '1' and addr(13 downto 11) = \"100\" else
        \"00100000\" when cs = '1' and addr(13 downto 11) = \"101\" else
        \"01000000\" when cs = '1' and addr(13 downto 11) = \"110\" else
        \"10000000\" when cs = '1' and addr(13 downto 11) = \"111\" else
        \"00000000\";

end architecture rtl;
";

printf "generated vhdl $vhdl_filename size: 0x%04x\n", $rom_size;
