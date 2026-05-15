------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      grclkgatex
-- File:        grclkgatex.vhd
-- Author:      Jiri Gaisler - Gaisler Research
-- Modified:    Jan Andersson - Aeroflex Gaisler
-- Description: Clock gate unit used:
--              .. in systems with dedicated FPUs (fpush = 0)
--              .. in systems with one shared FPU (fpush = 1)
--              .. in systems with one FPU shared between pairs of CPUs
--                 (fpush = 2)
--              .. in systems with dedicated FPUs and separate fpu clocks
--                 (fpush = 0, fpuclken = 1)
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library techmap;
use techmap.gencomp.all;

--pragma translate_off
use std.textio.all;
--pragma translate_on

entity grclkgatex is
  generic (
    tech     : integer := 0;
    pindex   : integer := 0;
    paddr    : integer := 0;
    pmask    : integer := 16#fff#;
    ncpu     : integer := 1;
    nclks    : integer := 8;
    emask    : integer := 0;
    extemask : integer := 0;
    scantest : integer := 0;
    edges    : integer := 0; -- Extra edges after reset complete,
                             -- CPU gets #+3 rising eges out of reset
                             -- other cores #+1 rising edges.
    noinv    : integer := 0; -- Do not use inverted clock on gate enable
    fpush    : integer range 0 to 2 := 0;
    clk2xen  : integer := 0;             -- Enable double clocking
    ungateen : integer := 0; -- Use extra ungate signal for test modes
    fpuclken : integer range 0 to 1 := 0;  -- enable separate clocks for FPU.
                                           -- requires that fpush = 0
    nahbclk  : integer := 1;
    nahbclk2x : integer := 1;
    balance : integer range 1 to 1 := 1
  );
  port (
    rst      : in  std_ulogic;
    clkin    : in  std_ulogic;
    clkin2x  : in  std_ulogic;
    pwd      : in  std_logic_vector(ncpu-1 downto 0);
    fpen     : in  std_logic_vector(ncpu-1 downto 0);
    apbi     : in  apb_slv_in_type;
    apbo     : out apb_slv_out_type;
    gclk     : out std_logic_vector(nclks-1 downto 0);
    reset    : out std_logic_vector(nclks-1 downto 0);
    clkahb   : out std_ulogic;
    clkahb2x : out std_ulogic;
    clkcpu   : out std_logic_vector(ncpu-1 downto 0);
    enable   : out std_logic_vector(nclks-1 downto 0);
    clkfpu   : out std_logic_vector((fpush/2+fpuclken)*(ncpu/(2-fpuclken)-1) downto 0);
    epwen    : in  std_logic_vector(nclks-1 downto 0);
    ungate   : in  std_ulogic;
    clkahbv  : out std_logic_vector(nahbclk-1 downto 0);
    clkahb2xv: out std_logic_vector(nahbclk2x-1 downto 0)
  );
end;

architecture rtl of grclkgatex is

constant REVISION : integer := 1;

constant pconfig : apb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_CLKGATE, 0, REVISION, 0),
  1 => apb_iobar(paddr, pmask));

constant pwen   :  std_logic_vector(nclks-1 downto 0) := conv_std_logic_vector(emask, nclks);
constant nfpuclks : integer := (fpush/2+fpuclken)*(ncpu/(2-fpuclken)-1) + 1;

type registers is record
  unlock        :  std_logic_vector(nclks-1 downto 0);
  clocken       :  std_logic_vector(nclks-1 downto 0);
  reset         :  std_logic_vector(nclks-1 downto 0);
  override      :  std_logic_vector(ncpu-1 downto 0);
  foverride     :  std_logic_vector(ncpu-1 downto 0);
  drstv         :  std_logic_vector(nclks-1 downto 0);
  drstvg        :  std_logic_vector(nclks-1 downto 0);
end record;

type nregisters is record
  clocken       :  std_logic_vector(nclks-1 downto 0);
end record;

signal r, rin : registers;
signal nr, nrin : nregisters;
signal clken : std_logic_vector(nclks-1 downto 0);
signal clk, clk2x, vcc, gnd : std_ulogic;

signal npwd : std_logic_vector(ncpu-1 downto 0);
signal vrst : std_logic_vector(ncpu-1 downto 0);
signal cpuen: std_logic_vector(ncpu-1 downto 0);
signal clkcpuin : std_ulogic;
signal clkn, clknx : std_ulogic;
signal clkncpu, clknxcpu : std_ulogic;
signal fpuen, npwdfpu : std_logic_vector(nfpuclks-1 downto 0);
signal rstx : std_logic_vector(1+edges downto 0);
signal vreset : std_logic_vector(nclks-1 downto 0);
signal vresetf : std_logic_vector(nclks-1 downto 0);

signal lungate : std_ulogic;

begin

  vcc <= '1'; gnd <= '0';
  vreset <= (others => rst);
  vresetf <= (others => rstx(1));
  clknx <= not clk when noinv = 0 else clk;
  clknxcpu <= not clk2x when noinv = 0 else clk2x;

  lungate <= ungate                  when ungateen /= 0 else
             '0';

  scanclknmux : if scantest /= 0 and noinv=0 generate
    clknmux : clkmux generic map(tech => tech)
      port map(i0 => clknx, i1  => clk, sel => apbi.testen, o => clkn, rst => rst);
    clkn2xmux : clkmux generic map(tech => tech)
      port map(i0 => clknxcpu, i1  => clk2x, sel => apbi.testen, o => clkncpu, rst => rst);
  end generate;
  noscanclkmux : if scantest = 0 or noinv /= 0 generate
    clkn <= clknx;
    clkncpu <= clknxcpu;
  end generate;

  comb : process(rst, r, apbi, vreset, epwen)
  variable readdata : std_logic_vector(31 downto 0);
  variable v : registers;
  begin

    v := r; 

-- read registers

    readdata := (others => '0');
    case apbi.paddr(3 downto 2) is
    when "00" => readdata(nclks-1 downto 0) := r.unlock;
    when "01" => readdata(nclks-1 downto 0) := r.clocken;
    when "10" => readdata(nclks-1 downto 0) := r.reset;
    when "11" => readdata(ncpu-1 downto 0) := r.override;
                 if fpush /= 0 or fpuclken /= 0 then
                   readdata(ncpu-1+16 downto 16) := r.foverride;
                 end if;
    when others =>
    end case;

-- write registers

    if (apbi.psel(pindex) and apbi.penable and apbi.pwrite) = '1' then
      case apbi.paddr(4 downto 2) is
      when "000" => v.unlock := apbi.pwdata(nclks-1 downto 0);
      when "001" => 
        for i in 0 to nclks - 1 loop
          if r.unlock(i) = '1' then v.clocken(i) := apbi.pwdata(i); end if;
        end loop;
      when "010" =>
        for i in 0 to nclks - 1 loop
          if r.unlock(i) = '1' then v.reset(i) := apbi.pwdata(i); end if;
        end loop;
      when "011" => v.override := apbi.pwdata(ncpu-1 downto 0);
                    if fpush /= 0 or fpuclken /= 0 then
                      v.foverride := apbi.pwdata(ncpu-1+16 downto 16);
                    end if;
      when others =>
      end case;
    end if;

-- reset operation

    if rst = '0' then
      v.unlock := (others => '0');
      if extemask = 0 then
        v.clocken := pwen;
        v.reset := not pwen;
      else
        v.clocken := epwen;
        v.reset := not epwen;
      end if;
      v.override := (others => '0');
      v.foverride := (others => '0');
    end if;
    if fpush = 0 and fpuclken = 0 then v.foverride := (others => '0'); end if;

    v.drstv  := (others => rst);
    v.drstvg := r.drstv and not r.reset;
    
    rin <= v;

    apbo.prdata <= readdata;    -- drive apb read bus
    apbo.pirq <= (others => '0');

    reset <= r.drstvg and vreset;

  end process;

  apbo.pindex <= pindex;
  apbo.pconfig <= pconfig;

  cand : for i in 0 to nclks-1 generate
    clken(i) <= lungate or nr.clocken(i);
    clkand0 : clkand generic map (tech) port map (clkin, clken(i), gclk(i), apbi.testen);
  end generate;



  enable <= r.clocken;

  hasclk2x : if clk2xen /= 0 generate

    tb : clkand generic map (tech => tech, ren => 0, isdummy => 1) port map (clkin, vcc, clk, apbi.testen, clkahb, clkahbv(0)); --v
    uahbl : for i in 1 to nahbclk-1 generate
      tb : clkand generic map (tech => tech, ren => 0, isdummy => 1) port map (clkin, vcc, clkahbv(i), apbi.testen);
    end generate;

    tb2 : clkand generic map (tech => tech, ren => 0, isdummy => 1) port map (clkin2x, vcc, clk2x, apbi.testen, clkahb2x, clkahb2xv(0));
    uahbl2x : for i in 1 to nahbclk2x-1 generate
      tb : clkand generic map (tech => tech, ren => 0, isdummy => 1) port map (clkin2x, vcc, clkahb2xv(i), apbi.testen);
    end generate;

  end generate;

  noclk2x : if clk2xen = 0 generate

    -- Make 2x duplicate of 1x, use same clkand for clkahbv(j) and clkahbv2x(j)
    tb : clkand generic map (tech => tech, ren => 0, isdummy => 1) port map (clkin, vcc, clk, apbi.testen, clkahb, clkahbv(0), clkahb2x, clkahb2xv(0)); --v
    clk2x <= clk;
    uahbl : for i in 1 to nahbclk-1 generate
      inc2x: if i < nahbclk2x generate
        tb : clkand generic map (tech => tech, ren => 0, isdummy => 1) port map (clkin, vcc, clkahbv(i), apbi.testen, clkahb2xv(i));
      end generate;
      notinc2x: if i >= nahbclk2x generate
        tb : clkand generic map (tech => tech, ren => 0, isdummy => 1) port map (clkin, vcc, clkahbv(i), apbi.testen);
      end generate;
    end generate;
    uahbl2: for i in nahbclk to nahbclk2x-1 generate
        tb : clkand generic map (tech => tech, ren => 0, isdummy => 1) port map (clkin, vcc, clkahb2xv(i), apbi.testen);
    end generate;
  end generate;

-- registers

  regs : process(clk, rst)
  begin
    if rising_edge(clk) then r <= rin; end if;
  end process;

  -- if noinv is set, use source clock directly instead of clkn to get delta matching
  nregsnoinv: if noinv=1 generate
    nregs : process(clk, rst)
    begin
      if rising_edge(clk) then nr.clocken <= r.clocken or not vresetf; end if;
    end process;
  end generate;
  nregsinv: if noinv=0 generate
    nregs : process(clkn, rst)
    begin
      if rising_edge(clkn) then nr.clocken <= r.clocken or not vresetf; end if;
    end process;
  end generate;


  clkcpuin <= clkin when (clk2xen = 0) else clkin2x;
  
  cpuand : for i in 0 to ncpu-1 generate
    cpuen(i) <= lungate or not npwd(i);
    cpuand0 : clkand generic map (tech) port map (clkcpuin, cpuen(i), clkcpu(i), apbi.testen);
  end generate;

  shfpu : if fpush /= 0 or fpuclken /= 0 generate
    fpugate: for i in fpuen'range generate
      fpuen(i) <= lungate or not npwdfpu(i);
      fpuand : clkand generic map (tech) port map (clkcpuin, fpuen(i), clkfpu(i), apbi.testen);
    end generate;
  end generate;
  noshfpu : if fpush = 0 and fpuclken = 0 generate
    fpuen <= (others => '0');
    clkfpu <= (others => '0');
  end generate;

  vrst <= (others => rstx(rstx'left));

  nregnoinv1x: if noinv=1 and clk2xen=0 generate
    nreg : process(clk)
    begin
      if rising_edge(clk) then
        npwd <= pwd and (not r.override) and vrst;
        if fpush = 1 then
          npwdfpu(0) <= andv(pwd or not (fpen or r.foverride)) and (not orv(r.override)) and rstx(rstx'left);
        end if;
        if fpush = 2 then
          for i in fpuen'range loop
            npwdfpu(i) <= andv(pwd(1+2*i downto 2*i) or not
                               (fpen(1+2*i downto 2*i) or r.foverride(1+2*i downto 2*i))) and
                          (not orv(r.override(1+2*i downto 2*i))) and rstx(rstx'left);
          end loop;
        end if;
        if fpuclken /= 0 then
          for i in fpuen'range loop
            npwdfpu(i) <= (pwd(i) or not (fpen(i) or r.foverride(i))) and (not r.override(i)) and rstx(rstx'left);
          end loop;
        end if;
        rstx <= rstx(rstx'left-1 downto 0) & rst;
        if fpush = 0 and fpuclken = 0 then npwdfpu <= (others => '0'); end if;
      end if;
    end process;
  end generate;

  nregnoinv2x: if noinv=1 and clk2xen /= 0 generate
    nreg : process(clk2x)
    begin
      if rising_edge(clk2x) then
        npwd <= pwd and (not r.override) and vrst;
        if fpush = 1 then
          npwdfpu(0) <= andv(pwd or not (fpen or r.foverride)) and (not orv(r.override)) and rstx(rstx'left);
        end if;
        if fpush = 2 then
          for i in fpuen'range loop
            npwdfpu(i) <= andv(pwd(1+2*i downto 2*i) or not
                               (fpen(1+2*i downto 2*i) or r.foverride(1+2*i downto 2*i))) and
                          (not orv(r.override(1+2*i downto 2*i))) and rstx(rstx'left);
          end loop;
        end if;
        if fpuclken /= 0 then
          for i in fpuen'range loop
            npwdfpu(i) <= (pwd(i) or not (fpen(i) or r.foverride(i))) and (not r.override(i)) and rstx(rstx'left);
          end loop;
        end if;
        rstx <= rstx(rstx'left-1 downto 0) & rst;
        if fpush = 0 and fpuclken = 0 then npwdfpu <= (others => '0'); end if;
      end if;
    end process;
  end generate;

  nreginv: if noinv=0 generate
    nreg : process(clkncpu)
    begin
      if rising_edge(clkncpu) then
        npwd <= pwd and (not r.override) and vrst;
        if fpush = 1 then
          npwdfpu(0) <= andv(pwd or not (fpen or r.foverride)) and (not orv(r.override)) and rstx(rstx'left);
        end if;
        if fpush = 2 then
          for i in fpuen'range loop
            npwdfpu(i) <= andv(pwd(1+2*i downto 2*i) or not
                               (fpen(1+2*i downto 2*i) or r.foverride(1+2*i downto 2*i))) and
                          (not orv(r.override(1+2*i downto 2*i))) and rstx(rstx'left);
          end loop;
        end if;
        if fpuclken /= 0 then
          for i in fpuen'range loop
            npwdfpu(i) <= (pwd(i) or not (fpen(i) or r.foverride(i))) and (not r.override(i)) and rstx(rstx'left);
          end loop;
        end if;
        rstx <= rstx(rstx'left-1 downto 0) & rst;
        if fpush = 0 and fpuclken = 0 then npwdfpu <= (others => '0'); end if;
      end if;
    end process;
  end generate;

-- boot message

-- pragma translate_off
    bootmsg : report_version
    generic map ("grclkgatex" & tost(pindex) &
        ": " &  tost(nclks) & "-bit Clock Gating Unit rev " & tost(REVISION));
-- pragma translate_on

end;

