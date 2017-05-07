----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:34:20 03/15/2017 
-- Design Name: 
-- Module Name:    decryptor - Behavioral 
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

entity decrypter is
port (clk: in STD_LOGIC;
				ciphertext: in STD_LOGIC_VECTOR (63 downto 0);
				start: in STD_LOGIC;
				reset: in STD_LOGIC;
				plaintext: out STD_LOGIC_VECTOR (63 downto 0);
				done: out STD_LOGIC);
end decrypter;

architecture Behavioral of decrypter is

constant delta : STD_LOGIC_VECTOR (31 downto 0) := X"9e3779b9";
signal sum : STD_LOGIC_VECTOR (31 downto 0) := X"C6EF3720";
constant k0 : STD_LOGIC_VECTOR (31 downto 0) := X"ff0f7457";
constant k1 : STD_LOGIC_VECTOR (31 downto 0) := X"43fd99f7";
constant k2 : STD_LOGIC_VECTOR (31 downto 0) := X"75f8c48f";
constant k3 : STD_LOGIC_VECTOR (31 downto 0) := X"2927c18c";
signal i : STD_LOGIC_VECTOR (5 downto 0) := "000000";
signal v0 : STD_LOGIC_VECTOR (31 downto 0);
signal v1 : STD_LOGIC_VECTOR (31 downto 0);
signal state : STD_LOGIC := '0';
begin
	process(start,reset,clk)
	begin
		if(reset='1')then
			i <= "000000";
			sum <= X"C6EF3720";
			state <= '0';
			done <= '0';
		elsif(rising_edge(clk)) then
			if start = '1' And i = "0" then
				v0 <= ciphertext(63 downto 32);
				v1 <= ciphertext(31 downto 0);
				i <= i + "1";
				done <= '0';
			elsif i = "100001" then
				plaintext <= v0 & v1;
				i <= i + "1";
				done <= '1';
			elsif i > "0" AND i < "100001" then
				if(state = '0') then
					v1 <= v1 - ((shl(v0,"100")+k2) XOR (v0 + sum) XOR (shr(v0,"101")+k3));
					state <= '1';
				else
					v0 <= v0 - ((shl(v1,"100")+k0) XOR (v1 + sum) XOR (shr(v1,"101")+k1));
					sum <= sum - delta;
					i <= i + "1";
					state <= '0';
				end if;
			else
				done <='0';
			end if;
		end if;
	end process;
end Behavioral;
