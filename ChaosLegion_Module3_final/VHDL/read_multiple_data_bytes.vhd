----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:36:05 03/15/2017 
-- Design Name: 
-- Module Name:    read_multiple_data_bytes - Behavioral 
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

entity read_multiple_data_bytes is
	port (clk : in  STD_LOGIC;
				reset : in STD_LOGIC;
				data_in : in  STD_LOGIC_VECTOR (7 downto 0);
				next_data : in  STD_LOGIC;
				data : out  STD_LOGIC_VECTOR (63 downto 0);
				done : out STD_LOGIC;
				data_received : out STD_LOGIC_VECTOR (2 downto 0));
end read_multiple_data_bytes;

architecture Behavioral of read_multiple_data_bytes is
signal i : STD_LOGIC_VECTOR (3 downto 0) := "0000";
signal state : STD_LOGIC_VECTOR (1 downto 0) := "00";
signal temp : STD_LOGIC_VECTOR (63 downto 0);
signal prev_value : STD_LOGIC := '0';
begin
	data_received <= i(2 downto 0);
	process(reset,clk,next_data)
	begin
		if(reset = '1') then
			i <= "0000";
			temp <= X"0000000000000000";
			state <= "00";
			done <= '0';
		elsif(rising_edge(clk)) then
			if(state = "00" and prev_value = '0' and next_data = '1' and i < "1000") then
				temp <= shl(temp, "1000");
				state <= "10";
			elsif(state = "10") then
				temp <= temp + data_in;
				i <= i + "1";
				state <= "11";
			elsif(state = "11") then
				data <= temp;
				state <= "00";
			elsif(i = "1000") then
				done <= '1';
			else
				done <= '0';
			end if;
			prev_value <= next_data;
		end if;
	end process;
end Behavioral;