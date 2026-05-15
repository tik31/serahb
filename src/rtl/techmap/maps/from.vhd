------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
library ieee;
use ieee.std_logic_1164.all;
use work.gencomp.all;
use work.allmem.all;

entity from is
   generic (
      tech:             integer := 0;
      timingcheckson:   boolean := True;
      instancepath:     string  := "*";
      xon:              boolean := False;
      msgon:            boolean := True;
      data_x:           integer := 1;
      memoryfile:       string  := "";
      progfile:         string  := "");
  port (
      clk:     in    std_ulogic;
      addr:    in    std_logic_vector(6 downto 0);
      data:    out   std_logic_vector(7 downto 0));
end entity;

architecture rtl of from is
begin

   inf: if tech=inferred generate
-- pragma translate_off
      process
      begin
         report "Inferred Flash PROM not supported"
            severity Failure;
         wait;
      end process;
-- pragma translate_on
   end generate;

   -- ProASIC3:
   proa3: if tech=apa3 generate
      UFROMH0 : proasic3_from
         generic map(
            TimingChecksOn => timingcheckson,
            InstancePath   => instancepath,
            Xon            => xon,
            MsgOn          => msgon,
            DATA_X         => data_x,
            MEMORYFILE     => memoryfile,
            ACT_PROGFILE   => progfile)
         port map(
            CLK            => clk,
            DO0            => data(0),
            DO1            => data(1),
            DO2            => data(2),
            DO3            => data(3),
            DO4            => data(4),
            DO5            => data(5),
            DO6            => data(6),
            DO7            => data(7),
            ADDR0          => addr(0),
            ADDR1          => addr(1),
            ADDR2          => addr(2),
            ADDR3          => addr(3),
            ADDR4          => addr(4),
            ADDR5          => addr(5),
            ADDR6          => addr(6));
   end generate;

   -- ProASIC3E:
   proa3e: if tech=apa3e generate
      UFROMH0 : proasic3e_from
         generic map(
            TimingChecksOn => timingcheckson,
            InstancePath   => instancepath,
            Xon            => xon,
            MsgOn          => msgon,
            DATA_X         => data_x,
            MEMORYFILE     => memoryfile,
            ACT_PROGFILE   => progfile)
         port map(
            CLK            => clk,
            DO0            => data(0),
            DO1            => data(1),
            DO2            => data(2),
            DO3            => data(3),
            DO4            => data(4),
            DO5            => data(5),
            DO6            => data(6),
            DO7            => data(7),
            ADDR0          => addr(0),
            ADDR1          => addr(1),
            ADDR2          => addr(2),
            ADDR3          => addr(3),
            ADDR4          => addr(4),
            ADDR5          => addr(5),
            ADDR6          => addr(6));
   end generate;

   -- ProASIC3L:
   proa3l: if tech=apa3l generate
      UFROMH0 : proasic3l_from
         generic map(
            TimingChecksOn => timingcheckson,
            InstancePath   => instancepath,
            Xon            => xon,
            MsgOn          => msgon,
            DATA_X         => data_x,
            MEMORYFILE     => memoryfile,
            ACT_PROGFILE   => progfile)
         port map(
            CLK            => clk,
            DO0            => data(0),
            DO1            => data(1),
            DO2            => data(2),
            DO3            => data(3),
            DO4            => data(4),
            DO5            => data(5),
            DO6            => data(6),
            DO7            => data(7),
            ADDR0          => addr(0),
            ADDR1          => addr(1),
            ADDR2          => addr(2),
            ADDR3          => addr(3),
            ADDR4          => addr(4),
            ADDR5          => addr(5),
            ADDR6          => addr(6));
   end generate;

   -- Fusion:
   fusion: if tech=actfus generate
      UFROMH0 : fusion_from
         generic map(
            TimingChecksOn => timingcheckson,
            InstancePath   => instancepath,
            Xon            => xon,
            MsgOn          => msgon,
            DATA_X         => data_x,
            MEMORYFILE     => memoryfile,
            ACT_PROGFILE   => progfile)
         port map(
            CLK            => clk,
            DO0            => data(0),
            DO1            => data(1),
            DO2            => data(2),
            DO3            => data(3),
            DO4            => data(4),
            DO5            => data(5),
            DO6            => data(6),
            DO7            => data(7),
            ADDR0          => addr(0),
            ADDR1          => addr(1),
            ADDR2          => addr(2),
            ADDR3          => addr(3),
            ADDR4          => addr(4),
            ADDR5          => addr(5),
            ADDR6          => addr(6));
   end generate;

end architecture rtl; --======================================================--

