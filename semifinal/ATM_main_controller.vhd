----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:25:41 03/15/2017 
-- Design Name: 
-- Module Name:    ATM_main_controller - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ATM_main_controller is
	Port(clk : in  STD_LOGIC;
        reset_button : in  STD_LOGIC;
        data_in_sliders : in  STD_LOGIC_VECTOR (7 downto 0);
        next_data_in_button : in  STD_LOGIC;
        done_button: in STD_LOGIC;
        start_button: in STD_LOGIC;
        data_out_leds : out  STD_LOGIC_VECTOR (7 downto 0);
		  data_to_be_encrypted: out STD_LOGIC_VECTOR (63 downto 0);
		  data_to_be_decrypted: out STD_LOGIC_VECTOR (63 downto 0);
		  encrypted_data: in STD_LOGIC_VECTOR (63 downto 0);
		  encrypted_data_comm: out STD_LOGIC_VECTOR (63 downto 0);
		  decrypted_data_comm: in STD_LOGIC_VECTOR (63 downto 0);
		  decrypted_data: in STD_LOGIC_VECTOR (63 downto 0);
		  start_encrypt : out STD_LOGIC;
		  start_decrypt : out STD_LOGIC;
		  done_encrypt : in STD_LOGIC;
		  done_decrypt : in STD_LOGIC;
  		  start_comm : out STD_LOGIC;
		  done_comm : in STD_LOGIC;
		  is_user: in STD_LOGIC;
		  is_suf_bal: in STD_LOGIC;
		  is_suf_atm: out STD_LOGIC );
end ATM_main_controller;

architecture Behavioral of ATM_main_controller is

	component timer
		port (clk: in STD_LOGIC;
				blink: out STD_LOGIC;
				i: out STD_LOGIC
					);
	end component;
	
	component read_multiple_data_bytes
	port (clk : in  STD_LOGIC;
				reset : in STD_LOGIC;
				data_in : in  STD_LOGIC_VECTOR (7 downto 0);
				next_data : in  STD_LOGIC;
				data : out  STD_LOGIC_VECTOR (63 downto 0);
				done : out STD_LOGIC;
				data_received : out STD_LOGIC_VECTOR (2 downto 0));
	end component;
	
	signal timer_inp : STD_LOGIC;
	signal read_input_done: STD_LOGIC := '0';
	signal state: STD_LOGIC_VECTOR(2 downto 0) := "000";
	signal n2000, n500, n100, n1000 : std_logic_vector(7 downto 0) := x"00";
	signal data_collected_so_far : STD_LOGIC_VECTOR(2 downto 0) := "000";
	signal d2000, d1000, d500, d100 : std_logic_vector(7 downto 0) := x"00";
	signal is_suf_cash : STD_LOGIC := '1';
	signal is_blink : STD_LOGIC := '0';
	signal count_blink : std_logic_vector(2 downto 0) := "000";
	signal double_time: STD_LOGIC := '0';
	signal data_to_be_encrypted_signal : STD_LOGIC_VECTOR (63 downto 0);
begin

	timer1: timer
		port map(clk => clk,
					blink => timer_inp,
					i => is_blink);
					
	data_inp: read_multiple_data_bytes
					  port map (clk => clk,
									reset => reset_button,
									data_in => data_in_sliders,
									next_data => next_data_in_button,
									data => data_to_be_encrypted_signal,
									data_received => data_collected_so_far,
									done => read_input_done);
									
	process(state,start_button,reset_button,clk)
	begin
		if(rising_edge(clk)) then
			if(reset_button = '1') then
				state <= "000";				-- ready state
--				data_collected_so_far <= "000";
				n100 <= X"FF";
				n500 <= X"02";
				n1000 <= X"02";
				n2000 <= X"02";
			elsif(state = "000" and start_button = '1') then
				state <= "001";				--get_user_input state
			elsif(state = "001" and read_input_done = '1') then
				state <= "010";				--send data for encryption
				data_to_be_encrypted <= data_to_be_encrypted_signal;
				
				if(n2000 >= data_to_be_encrypted_signal(31 downto 24) and 
					n1000 >= data_to_be_encrypted_signal(23 downto 16) and
					n500 >= data_to_be_encrypted_signal(15 downto 8) and
					n100 >= data_to_be_encrypted_signal(7 downto 0)) then
					is_suf_atm <= '1';
				end if;
				start_encrypt <= '1';
			elsif(state = "010" and done_encrypt = '1') then
				start_encrypt <= '0';
				state <= "011";				--communicating_with_backend
				encrypted_data_comm <= encrypted_data;
				start_comm <= '1';
			elsif(state = "011" and done_comm = '1' ) then
				start_comm <= '0';
				state <= "100";				--backend communication done + decrption start
				data_to_be_decrypted <= decrypted_data_comm;
				start_decrypt <= '1';
			elsif(state = "100" and done_decrypt = '1' and is_user = '1' and is_suf_bal = '1') then
				start_decrypt <= '0';
				d2000 <= decrypted_data(31 downto 24);
				d1000 <= decrypted_data(23 downto 16);
				d500 <= decrypted_data(15 downto 8);
				d100 <= decrypted_data(7 downto 0);
--				n2000 <= decrypted_data(63 downto 56);
--				n1000 <= decrypted_data(55 downto 48);
--				n500 <= decrypted_data(47 downto 40);
--				n100 <= decrypted_data(39 downto 32);
				state <= "101"; 						--user with sufficient balance
			elsif(state = "100" and done_decrypt = '1' and is_user = '1' and is_suf_bal = '0') then
				state <= "110"; 						--user with insufficient balance
			elsif(state = "100" and done_decrypt = '1' and is_user = '0' and is_suf_bal = '1') then
				state <= "111";				--admin
				n2000 <= decrypted_data(31 downto 24);
				n1000 <= decrypted_data(23 downto 16);
				n500 <= decrypted_data(15 downto 8);
				n100 <= decrypted_data(7 downto 0);
			elsif(state = "100" and done_decrypt = '1' and is_user = '0' and is_suf_bal = '0') then
				state <= "000";
			elsif(done_button = '1') then
				state <= "000";
			end if;
		
			if(state = "000") then
				data_out_leds <= "00000000";				--ready state
				count_blink <= "000";
				is_suf_atm <= '0';
				start_decrypt <= '0';
				start_comm <= '0';
				start_encrypt <= '0';		
			elsif(state = "001") then
				data_out_leds <= timer_inp & data_collected_so_far & "0000";	--get_user_input
			elsif(state = "011") then
				data_out_leds <= timer_inp & timer_inp & "000000";		--communicating_with_backend
			elsif(state = "111" and count_blink < "101") then
				data_out_leds <= 	timer_inp & timer_inp & timer_inp & "00000"; -- admin (Loading cash)
				if(is_blink = '1') then
					count_blink <= count_blink + "001";
				end if;
			elsif(state = "111" and count_blink = "101") then
				data_out_leds <= "00000000";
			elsif(state = "110" and count_blink < "011") then		--user with insufficient balance
				if(timer_inp = '1') then
					data_out_leds <= "11111111";
				else
					data_out_leds <= "00000000";
				end if;
				if(is_blink = '1') then
					count_blink <= count_blink + "001";
				end if;
			elsif(state = "110" and count_blink < "101") then
				if(timer_inp = '1') then
					data_out_leds <= "11110000";
				else
					data_out_leds <= "00000000";
				end if;
				if(is_blink = '1') then
					count_blink <= count_blink + "001";
				end if;
			elsif(state = "110" and count_blink = "101") then
				data_out_leds <= "00000000";
			elsif(state = "101") then								--user with sufficient balance
				if(count_blink = "000") then
					data_out_leds <= decrypted_data_comm(63 downto 56);
				elsif(count_blink = "001") then
					data_out_leds <= decrypted_data_comm(55 downto 48);
				elsif(count_blink = "010") then
					data_out_leds <= decrypted_data_comm(47 downto 40);
				elsif(count_blink = "011") then
					data_out_leds <= decrypted_data_comm(39 downto 32);
				elsif(count_blink = "100") then
					data_out_leds <= decrypted_data_comm(31 downto 24);
				elsif(count_blink = "101") then
					data_out_leds <= decrypted_data_comm(23 downto 16);
				elsif(count_blink = "110") then
					data_out_leds <= decrypted_data_comm(15 downto 8);
				elsif(count_blink = "111") then
					data_out_leds <= decrypted_data_comm(7 downto 0);
				end if;
				if(is_blink = '1') then
					count_blink <= count_blink + "001";
				end if;
--				if(n2000 >= d2000 and n1000 >= d1000 and n500 >= d500 and n100 >= d100) then
--					-- also make a state to finally decrease the cash in ATM
--					if(is_blink = '1' and double_time = '0') then
--						double_time <= '1';
--					elsif(is_blink = '1' and double_time = '1') then
--						double_time <= '0';
--					end if;
--					if(double_time = '0') then
--						if(d2000 > 0) then
--							if(timer_inp = '1') then
--								data_out_leds <= "11111000";
--							else
--								data_out_leds <= "00000000";
--							end if;
--							if(is_blink = '1') then
--								d2000 <= d2000 - "00000001";
--								n2000 <= n2000 - "00000001";
--							end if;
--						elsif(d1000 > 0) then
--							if(timer_inp = '1') then
--								data_out_leds <= "11110100";
--							else
--								data_out_leds <= "00000000";
--							end if;
--							if(is_blink = '1') then
--								d1000 <= d1000 - "00000001";
--								n1000 <= n1000 - "00000001";
--							end if;
--						elsif(d500 > 0) then
--							if(timer_inp = '1') then
--								data_out_leds <= "11110010";
--							else
--								data_out_leds <= "00000000";
--							end if;
--							if(is_blink = '1') then
--								d500 <= d500 - "00000001";
--								n500 <= n500 - "00000001";
--							end if;
--						elsif(d100 > 0) then
--							if(timer_inp = '1') then
--								data_out_leds <= "11110001";
--							else
--								data_out_leds <= "00000000";
--							end if;
--							if(is_blink = '1') then
--								d100 <= d100 - "00000001";
--								n100 <= n100 - "00000001";
--							end if;
--						else
--							if(timer_inp = '1') then
--								data_out_leds <= "11110000";
--							else
--								data_out_leds <= "00000000";
--							end if;
--							-- TODO - take care of atleast 5 blinks
--						end if;
--					else
--						if(timer_inp = '1') then
--							data_out_leds <= "11110000";
--						else
--							data_out_leds <= "00000000";
--						end if;
--					end if;
--				else
--					if(count_blink < "110") then
--						if(timer_inp = '1') then
--							data_out_leds <= "11111111";
--						else
--							data_out_leds <= "00000000";
--						end if;
--						if(is_blink = '1') then
--							count_blink <= count_blink + "001";
--						end if;
--					elsif(count_blink = "110") then
--						data_out_leds <= "00000000";
--					end if;
--				end if;
			end if;
		end if;
	end process;
end Behavioral;
--
--n2000 <= n2000 - decrypted_data(63 downto 56);
--				n1000 <= n1000 - decrypted_data(55 downto 48);
--				n500 <= n500 - decrypted_data(47 downto 40);
--				n100 <= n100 - decrypted_data(39 downto 32);