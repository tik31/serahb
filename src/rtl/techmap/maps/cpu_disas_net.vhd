------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Package: 	cpu_disas_net
-- File:	cpu_disas_net.vhd
-- Author:	Jiri Gaisler, Gaisler Research
-- Description:	SPARC disassembler according to SPARC V8 manual 
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
-- pragma translate_off
library grlib;
use grlib.stdlib.all;
use grlib.sparc.all;
use grlib.sparc_disas.all;
-- pragma translate_on

entity cpu_disas_net is
port (
  clk   : in std_ulogic;
  rstn  : in std_ulogic;
  dummy : out std_ulogic;
  inst  : in std_logic_vector(31 downto 0);
  pc    : in std_logic_vector(31 downto 2);
  result: in std_logic_vector(31 downto 0);
  index : in std_logic_vector(3 downto 0);
  wreg  : in std_ulogic;
  annul : in std_ulogic;
  holdn : in std_ulogic;
  pv    : in std_ulogic;
  trap  : in std_ulogic;
  disas : in std_ulogic);
end;

architecture behav of cpu_disas_net is
begin

  dummy <= '1';

-- pragma translate_off
  trc : process(clk)
    variable valid : boolean;
    variable op : std_logic_vector(1 downto 0);
    variable op3 : std_logic_vector(5 downto 0);
    variable fpins, fpld : boolean;    
    variable iindex : integer;
  begin
      iindex := conv_integer(index);
      op := inst(31 downto 30); op3 := inst(24 downto 19);
      fpins := (op = FMT3) and ((op3 = FPOP1) or (op3 = FPOP2));
      fpld := (op = LDST) and ((op3 = LDF) or (op3 = LDDF) or (op3 = LDFSR));
      valid := (((not annul) and pv) = '1') and (not ((fpins or fpld) and (trap = '0')));
      valid := valid and (holdn = '1');
    if rising_edge(clk) and (rstn = '1') and (disas = '1') then
      print_insn (iindex, pc(31 downto 2) & "00", inst, 
                  result, valid, trap = '1', wreg = '1'
                  , false
                  );
    end if;
  end process;
-- pragma translate_on

end;
  
library ieee;
use ieee.std_logic_1164.all;
-- pragma translate_off
library grlib;
use grlib.stdlib.all;
use grlib.sparc.all;
use grlib.sparc_disas.all;
-- pragma translate_on

entity fpu_disas_net is
port (
  clk   : in std_ulogic;
  rstn  : in std_ulogic;
  dummy : out std_ulogic;
  wr2inst  : in std_logic_vector(31 downto 0);
  wr2pc    : in std_logic_vector(31 downto 2);
  divinst  : in std_logic_vector(31 downto 0);
  divpc    : in std_logic_vector(31 downto 2);
  dbg_wrdata: in std_logic_vector(63 downto 0);
  index : in std_logic_vector(3 downto 0);
  dbg_wren : in std_logic_vector(1 downto 0);
  resv  : in std_ulogic;
  ld    : in std_ulogic;
  rdwr  : in std_ulogic;
  ccwr  : in std_ulogic;
  rdd   : in std_ulogic;
  div_valid  : in std_ulogic;
  holdn : in std_ulogic;
  disas : in std_ulogic);
end;

architecture behav of fpu_disas_net is
begin

  dummy <= '1';

-- pragma translate_off

  trc : process(clk)
    variable valid : boolean;
    variable op : std_logic_vector(1 downto 0);
    variable op3 : std_logic_vector(5 downto 0);
    variable fpins, fpld : boolean;    
    variable iindex : integer;
  begin
    iindex := conv_integer(index);

    if rising_edge(clk) and (rstn = '1') and (disas /= '0') then
         valid := ((((rdwr and not ld) or ccwr or (ld and resv)) and holdn) = '1');
         print_fpinsn(0, wr2pc(31 downto 2) & "00", wr2inst, dbg_wrdata,
                      (rdd = '1'), valid, false, (dbg_wren /= "00"));
         print_fpinsn(0, divpc(31 downto 2) & "00", divinst, dbg_wrdata,
                      (rdd = '1'), (div_valid and holdn) = '1', false, (dbg_wren /= "00"));
    end if;
  end process;

-- pragma translate_on

end;


