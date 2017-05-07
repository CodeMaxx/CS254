----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:22:48 03/15/2017 
-- Design Name: 
-- Module Name:    encrypter - Behavioral 
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

entity encrypter is
port (clk: in STD_LOGIC;
				reset : in STD_LOGIC;
				plaintext: in STD_LOGIC_VECTOR (63 downto 0);
				start: in STD_LOGIC;
				ciphertext: out STD_LOGIC_VECTOR (63 downto 0);
				done: out STD_LOGIC);
end encrypter;


architecture Behavioral of encrypter is

constant delta : STD_LOGIC_VECTOR (31 downto 0) := X"9e3779b9";
signal sum : STD_LOGIC_VECTOR (31 downto 0) := X"9e3779b9";
constant k0 : STD_LOGIC_VECTOR (31 downto 0) := X"ff0f7457";
constant k1 : STD_LOGIC_VECTOR (31 downto 0) := X"43fd99f7";
constant k2 : STD_LOGIC_VECTOR (31 downto 0) := X"75f8c48f";
constant k3 : STD_LOGIC_VECTOR (31 downto 0) := X"2927c18c";
signal v0 : STD_LOGIC_VECTOR (31 downto 0);
signal v1 : STD_LOGIC_VECTOR (31 downto 0);
signal i : STD_LOGIC_VECTOR (5 downto 0) := "000000";
signal state : STD_LOGIC := '0';

begin
	process(start,clk,reset)
	begin
		if(reset='1')then
			state <= '0';
			i <= "000000";
			sum <= X"9e3779b9";
			done <= '0';
		elsif(rising_edge(clk)) then
			if start='1' And i = "0" then
				v0 <= plaintext(63 downto 32);
				v1 <= plaintext(31 downto 0);
				i <= i + "1";
				done <= '0';
			elsif(i = "100001") then
				ciphertext <= v0 & v1;
				i <= i + "1";
				done <= '1';
			elsif i > "0" AND i < "100001" then
				if(state = '0') then
					v0 <= v0 + ((shl(v1,"100")+k0) XOR (v1 + sum) XOR (shr(v1,"101")+k1));
					state <= '1';
				else
					v1 <= v1 + ((shl(v0,"100")+k2) XOR (v0 + sum) XOR (shr(v0,"101")+k3));
					state <= '0';
					sum <= sum + delta;
					i <= i + "1";
				end if;
			else
				done <='0';
			end if;
		end if;
	end process;
	
end Behavioral;