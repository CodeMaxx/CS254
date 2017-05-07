----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:38:23 03/15/2017 
-- Design Name: 
-- Module Name:    timer - Behavioral 
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

entity timer is
    Generic (N : STD_LOGIC_VECTOR (23 downto 0) := x"FF2F40");
port (clk: in STD_LOGIC;
		blink: out STD_LOGIC;
		i: out STD_LOGIC
			);
end timer;

architecture Behavioral of timer is
	signal temp : STD_LOGIC_VECTOR (24 downto 0) := "0000000000000000000000000";
begin
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(temp < N ) then
				temp <= temp + "0000000000000000000000001";
				blink <= '0';
			elsif(temp < "10"*N) then
				blink <= '1';
				temp <= temp + "0000000000000000000000001";
			else
				temp <= "0000000000000000000000000";	
			end if;
			if(temp = N ) then
				i <= '1';
			else
				i <= '0';
			end if;
		end if;
	end process;

end Behavioral;

