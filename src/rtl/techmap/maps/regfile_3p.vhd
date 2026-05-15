------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	regfile_3p
-- File:	regfile_3p.vhd
-- Author:	Jiri Gaisler Gaisler Research
-- Description:	3-port regfile implemented with two 2-port rams
------------------------------------------------------------------------------

library ieee;
library techmap;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;
use techmap.allmem.all;

entity regfile_3p is
  generic (tech : integer := 0; abits : integer := 6; dbits : integer := 8;
           wrfst : integer := 0; numregs : integer := 64; testen : integer := 0;
           custombits : integer := 1);
  port (
    wclk   : in  std_ulogic;
    waddr  : in  std_logic_vector((abits -1) downto 0);
    wdata  : in  std_logic_vector((dbits -1) downto 0);
    we     : in  std_ulogic;
    rclk   : in  std_ulogic;
    raddr1 : in  std_logic_vector((abits -1) downto 0);
    re1    : in  std_ulogic;
    rdata1 : out std_logic_vector((dbits -1) downto 0);
    raddr2 : in  std_logic_vector((abits -1) downto 0);
    re2    : in  std_ulogic;
    rdata2 : out std_logic_vector((dbits -1) downto 0);
    ce1    : out std_ulogic;
    ce2    : out std_ulogic;
    testin   : in std_logic_vector(TESTIN_WIDTH-1 downto 0) := testin_none
    );
end;

architecture rtl of regfile_3p is
  constant rfinfer : boolean := (regfile_3p_infer(tech) = 1) or
	(((is_unisim(tech) = 1)) and (abits <= 5));
  signal xwe,xre1,xre2 : std_ulogic;

  constant rfinfer_tmr: boolean := (tech=rhs65 or tech=memrhs65b);

  function mvote (a, b, c : std_ulogic) return std_ulogic is
  begin
    return((a and b) or (a and c) or (b and c));
  end;

  function mvote (a, b, c : std_logic_vector) return std_logic_vector is
  variable x : std_logic_vector (a'range);
  begin
    for i in 0 to a'high-a'low loop
      x(i) := mvote(a(i+a'low), b(i+b'low), c(i+c'low));
    end loop;
    return(x);
  end;

  function chkdiff (a, b, c: std_logic_vector;
                    ae,be,ce: std_ulogic) return std_ulogic is
    variable r : std_ulogic;
  begin
    r := '0';
    if a /= b or b /= c then
      r := '1';
    end if;
    if ae='0' and be='0' and ce='0' then
      r := '0';
    end if;
    return r;
  end;

  signal rdata11,rdata12,rdata13,rdata21,rdata22,rdata23: std_logic_vector(dbits-1 downto 0);
  signal prdata11,prdata12,prdata13,prdata21,prdata22,prdata23: std_logic_vector(dbits-1 downto 0);
  signal pre11,pre21,pre12,pre22,pre13,pre23: std_ulogic;

  signal custominx,customoutx: std_logic_vector(syncram_customif_maxwidth downto 0);
  
begin
  xwe <= we and not testin(TESTIN_WIDTH-2) when testen/=0 else we;
  xre1 <= re1 and not testin(TESTIN_WIDTH-2) when testen/=0 else re1;
  xre2 <= re2 and not testin(TESTIN_WIDTH-2) when testen/=0 else re2;
  
  s0 : if rfinfer generate
    nom: if not rfinfer_tmr generate
      rhu : generic_regfile_3p generic map (tech, abits, dbits, wrfst, numregs)
        port map ( wclk, waddr, wdata, we, rclk, raddr1, re1, rdata1, raddr2, re2, rdata2);
      ce1 <= '0';
      ce2 <= '0';
    end generate;
    tmr0: if rfinfer_tmr generate
      rhu_tmr1 : generic_regfile_3p generic map (tech, abits, dbits, wrfst, numregs, 1)
        port map ( wclk, waddr, wdata, we, rclk, raddr1, re1, rdata11, raddr2, re2, rdata21,
                   pre11, pre21, prdata11, prdata21);
      rhu_tmr2 : generic_regfile_3p generic map (tech, abits, dbits, wrfst, numregs, 1)
        port map ( wclk, waddr, wdata, we, rclk, raddr1, re1, rdata12, raddr2, re2, rdata22,
                   pre12, pre22, prdata12, prdata22);
      rhu_tmr3 : generic_regfile_3p generic map (tech, abits, dbits, wrfst, numregs, 1)
        port map ( wclk, waddr, wdata, we, rclk, raddr1, re1, rdata13, raddr2, re2, rdata23,
                   pre13, pre23, prdata13, prdata23);
      rdata1 <= mvote(rdata11,rdata12,rdata13);
      rdata2 <= mvote(rdata21,rdata22,rdata23);
      ce1 <= chkdiff(rdata11,rdata12,rdata13,pre11,pre12,pre13);
      ce2 <= chkdiff(rdata21,rdata22,rdata23,pre21,pre22,pre23);
    end generate;
    
  end generate;

  s1 : if not rfinfer generate
    pere : if tech = peregrine generate
      rfhard : peregrine_regfile_3p generic map (abits, dbits)
      port map ( wclk, waddr, wdata, xwe, raddr1, xre1, rdata1, raddr2, xre2, rdata2);
    end generate;
    dp : if tech /= peregrine generate
      x0 : syncram_2p generic map (tech, abits, dbits, 0, wrfst, testen, 0, custombits)
        port map (rclk, re1, raddr1, rdata1, wclk, we, waddr, wdata, testin
                  );
      x1 : syncram_2p generic map (tech, abits, dbits, 0, wrfst, testen, 0, custombits)
        port map (rclk, re2, raddr2, rdata2, wclk, we, waddr, wdata, testin
                  );
    end generate;
  end generate;

    custominx <= (others => '0');
  nocust: if syncram_has_customif(tech)=0 or rfinfer generate
    customoutx <= (others => '0');
  end generate;
end;

