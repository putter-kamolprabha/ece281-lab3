--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2018 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : top_basys3.vhd
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 02/22/2018
--| DESCRIPTION   : This file implements the top level module for a BASYS 3 to 
--|					drive a Thunderbird taillight controller FSM.
--|
--|					Inputs:  clk 	--> 100 MHz clock from FPGA
--|                          sw(15) --> left turn signal
--|                          sw(0)  --> right turn signal
--|                          btnL   --> clk reset
--|                          btnR   --> FSM reset
--|							 
--|					Outputs:  led(15:13) --> left turn signal lights
--|					          led(2:0)   --> right turn signal lights
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm.vhd, clock_divider.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
	port(

		clk     :   in std_logic; -- native 100MHz FPGA clock
		
		-- Switches (16 total)
		sw  	:   in std_logic_vector(15 downto 0); -- sw(15) = left; sw(0) = right

		-- LEDs (16 total)
		-- taillights (LC, LB, LA, RA, RB, RC)
		led 	:   out std_logic_vector(15 downto 0);  -- led(15:13) --> L
                                                        -- led(2:0)   --> R
		
		-- Buttons (5 total)
		btnC	:	in	std_logic;
		btnU	:	in	std_logic;
		btnL	:	in	std_logic;                    -- clk_reset
		btnR	:	in	std_logic;	                  -- fsm_reset
		btnD	:	in	std_logic	
	);
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components
	component thunderbird_fsm
        port (
            i_clk       : in  std_logic;
            i_reset     : in  std_logic;
            i_left      : in  std_logic;
            i_right     : in  std_logic;
            o_lights_L  : out std_logic_vector(2 downto 0);
            o_lights_R  : out std_logic_vector(2 downto 0)
        );
    end component;
    
    component clock_divider is
        generic (
            k_DIV : natural := 2
        );
        port (
            i_clk   : in  std_logic;
            i_reset : in  std_logic;
            o_clk   : out std_logic
        );
    end component;
    
    --INTERNAL SIGNALS ----
    signal slow_clk    : std_logic;
    signal lights_L    : std_logic_vector(2 downto 0);
    signal lights_R    : std_logic_vector(2 downto 0);

  
begin
    -- CLOCK DIVIDER INSTANCE ----------------------------
    clk_div: clock_divider
        generic map (k_DIV => 25000000)  -- 100 MHz ÷ 25M = ~4 Hz
        port map (
            i_clk   => clk,
            i_reset => btnL,             -- clock reset
            o_clk   => slow_clk
        );
        
    -- FSM INSTANCE ---------------------------------------
    fsm: thunderbird_fsm
        port map (
            i_clk      => slow_clk,
            i_reset    => btnR,
            i_left     => sw(15),
            i_right    => sw(0),
            o_lights_L => lights_L,
            o_lights_R => lights_R
        );   
	-- OUTPUT ASSIGNMENTS -------------------------------
    led(15 downto 13) <= lights_L;  -- LC, LB, LA
    led(2) <= lights_R(0);  -- RC
    led(1) <= lights_R(1);  -- RB
    led(0) <= lights_R(2);  -- RA
	
	-- ground unused LEDs
	-- leave unused switches UNCONNECTED
	led(12 downto 3) <= (others => '0');
	
end top_basys3_arch;
