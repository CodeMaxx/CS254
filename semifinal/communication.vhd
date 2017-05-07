----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:38:05 03/15/2017 
-- Design Name: 
-- Module Name:    communication - Behavioral 
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
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity communication is
	PORT( 
		  clk : in STD_LOGIC;
		  is_user: out STD_LOGIC;
		  is_suf_bal: out STD_LOGIC;
		  is_suf_atm: in STD_LOGIC;
		  start_comm : in STD_LOGIC;
		  done_comm : out STD_LOGIC;
		  data_send: in STD_LOGIC_VECTOR (63 downto 0);
		  data_recieved: out STD_LOGIC_VECTOR (63 downto 0);
		  
		  chanAddr_in  : in std_logic_vector(6 downto 0);  -- the selected channel (0-127)

	-- Host >> FPGA pipe:
	h2fData_in   : in std_logic_vector(7 downto 0);  -- data lines used when the host writes to a channel
	h2fValid_in  : in std_logic;                     -- '1' means "on the next clock rising edge, please accept the data on h2fData"
	h2fReady_out  : out std_logic;                     -- channel logic can drive this low to say "I'm not ready for more data yet"
	
	-- Host << FPGA pipe:
	f2hData_out   : out std_logic_vector(7 downto 0);  -- data lines used when the host reads from a channel
	f2hValid_out  : out std_logic;                     -- channel logic can drive this low to say "I don't have data ready for you"
	f2hReady_in  : in std_logic                   -- '1' means "on the next clock rising edge, put your next byte of data on f2hData"
		  
		  );
end communication;

architecture Behavioral of communication is 
signal channel0value : std_logic_vector(7 downto 0) := "00000000";
signal checkuser : std_logic_vector(7 downto 0) := "00000000";
signal a : std_logic_vector(7 downto 0) := "00000001";
signal b : std_logic_vector(7 downto 0) := "00000011";
signal c : std_logic_vector(7 downto 0) := "00000111";
signal d : std_logic_vector(7 downto 0) := "00001111";
signal e : std_logic_vector(7 downto 0) := "00011111";
signal f : std_logic_vector(7 downto 0) := "00111111";
signal g : std_logic_vector(7 downto 0) := "01111111";
signal h : std_logic_vector(7 downto 0) := "11111111";
begin
	with is_suf_atm select channel0value <=
					"00000001" when '1',
					"00000010" when others;
	with checkuser select is_user <= 
					'1' when "00000001",
					'1' when "00000010",
					'0' when "00000011",
					'0' when "00000100",
					'0' when others;
	with checkuser select is_suf_bal <= 
					'1' when "00000001",
					'0' when "00000010",
					'1' when "00000011",
					'0' when "00000100",
					'0' when others;
	with checkuser select done_comm <= 
					'1' when "00000001",
					'1' when "00000010",
					'1' when "00000011",
					'1' when "00000100",
					'0' when others;	
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(start_comm = '1') then
				if(f2hReady_in = '1') then
					if(chanAddr_in = "0000000") then
						f2hData_out <= channel0value;
					elsif(chanAddr_in = "0000001") then
						f2hData_out <= data_send(63 downto 56);
					elsif(chanAddr_in = "0000010") then
						f2hData_out <= data_send(55 downto 48);
					elsif(chanAddr_in = "0000011") then
						f2hData_out <= data_send(47 downto 40);
					elsif(chanAddr_in = "0000100") then
						f2hData_out <= data_send(39 downto 32);
					elsif(chanAddr_in = "0000101") then
						f2hData_out <= data_send(31 downto 24);
					elsif(chanAddr_in = "0000110") then
						f2hData_out <= data_send(23 downto 16);
					elsif(chanAddr_in = "0000111") then
						f2hData_out <= data_send(15 downto 8);
					elsif(chanAddr_in = "0001000") then
						f2hData_out <= data_send(7 downto 0);
					end if;
				end if;
				f2hValid_out <= '1';
				h2fReady_out <= '1';

				if(h2fValid_in = '1') then
					if(chanAddr_in = "0001001") then
						checkuser <= h2fData_in;
					elsif(chanAddr_in = "0001010") then
						a <= h2fData_in;
					elsif(chanAddr_in = "0001011") then
						b <= h2fData_in;
					elsif(chanAddr_in = "0001100") then
						c <= h2fData_in;
					elsif(chanAddr_in = "0001101") then
						d <= h2fData_in;
					elsif(chanAddr_in = "0001110") then
						e <= h2fData_in;
					elsif(chanAddr_in = "0001111") then
						f <= h2fData_in;
					elsif(chanAddr_in = "0010000") then
						g <= h2fData_in;
					elsif(chanAddr_in = "0010001") then
						h <= h2fData_in;
					end if;
					data_recieved <= a & b & c & d & e & f & g & h;
				end if;
			end if;
		end if;
	end process;
end Behavioral;

