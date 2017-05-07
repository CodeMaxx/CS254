----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:26:12 03/15/2017 
-- Design Name: 
-- Module Name:    top_level - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_level is
    Port(
	 -- FX2LP interface ---------------------------------------------------------------------------
		fx2Clk_in      : in    std_logic;                    -- 48MHz clock from FX2LP
		fx2Addr_out    : out   std_logic_vector(1 downto 0); -- select FIFO: "00" for EP2OUT, "10" for EP6IN
		fx2Data_io     : inout std_logic_vector(7 downto 0); -- 8-bit data to/from FX2LP

		-- When EP2OUT selected:
		fx2Read_out    : out   std_logic;                    -- asserted (active-low) when reading from FX2LP
		fx2OE_out      : out   std_logic;                    -- asserted (active-low) to tell FX2LP to drive bus
		fx2GotData_in  : in    std_logic;                    -- asserted (active-high) when FX2LP has data for us

		-- When EP6IN selected:
		fx2Write_out   : out   std_logic;                    -- asserted (active-low) when writing to FX2LP
		fx2GotRoom_in  : in    std_logic;                    -- asserted (active-high) when FX2LP has room for more data from us
		fx2PktEnd_out  : out   std_logic;                    -- asserted (active-low) when a host read needs to be committed early

		-- Onboard peripherals -----------------------------------------------------------------------
		sseg_out       : out   std_logic_vector(7 downto 0); -- seven-segment display cathodes (one for each segment)
		anode_out      : out   std_logic_vector(3 downto 0); -- seven-segment display anodes (one for each digit)
		led_out        : out   std_logic_vector(7 downto 0); -- eight LEDs
		sw_in          : in    std_logic_vector(7 downto 0);  -- eight switches
		
		  --clk : in  STD_LOGIC;
        reset : in  STD_LOGIC;
--        data_in_sliders : in  STD_LOGIC_VECTOR (7 downto 0);
        next_data_in : in  STD_LOGIC;
        done: in STD_LOGIC;
        start: in STD_LOGIC);
--        data_out_leds : out  STD_LOGIC_VECTOR (7 downto 0));
end top_level;

architecture Behavioral of top_level is
	 component ATM_main_controller
		port(clk : in  STD_LOGIC;
        reset_button : in  STD_LOGIC;
        data_in_sliders : in  STD_LOGIC_VECTOR (7 downto 0);
        next_data_in_button : in  STD_LOGIC;
        done_button: in STD_LOGIC;
        start_button: in STD_LOGIC;
        data_out_leds : out  STD_LOGIC_VECTOR (7 downto 0);
		  data_to_be_encrypted: out STD_LOGIC_VECTOR (63 downto 0);
		  data_to_be_decrypted: out STD_LOGIC_VECTOR (63 downto 0);
		  encrypted_data: in STD_LOGIC_VECTOR (63 downto 0);
		  decrypted_data: in STD_LOGIC_VECTOR (63 downto 0);
		  encrypted_data_comm: out STD_LOGIC_VECTOR (63 downto 0);
		  decrypted_data_comm: in STD_LOGIC_VECTOR (63 downto 0);
		  start_encrypt : out STD_LOGIC;
		  start_decrypt : out STD_LOGIC;
		  done_encrypt : in STD_LOGIC;
		  done_decrypt : in STD_LOGIC;
		  start_comm : out STD_LOGIC;
		  done_comm : in STD_LOGIC;
		  is_user: in STD_LOGIC;
		  is_suf_bal: in STD_LOGIC;
		  is_suf_atm: out STD_LOGIC);
	 end component;
	
    component debouncer
        port(clk: in STD_LOGIC;
            button: in STD_LOGIC;
            button_deb: out STD_LOGIC);
    end component;
	
    component encrypter
        port(clk: in STD_LOGIC;
            reset : in  STD_LOGIC;
            plaintext: in STD_LOGIC_VECTOR (63 downto 0);
            start: in STD_LOGIC;
            ciphertext: out STD_LOGIC_VECTOR (63 downto 0);
            done: out STD_LOGIC);
    end component;

    component decrypter
        port(clk: in STD_LOGIC;
            reset : in  STD_LOGIC;
            ciphertext: in STD_LOGIC_VECTOR (63 downto 0);
            start: in STD_LOGIC;
            plaintext: out STD_LOGIC_VECTOR (63 downto 0);
            done: out STD_LOGIC);
    end component;
	 component communication 
		PORT( clk : in  STD_LOGIC;
				reset : in STD_LOGIC;
				is_user: out STD_LOGIC;
			  is_suf_bal: out STD_LOGIC;
			  is_suf_atm: in STD_LOGIC;
			  start_comm : in STD_LOGIC;
			  done_comm : out STD_LOGIC;
			  data_send: in STD_LOGIC_VECTOR (63 downto 0);
			  data_recieved: out STD_LOGIC_VECTOR (63 downto 0);
			  chanAddr_in  : in std_logic_vector(6 downto 0);
				-- Host >> FPGA pipe:
				h2fData_in   : in std_logic_vector(7 downto 0);  
				h2fValid_in  : in std_logic;                     
				h2fReady_out  : out std_logic;                     
				-- Host << FPGA pipe:
				f2hData_out   : out std_logic_vector(7 downto 0);  
				f2hValid_out  : out std_logic;                     
				f2hReady_in  : in std_logic                   
				);
	end component;
	
	component comm_fpga_fx2 
	port(
		clk_in         : in    std_logic;                     -- 48MHz clock from FX2LP
		reset_in       : in    std_logic;                     -- synchronous active-high reset input
		reset_out      : out   std_logic;                     -- synchronous active-high reset output

		-- FX2LP interface ---------------------------------------------------------------------------
		fx2FifoSel_out : out   std_logic;                     -- select FIFO: '0' for EP2OUT, '1' for EP6IN
		fx2Data_io     : inout std_logic_vector(7 downto 0);  -- 8-bit data to/from FX2LP

		-- When EP2OUT selected:
		fx2Read_out    : out   std_logic;                     -- asserted (active-low) when reading from FX2LP
		fx2GotData_in  : in    std_logic;                     -- asserted (active-high) when FX2LP has data for us

		-- When EP6IN selected:
		fx2Write_out   : out   std_logic;                     -- asserted (active-low) when writing to FX2LP
		fx2GotRoom_in  : in    std_logic;                     -- asserted (active-high) when FX2LP has room for more data from us
		fx2PktEnd_out  : out   std_logic;                     -- asserted (active-low) when a host read needs to be committed early

		-- Channel read/write interface --------------------------------------------------------------
		chanAddr_out   : out   std_logic_vector(6 downto 0);  -- the selected channel (0-127)

		-- Host >> FPGA pipe:
		h2fData_out    : out   std_logic_vector(7 downto 0);  -- data lines used when the host writes to a channel
		h2fValid_out   : out   std_logic;                     -- '1' means "on the next clock rising edge, please accept the data on h2fData_out"
		h2fReady_in    : in    std_logic;                     -- channel logic can drive this low to say "I'm not ready for more data yet"

		-- Host << FPGA pipe:
		f2hData_in     : in    std_logic_vector(7 downto 0);  -- data lines used when the host reads from a channel
		f2hValid_in    : in    std_logic;                     -- channel logic can drive this low to say "I don't have data ready for you"
		f2hReady_out   : out   std_logic                      -- '1' means "on the next clock rising edge, put your next byte of data on f2hData_in"
		);
		end component;
		
		
		-- Channel read/write interface -----------------------------------------------------------------
	signal chanAddr  : std_logic_vector(6 downto 0);  -- the selected channel (0-127)

	-- Host >> FPGA pipe:
	signal h2fData   : std_logic_vector(7 downto 0);  -- data lines used when the host writes to a channel
	signal h2fValid  : std_logic;                     -- '1' means "on the next clock rising edge, please accept the data on h2fData"
	signal h2fReady  : std_logic;                     -- channel logic can drive this low to say "I'm not ready for more data yet"

	-- Host << FPGA pipe:
	signal f2hData   : std_logic_vector(7 downto 0);  -- data lines used when the host reads from a channel
	signal f2hValid  : std_logic;                     -- channel logic can drive this low to say "I don't have data ready for you"
	signal f2hReady  : std_logic;                     -- '1' means "on the next clock rising edge, put your next byte of data on f2hData"
	-- ----------------------------------------------------------------------------------------------

	-- Needed so that the comm_fpga_fx2 module can drive both fx2Read_out and fx2OE_out
	signal fx2Read   : std_logic;

	-- Reset signal so host can delay startup
	signal fx2Reset  : std_logic;


signal debounced_next_data_in_button: STD_LOGIC;
signal debounced_done_button: STD_LOGIC := '0';
signal debounced_reset_button: STD_LOGIC := '0';
signal debounced_start_button: STD_LOGIC;
signal data_to_be_encrypted: STD_LOGIC_VECTOR (63 downto 0);
signal data_to_be_decrypted: STD_LOGIC_VECTOR (63 downto 0);
signal encrypted_data: STD_LOGIC_VECTOR (63 downto 0);
signal decrypted_data: STD_LOGIC_VECTOR (63 downto 0);
signal done_decrypt: STD_LOGIC;
signal done_encrypt: STD_LOGIC;
signal start_decrypt: STD_LOGIC;
signal start_encrypt: STD_LOGIC;
signal start_comm : STD_LOGIC;
signal done_comm : STD_LOGIC;
signal is_user: STD_LOGIC;
signal is_suf_bal: STD_LOGIC;
signal is_suf_atm: STD_LOGIC;
signal encrypted_data_comm: STD_LOGIC_VECTOR (63 downto 0);
signal decrypted_data_comm: STD_LOGIC_VECTOR (63 downto 0);
signal done_or_reset : STD_LOGIC;

begin
	done_or_reset <= debounced_done_button or debounced_reset_button;
	-- CommFPGA module
	fx2Read_out <= fx2Read;
	fx2OE_out <= fx2Read;
	fx2Addr_out(0) <=  -- So fx2Addr_out(1)='0' selects EP2OUT, fx2Addr_out(1)='1' selects EP6IN
		'0' when fx2Reset = '0'
		else 'Z';
		
	comm_fpga : comm_fpga_fx2
		port map(
			clk_in         => fx2Clk_in,
			reset_in       => '0',
			reset_out      => fx2Reset,
			
			-- FX2LP interface
			fx2FifoSel_out => fx2Addr_out(1),
			fx2Data_io     => fx2Data_io,
			fx2Read_out    => fx2Read,
			fx2GotData_in  => fx2GotData_in,
			fx2Write_out   => fx2Write_out,
			fx2GotRoom_in  => fx2GotRoom_in,
			fx2PktEnd_out  => fx2PktEnd_out,

			-- DVR interface -> Connects to application module
			chanAddr_out   => chanAddr,
			h2fData_out    => h2fData,
			h2fValid_out   => h2fValid,
			h2fReady_in    => h2fReady,
			f2hData_in     => f2hData,
			f2hValid_in    => f2hValid,
			f2hReady_out   => f2hReady
		);

debouncer1: debouncer
              port map (clk => fx2Clk_in,
                        button => next_data_in,
                        button_deb => debounced_next_data_in_button);

debouncer2: debouncer
              port map (clk => fx2Clk_in,
                        button => done,
                        button_deb => debounced_done_button);

debouncer3: debouncer
              port map (clk => fx2Clk_in,
                        button => reset,
                        button_deb => debounced_reset_button);

debouncer4: debouncer
              port map (clk => fx2Clk_in,
                        button => start,
                        button_deb => debounced_start_button);

encrypt: encrypter
              port map (clk => fx2Clk_in,
                        reset => done_or_reset,
                        plaintext => data_to_be_encrypted,
                        start => start_encrypt,
                        ciphertext => encrypted_data,
                        done => done_encrypt);

decrypt: decrypter
              port map (clk => fx2Clk_in,
                        reset => done_or_reset,
                        ciphertext => data_to_be_decrypted,
								start => start_decrypt,
                        plaintext => decrypted_data,
                        done => done_decrypt);

ATM_Main_cont : ATM_main_controller
				port map( 
							clk => fx2Clk_in,
							reset_button => debounced_reset_button,
						   data_in_sliders => sw_in,
						   next_data_in_button => debounced_next_data_in_button,
						   done_button => debounced_done_button,
						   start_button => debounced_start_button,
						   data_out_leds => led_out,
							data_to_be_encrypted => data_to_be_encrypted,
							encrypted_data => encrypted_data,
							data_to_be_decrypted => data_to_be_decrypted,
							decrypted_data => decrypted_data,
							start_encrypt => start_encrypt,
							start_decrypt => start_decrypt,
							done_encrypt => done_encrypt,
							done_decrypt => done_decrypt,
							encrypted_data_comm => encrypted_data_comm,
						   decrypted_data_comm => decrypted_data_comm,
						   start_comm => start_comm,
						   done_comm => done_comm,
						   is_user => is_user,
						   is_suf_bal => is_suf_bal,
						   is_suf_atm => is_suf_atm
							);

comm : communication
		port map(	clk => fx2Clk_in,
							-- DVR interface -> Connects to comm_fpga module
							chanAddr_in  => chanAddr,
							h2fData_in   => h2fData,
							h2fValid_in  => h2fValid,
							h2fReady_out => h2fReady,
							f2hData_out  => f2hData,
							f2hValid_out => f2hValid,
							f2hReady_in  => f2hReady,
							reset => done_or_reset,
							start_comm => start_comm,
						   done_comm => done_comm,
						   is_user => is_user,
						   is_suf_bal => is_suf_bal,
						   is_suf_atm => is_suf_atm,
							data_send => encrypted_data_comm,
						   data_recieved => decrypted_data_comm
					);
end Behavioral;