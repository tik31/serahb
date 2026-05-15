--
-- SPI PHY standalone testbench
-- Instantiates one spi_phy as master and one as slave, cross-wires them,
-- and verifies data integrity for five test scenarios.
--
-- Library: spi
-- Clock period: 20 ns (50 MHz sys_clk)
-- Reset: active-low synchronous, released after 100 ns
--
-- Simulation termination: assert false ... severity failure (ModelSim 10.2c style)
--
-- Created:
--          by - irz design team
--          at - 05.2026
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_tb is
end entity spi_tb;

architecture behav of spi_tb is

    -- -----------------------------------------------------------------------
    -- Constants
    -- -----------------------------------------------------------------------
    constant CLK_PERIOD : time    := 20 ns;
    constant RST_HOLD   : time    := 100 ns;

    -- -----------------------------------------------------------------------
    -- DUT component
    -- -----------------------------------------------------------------------
    component spi_phy is
        generic(
            g_master  : boolean := true;
            g_clk_div : integer := 5
        );
        port(
            clk        : in  std_logic;
            rstn       : in  std_logic;
            tx_byte_i  : in  std_logic_vector(7 downto 0);
            tx_valid_i : in  std_logic;
            tx_req_o   : out std_logic;
            rx_byte_o  : out std_logic_vector(7 downto 0);
            rx_valid_o : out std_logic;
            sclk_o     : out std_logic;
            sclk_i     : in  std_logic;
            mosi_o     : out std_logic;
            mosi_i     : in  std_logic;
            miso_o     : out std_logic;
            miso_i     : in  std_logic;
            ss_n_o     : out std_logic;
            ss_n_i     : in  std_logic
        );
    end component spi_phy;

    -- -----------------------------------------------------------------------
    -- Signals
    -- -----------------------------------------------------------------------
    signal clk  : std_logic := '0';
    signal rstn : std_logic := '0';

    -- Master byte interface
    signal m_tx_byte  : std_logic_vector(7 downto 0) := (others => '0');
    signal m_tx_valid : std_logic := '0';
    signal m_tx_req   : std_logic;
    signal m_rx_byte  : std_logic_vector(7 downto 0);
    signal m_rx_valid : std_logic;

    -- Slave byte interface
    signal s_tx_byte  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_tx_valid : std_logic := '0';
    signal s_tx_req   : std_logic;
    signal s_rx_byte  : std_logic_vector(7 downto 0);
    signal s_rx_valid : std_logic;

    -- SPI bus wires
    signal spi_sclk : std_logic;
    signal spi_mosi : std_logic;
    signal spi_miso : std_logic;
    signal spi_ss_n : std_logic;

    -- Test sequencing signals
    signal test_phase : integer := 0;
    signal test_done  : std_logic := '0';

    -- Failure counter (plain signal, not shared variable, to avoid VHDL-87/93 restriction)
    signal fail_count : integer := 0;

begin

    -- -----------------------------------------------------------------------
    -- Clock and reset
    -- -----------------------------------------------------------------------
    clk  <= not clk after CLK_PERIOD / 2;
    rstn <= '1' after RST_HOLD;

    -- -----------------------------------------------------------------------
    -- DUT: Master
    -- -----------------------------------------------------------------------
    u_master : spi_phy
        generic map(g_master => true, g_clk_div => 5)
        port map(
            clk        => clk,
            rstn       => rstn,
            tx_byte_i  => m_tx_byte,
            tx_valid_i => m_tx_valid,
            tx_req_o   => m_tx_req,
            rx_byte_o  => m_rx_byte,
            rx_valid_o => m_rx_valid,
            sclk_o     => spi_sclk,
            sclk_i     => '0',
            mosi_o     => spi_mosi,
            mosi_i     => '0',
            miso_o     => open,
            miso_i     => spi_miso,
            ss_n_o     => spi_ss_n,
            ss_n_i     => '0'
        );

    -- -----------------------------------------------------------------------
    -- DUT: Slave
    -- -----------------------------------------------------------------------
    u_slave : spi_phy
        generic map(g_master => false, g_clk_div => 5)
        port map(
            clk        => clk,
            rstn       => rstn,
            tx_byte_i  => s_tx_byte,
            tx_valid_i => s_tx_valid,
            tx_req_o   => s_tx_req,
            rx_byte_o  => s_rx_byte,
            rx_valid_o => s_rx_valid,
            sclk_o     => open,
            sclk_i     => spi_sclk,
            mosi_o     => open,
            mosi_i     => spi_mosi,
            miso_o     => spi_miso,
            miso_i     => '0',
            ss_n_o     => open,
            ss_n_i     => spi_ss_n
        );

    -- -----------------------------------------------------------------------
    -- Master TX driver process
    -- Responds to m_tx_req one clock after the strobe (registered response).
    -- Resets frame counter on phase transitions.
    -- -----------------------------------------------------------------------
    p_master_drv : process(clk)
        variable m_frame_cnt  : integer := 0;
        variable m_prev_phase : integer := 0;
    begin
        if rising_edge(clk) then
            m_tx_valid <= '0';
            m_tx_byte  <= (others => '0');

            if rstn = '1' then
                -- Reset frame counter on phase transition
                if test_phase /= m_prev_phase then
                    m_frame_cnt  := 0;
                    m_prev_phase := test_phase;
                end if;

                if m_tx_req = '1' then
                    case test_phase is
                        when 1 =>   -- master sends 0x00..0x0F
                            if m_frame_cnt < 16 then
                                m_tx_valid <= '1';
                                m_tx_byte  <= std_logic_vector(to_unsigned(m_frame_cnt, 8));
                                m_frame_cnt := m_frame_cnt + 1;
                            end if;

                        when 2 =>   -- master silent
                            null;

                        when 3 =>   -- full duplex: master sends 0x10..0x2F
                            if m_frame_cnt < 32 then
                                m_tx_valid <= '1';
                                m_tx_byte  <= std_logic_vector(to_unsigned(16#10# + m_frame_cnt, 8));
                                m_frame_cnt := m_frame_cnt + 1;
                            end if;

                        when 4 =>   -- both idle
                            null;

                        when 5 =>   -- long sequence: master sends 0x00..0xFF
                            if m_frame_cnt < 256 then
                                m_tx_valid <= '1';
                                m_tx_byte  <= std_logic_vector(to_unsigned(m_frame_cnt, 8));
                                m_frame_cnt := m_frame_cnt + 1;
                            end if;

                        when others =>
                            null;
                    end case;
                end if;
            end if;
        end if;
    end process p_master_drv;

    -- -----------------------------------------------------------------------
    -- Slave TX driver process
    -- Resets frame counter on phase transitions.
    -- -----------------------------------------------------------------------
    p_slave_drv : process(clk)
        variable s_frame_cnt  : integer := 0;
        variable s_prev_phase : integer := 0;
    begin
        if rising_edge(clk) then
            s_tx_valid <= '0';
            s_tx_byte  <= (others => '0');

            if rstn = '1' then
                -- Reset frame counter on phase transition
                if test_phase /= s_prev_phase then
                    s_frame_cnt  := 0;
                    s_prev_phase := test_phase;
                end if;

                if s_tx_req = '1' then
                    case test_phase is
                        when 1 =>   -- slave silent
                            null;

                        when 2 =>   -- slave sends 0xA0..0xAF
                            if s_frame_cnt < 16 then
                                s_tx_valid <= '1';
                                s_tx_byte  <= std_logic_vector(to_unsigned(16#A0# + s_frame_cnt, 8));
                                s_frame_cnt := s_frame_cnt + 1;
                            end if;

                        when 3 =>   -- full duplex: slave sends 0x50..0x6F
                            if s_frame_cnt < 32 then
                                s_tx_valid <= '1';
                                s_tx_byte  <= std_logic_vector(to_unsigned(16#50# + s_frame_cnt, 8));
                                s_frame_cnt := s_frame_cnt + 1;
                            end if;

                        when 4 =>   -- both idle
                            null;

                        when 5 =>   -- long sequence: slave sends 0x00..0xFF
                            if s_frame_cnt < 256 then
                                s_tx_valid <= '1';
                                s_tx_byte  <= std_logic_vector(to_unsigned(s_frame_cnt, 8));
                                s_frame_cnt := s_frame_cnt + 1;
                            end if;

                        when others =>
                            null;
                    end case;
                end if;
            end if;
        end if;
    end process p_slave_drv;

    -- -----------------------------------------------------------------------
    -- Master RX monitor + test sequencer
    -- -----------------------------------------------------------------------
    p_sequencer : process

        -- Wait N clock edges without caring about rx
        procedure idle_clocks(n : integer) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        -- Collect up to nm master-rx and ns slave-rx bytes simultaneously;
        -- verify sequences; timeout if either side doesn't produce enough.
        procedure expect_both_rx(
                nm : integer; m_start : integer;
                ns : integer; s_start : integer;
                tname : string) is
            variable m_cnt, s_cnt, timeout : integer;
            variable m_exp, s_exp          : integer;
        begin
            m_cnt := 0; s_cnt := 0; timeout := 0;
            m_exp := m_start; s_exp := s_start;
            while (m_cnt < nm) or (s_cnt < ns) loop
                wait until rising_edge(clk);
                timeout := timeout + 1;
                if timeout > 500000 then
                    if m_cnt < nm then
                        report tname & ": TIMEOUT master rx (got " & integer'image(m_cnt) &
                               "/" & integer'image(nm) & ")" severity error;
                        fail_count <= fail_count + 1;
                    end if;
                    if s_cnt < ns then
                        report tname & ": TIMEOUT slave rx (got " & integer'image(s_cnt) &
                               "/" & integer'image(ns) & ")" severity error;
                        fail_count <= fail_count + 1;
                    end if;
                    return;
                end if;
                if m_rx_valid = '1' and m_cnt < nm then
                    if to_integer(unsigned(m_rx_byte)) /= m_exp mod 256 then
                        report tname & ": master rx FAIL byte " & integer'image(m_cnt) &
                               " exp=" & integer'image(m_exp mod 256) &
                               " got=" & integer'image(to_integer(unsigned(m_rx_byte))) severity error;
                        fail_count <= fail_count + 1;
                    end if;
                    m_exp := m_exp + 1; m_cnt := m_cnt + 1;
                end if;
                if s_rx_valid = '1' and s_cnt < ns then
                    if to_integer(unsigned(s_rx_byte)) /= s_exp mod 256 then
                        report tname & ": slave rx FAIL byte " & integer'image(s_cnt) &
                               " exp=" & integer'image(s_exp mod 256) &
                               " got=" & integer'image(to_integer(unsigned(s_rx_byte))) severity error;
                        fail_count <= fail_count + 1;
                    end if;
                    s_exp := s_exp + 1; s_cnt := s_cnt + 1;
                end if;
            end loop;
        end procedure;

        -- Collect only master rx (slave is silent)
        procedure expect_master_rx(n : integer; start_val : integer; tname : string) is
        begin
            expect_both_rx(n, start_val, 0, 0, tname);
        end procedure;

        -- Collect only slave rx (master is silent)
        procedure expect_slave_rx(n : integer; start_val : integer; tname : string) is
        begin
            expect_both_rx(0, 0, n, start_val, tname);
        end procedure;

    begin
        test_phase <= 0;
        wait until rstn = '1';
        wait until rising_edge(clk);

        -- ==================================================================
        -- TEST 1: Master sends 0x00..0x0F; slave is silent.
        -- Verify slave receives 16 bytes.
        -- ==================================================================
        report "Test 1 START: master TX 0x00..0x0F, slave silent" severity note;
        test_phase <= 1;
        expect_slave_rx(16, 0, "Test 1");
        idle_clocks(200);
        report "Test 1: slave RX PASS" severity note;

        -- ==================================================================
        -- TEST 2: Slave sends 0xA0..0xAF; master is silent.
        -- Verify master receives 16 bytes.
        -- ==================================================================
        report "Test 2 START: slave TX 0xA0..0xAF, master silent" severity note;
        test_phase <= 2;
        expect_master_rx(16, 16#A0#, "Test 2");
        idle_clocks(200);
        report "Test 2: master RX PASS" severity note;

        -- ==================================================================
        -- TEST 3: Full duplex — master sends 0x10..0x2F, slave sends 0x50..0x6F.
        -- Both sides collected simultaneously.
        -- ==================================================================
        report "Test 3 START: full-duplex" severity note;
        test_phase <= 3;
        expect_both_rx(32, 16#50#, 32, 16#10#, "Test 3");
        idle_clocks(200);
        report "Test 3: full-duplex PASS" severity note;

        -- ==================================================================
        -- TEST 4: Both idle — no rx_valid_o on either side.
        -- ==================================================================
        report "Test 4 START: both idle, verifying no rx_valid" severity note;
        test_phase <= 4;
        for i in 1 to 3000 loop
            wait until rising_edge(clk);
            if m_rx_valid = '1' then
                report "Test 4: FAIL spurious master rx_valid" severity error;
                fail_count <= fail_count + 1;
            end if;
            if s_rx_valid = '1' then
                report "Test 4: FAIL spurious slave rx_valid" severity error;
                fail_count <= fail_count + 1;
            end if;
        end loop;
        report "Test 4: idle PASS (no spurious rx_valid)" severity note;

        -- ==================================================================
        -- TEST 5: Long sequence — master 0x00..0xFF, slave 0x00..0xFF.
        -- Both sides collected simultaneously.
        -- ==================================================================
        report "Test 5 START: long sequence 256 bytes each" severity note;
        test_phase <= 5;
        expect_both_rx(256, 0, 256, 0, "Test 5");
        idle_clocks(200);
        report "Test 5: long sequence PASS" severity note;

        -- ==================================================================
        -- Done
        -- ==================================================================
        test_done <= '1';
        wait;
    end process p_sequencer;

    -- -----------------------------------------------------------------------
    -- Termination process
    -- -----------------------------------------------------------------------
    p_done : process
    begin
        wait until test_done = '1';
        wait for CLK_PERIOD * 10;

        if fail_count = 0 then
            report "All tests passed" severity note;
        else
            report "SIMULATION DONE with " & integer'image(fail_count) & " failures" severity error;
        end if;

        assert false report "SIMULATION DONE" severity failure;
    end process p_done;

end architecture behav;
