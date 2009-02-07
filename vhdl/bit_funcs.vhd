library IEEE;
   use IEEE.std_logic_1164.all;
   use IEEE.std_logic_arith.all;
   use IEEE.std_logic_unsigned.all;

package bit_funcs is
   function log2(v: in natural) return natural;
   function pow2(v: in natural) return natural;
end package bit_funcs;

package body bit_funcs is
   function log2(v: in natural) return natural is
      variable i: natural;
      variable n: natural;
      variable logn: natural;
   begin
      n := 1;
      for i in 0 to 128 loop
         logn := i;
         exit when (n>=v);
         n := n * 2;
      end loop;
      return logn;
   end function log2;

   function pow2(v: in natural) return natural is
      variable i: natural;
      variable pown: natural;
   begin
      pown := 1;
      for i in 0 to v loop
         exit when (i=v);
         pown := pown * 2;
      end loop;
      return pown;
   end function pow2;

end package body bit_funcs;
