--
-- SPI PHY core (Mode 0: CPOL=0, CPHA=0)
-- Frame = 9 bits: bit[8]=valid flag, bits[7:0]=data, MSB first.
--
-- Master: drives sclk_o, mosi_o, ss_n_o; samples miso_i.
-- Slave:  drives miso_o; samples sclk_i, mosi_i, ss_n_i via 2-FF synchronizers.
--
-- SCLK generation:
--   low_half  = g_clk_div / 2   (floor)
--   high_half = (g_clk_div+1)/2 (ceiling)
--   Example: g_clk_div=5 => low=2, high=3 => 5 sys_clk/period => SCLK=10 MHz @ 50 MHz.
--
-- Master frame sequence:
--   M_REQ: assert tx_req_o for 1 clock.
--   M_WAIT: one idle clock (user's registered logic sees tx_req_o and puts data on tx_byte_i/tx_valid_i).
--   M_LATCH: sample tx_byte_i/tx_valid_i; pull SS_n low; pre-drive MOSI.
--   M_SETUP: wait C_SETUP clocks with SS_n low so slave 2-FF sync + edge detect + latch can complete.
--   M_FRAME: clock 9 SCLK bits.
--   M_DONE: raise SS_n; decode received frame; go back to M_REQ.
--
-- Slave latch sequence (relative to SS_n falling on spi bus):
--   +0 clk: SS_n falls on wire (after M_LATCH in master).
--   +1,+2: 2-FF sync.
--   +3: edge_proc registers sl_ssn_fall='1'.
--   +4: slave_proc sees sl_ssn_fall='1', issues sl_tx_req (tx_req_o='1').
--   +5: slave driver sees tx_req_o='1', responds with tx_byte_i/tx_valid_i (registered output).
--       Also sl_tx_req_d1 becomes '1' (capturing sl_tx_req from +4).
--   +6: slave_proc sees sl_tx_req_d1='1', latches tx_byte_i/tx_valid_i (stable from +5), drives MISO.
--   Master's first SCLK rising edge: C_SETUP must be >= 6 (we use 8).
--
-- Created:
--          by - irz design team
--          at - 05.2026
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_phy is
    generic(
        g_master  : boolean := true;
        g_clk_div : integer := 5
    );
    port(
        clk    : in  std_logic;
        rstn   : in  std_logic;

        -- byte interface (1-clk strobes)
        tx_byte_i  : in  std_logic_vector(7 downto 0);
        tx_valid_i : in  std_logic;
        tx_req_o   : out std_logic;
        rx_byte_o  : out std_logic_vector(7 downto 0);
        rx_valid_o : out std_logic;

        -- SPI pins (unused outputs hold '0')
        sclk_o : out std_logic;
        sclk_i : in  std_logic;
        mosi_o : out std_logic;
        mosi_i : in  std_logic;
        miso_o : out std_logic;
        miso_i : in  std_logic;
        ss_n_o : out std_logic;
        ss_n_i : in  std_logic
    );
end entity spi_phy;

architecture rtl of spi_phy is

    constant C_LOW_HALF   : integer := g_clk_div / 2;
    constant C_HIGH_HALF  : integer := (g_clk_div + 1) / 2;
    constant C_FRAME_BITS : integer := 9;
    -- Minimum: sync(2) + edge_detect(1) + slave_proc_sees_ssn_fall(1) + tx_req(1) + slave_latch_d1(1) = 6
    constant C_SETUP      : integer := 8;

begin

    -- =========================================================================
    -- MASTER
    -- =========================================================================
    gen_master : if g_master generate

        type master_state_t is (M_REQ, M_WAIT, M_LATCH, M_SETUP, M_FRAME, M_DONE);

        signal m_state     : master_state_t;
        signal m_clk_cnt   : integer range 0 to 255;
        signal m_bit_cnt   : integer range 0 to C_FRAME_BITS;
        signal m_sclk      : std_logic;
        signal m_ss_n      : std_logic;
        signal m_mosi      : std_logic;
        signal m_shift_tx  : std_logic_vector(8 downto 0);
        signal m_shift_rx  : std_logic_vector(8 downto 0);
        signal m_tx_req    : std_logic;
        signal m_rx_valid  : std_logic;
        signal m_rx_byte   : std_logic_vector(7 downto 0);

    begin

        master_proc : process(clk)
        begin
            if rising_edge(clk) then
                m_tx_req   <= '0';
                m_rx_valid <= '0';

                if rstn = '0' then
                    m_state    <= M_REQ;
                    m_clk_cnt  <= 0;
                    m_bit_cnt  <= 0;
                    m_sclk     <= '0';
                    m_ss_n     <= '1';
                    m_mosi     <= '0';
                    m_shift_tx <= (others => '0');
                    m_shift_rx <= (others => '0');
                    m_rx_byte  <= (others => '0');
                else
                    case m_state is

                        -- Assert tx_req for 1 clk; user's registered logic will
                        -- see it and present data on tx_byte_i/tx_valid_i 1 cycle later.
                        when M_REQ =>
                            m_sclk    <= '0';
                            m_ss_n    <= '1';
                            m_bit_cnt <= 0;
                            m_clk_cnt <= 0;
                            m_tx_req  <= '1';
                            m_state   <= M_WAIT;

                        -- Wait one cycle: user's registered response is now stable on
                        -- tx_byte_i/tx_valid_i.
                        when M_WAIT =>
                            m_state <= M_LATCH;

                        -- Sample tx_byte_i/tx_valid_i; pull SS_n low; pre-drive MOSI.
                        when M_LATCH =>
                            m_shift_tx <= tx_valid_i & tx_byte_i;
                            m_shift_rx <= (others => '0');
                            m_mosi     <= tx_valid_i;   -- MSB of 9-bit frame
                            m_ss_n     <= '0';
                            m_clk_cnt  <= 0;
                            m_state    <= M_SETUP;

                        -- Hold SS_n low for C_SETUP clocks so slave can sync and
                        -- pre-load MISO before the first SCLK rising edge.
                        when M_SETUP =>
                            if m_clk_cnt = C_SETUP - 1 then
                                m_clk_cnt <= 0;
                                m_state   <= M_FRAME;
                            else
                                m_clk_cnt <= m_clk_cnt + 1;
                            end if;

                        -- Clock 9 SCLK bits: sample MISO on rising edge,
                        -- update MOSI on falling edge.
                        when M_FRAME =>
                            if m_bit_cnt < C_FRAME_BITS then
                                if m_sclk = '0' then
                                    -- SCLK low phase
                                    if m_clk_cnt = C_LOW_HALF - 1 then
                                        -- Rising edge: sample MISO
                                        m_sclk     <= '1';
                                        m_clk_cnt  <= 0;
                                        m_shift_rx <= m_shift_rx(7 downto 0) & miso_i;
                                    else
                                        m_clk_cnt <= m_clk_cnt + 1;
                                    end if;
                                else
                                    -- SCLK high phase
                                    if m_clk_cnt = C_HIGH_HALF - 1 then
                                        -- Falling edge: shift MOSI to next bit
                                        m_sclk     <= '0';
                                        m_shift_tx <= m_shift_tx(7 downto 0) & '0';
                                        m_mosi     <= m_shift_tx(7);
                                        m_clk_cnt  <= 0;
                                        m_bit_cnt  <= m_bit_cnt + 1;
                                    else
                                        m_clk_cnt <= m_clk_cnt + 1;
                                    end if;
                                end if;
                            else
                                -- All 9 bits transferred; raise SS_n
                                m_ss_n  <= '1';
                                m_mosi  <= '0';
                                m_state <= M_DONE;
                            end if;

                        -- Decode received frame, then restart
                        when M_DONE =>
                            if m_shift_rx(8) = '1' then
                                m_rx_valid <= '1';
                                m_rx_byte  <= m_shift_rx(7 downto 0);
                            end if;
                            m_state <= M_REQ;

                        when others =>
                            m_state <= M_REQ;

                    end case;
                end if;
            end if;
        end process master_proc;

        sclk_o     <= m_sclk;
        ss_n_o     <= m_ss_n;
        mosi_o     <= m_mosi;
        miso_o     <= '0';
        tx_req_o   <= m_tx_req;
        rx_valid_o <= m_rx_valid;
        rx_byte_o  <= m_rx_byte;

    end generate gen_master;

    -- =========================================================================
    -- SLAVE
    -- =========================================================================
    gen_slave : if not g_master generate

        -- 2-FF synchronizers
        signal sl_sclk_s1, sl_sclk_s2 : std_logic;
        signal sl_mosi_s1, sl_mosi_s2 : std_logic;
        signal sl_ssn_s1,  sl_ssn_s2  : std_logic;

        -- Edge-detect registers (registered 1 cycle after sync output)
        signal sl_sclk_prev : std_logic;
        signal sl_ssn_prev  : std_logic;
        signal sl_sclk_rise : std_logic;
        signal sl_ssn_fall  : std_logic;
        signal sl_ssn_rise  : std_logic;

        -- TX request pipeline:
        -- sl_tx_req fires at edge T (visible as tx_req_o = '1' from T onwards).
        -- Driver reads tx_req_o at T+1 (clocked), sets tx_byte_i/tx_valid_i (stable from T+1 delta).
        -- sl_tx_req_d1 is '1' at T+1 (captures old sl_tx_req='1' from T).
        -- Slave latches tx_valid_i at T+2 when it reads sl_tx_req_d1='1': tx_valid_i is
        -- the value set AFTER T+1 delta by the driver, which the slave reads at T+2's edge. Correct.
        signal sl_tx_req    : std_logic;
        signal sl_tx_req_d1 : std_logic;

        -- Data path
        signal sl_shift_rx  : std_logic_vector(8 downto 0);
        signal sl_shift_tx  : std_logic_vector(8 downto 0);
        signal sl_bit_cnt   : integer range 0 to C_FRAME_BITS;
        signal sl_active    : std_logic;
        signal sl_miso      : std_logic;
        signal sl_rx_valid  : std_logic;
        signal sl_rx_byte   : std_logic_vector(7 downto 0);

    begin

        -- 2-FF synchronizers
        sync_proc : process(clk)
        begin
            if rising_edge(clk) then
                if rstn = '0' then
                    sl_sclk_s1 <= '0'; sl_sclk_s2 <= '0';
                    sl_mosi_s1 <= '0'; sl_mosi_s2 <= '0';
                    sl_ssn_s1  <= '1'; sl_ssn_s2  <= '1';
                else
                    sl_sclk_s1 <= sclk_i; sl_sclk_s2 <= sl_sclk_s1;
                    sl_mosi_s1 <= mosi_i; sl_mosi_s2 <= sl_mosi_s1;
                    sl_ssn_s1  <= ss_n_i; sl_ssn_s2  <= sl_ssn_s1;
                end if;
            end if;
        end process sync_proc;

        -- Edge detection (each edge signal is registered, so it's valid 1 cycle
        -- after the sync FF output transitions).
        edge_proc : process(clk)
        begin
            if rising_edge(clk) then
                if rstn = '0' then
                    sl_sclk_prev <= '0';
                    sl_ssn_prev  <= '1';
                    sl_sclk_rise <= '0';
                    sl_ssn_fall  <= '0';
                    sl_ssn_rise  <= '0';
                else
                    sl_sclk_prev <= sl_sclk_s2;
                    sl_ssn_prev  <= sl_ssn_s2;
                    sl_sclk_rise <= sl_sclk_s2 and not sl_sclk_prev;
                    sl_ssn_fall  <= not sl_ssn_s2 and sl_ssn_prev;
                    sl_ssn_rise  <= sl_ssn_s2 and not sl_ssn_prev;
                end if;
            end if;
        end process edge_proc;

        -- Slave main data path
        slave_proc : process(clk)
        begin
            if rising_edge(clk) then
                -- Default: clear single-cycle pulses
                sl_tx_req    <= '0';
                sl_tx_req_d1 <= sl_tx_req;
                sl_rx_valid  <= '0';

                if rstn = '0' then
                    sl_bit_cnt   <= 0;
                    sl_shift_rx  <= (others => '0');
                    sl_shift_tx  <= (others => '0');
                    sl_active    <= '0';
                    sl_miso      <= '0';
                    sl_rx_byte   <= (others => '0');
                    sl_tx_req_d1 <= '0';
                else

                    -- SS_n falling: start of frame
                    if sl_ssn_fall = '1' then
                        sl_bit_cnt  <= 0;
                        sl_shift_rx <= (others => '0');
                        sl_active   <= '1';
                        sl_tx_req   <= '1';
                        -- MISO will be loaded when sl_tx_req_d1 fires (1 cycle later).
                        sl_miso     <= '0';
                    end if;

                    -- 1 clock after tx_req: driver's registered response is now stable on
                    -- tx_byte_i/tx_valid_i (the driver process reads tx_req_o='1' and
                    -- sets its outputs, which are visible at the NEXT clock edge = now).
                    if sl_tx_req_d1 = '1' then
                        sl_shift_tx <= tx_valid_i & tx_byte_i;
                        sl_miso     <= tx_valid_i;   -- MSB = valid flag (bit 8)
                    end if;

                    -- Rising SCLK: sample MOSI; advance MISO to next bit.
                    if sl_sclk_rise = '1' and sl_active = '1' then
                        sl_shift_rx <= sl_shift_rx(7 downto 0) & sl_mosi_s2;
                        -- After master samples current MISO bit, present next bit.
                        -- sl_shift_tx(8 - sl_bit_cnt) is the bit just sampled by master.
                        -- Next bit is sl_shift_tx(7 - sl_bit_cnt).
                        if sl_bit_cnt < C_FRAME_BITS - 1 then
                            sl_miso <= sl_shift_tx(7 - sl_bit_cnt);
                        else
                            sl_miso <= '0';
                        end if;
                        sl_bit_cnt <= sl_bit_cnt + 1;
                    end if;

                    -- SS_n rising: end of frame; decode received data.
                    if sl_ssn_rise = '1' then
                        sl_active <= '0';
                        sl_miso   <= '0';
                        if sl_bit_cnt = C_FRAME_BITS then
                            if sl_shift_rx(8) = '1' then
                                sl_rx_valid <= '1';
                                sl_rx_byte  <= sl_shift_rx(7 downto 0);
                            end if;
                        end if;
                        sl_bit_cnt <= 0;
                    end if;

                end if;
            end if;
        end process slave_proc;

        sclk_o     <= '0';
        mosi_o     <= '0';
        ss_n_o     <= '0';
        miso_o     <= sl_miso;
        tx_req_o   <= sl_tx_req;
        rx_valid_o <= sl_rx_valid;
        rx_byte_o  <= sl_rx_byte;

    end generate gen_slave;

end architecture rtl;
