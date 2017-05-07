--
-- Copyright (C) 2009-2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of swled is
	-- Flags for display on the 7-seg decimal points
	signal flags                   : std_logic_vector(3 downto 0);

	-- Registers implementing the channels
	signal checksum, checksum_next : std_logic_vector(15 downto 0) := (others => '0');
	--signal reg0, reg0_next         : std_logic_vector(7 downto 0)  := (others => '0');
	type MyArray is array (0 to 127) of std_logic_vector(7 downto 0);
	signal reg, reg_next : MyArray;
	signal waittime : integer := 0;
	--signal i2 : integer := 0;
	signal i : integer := 0;

begin                                                                     --BEGIN_SNIPPET(registers)
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if (waittime < 500) then
				waittime <= waittime + 1;
			elsif ( reset_in = '1' ) then

				reg(to_integer(signed(chanAddr_in))) <= (others => '0');
				checksum <= (others => '0');
			else 
				reg(to_integer(signed(chanAddr_in))) <= reg_next(to_integer(signed(chanAddr_in)));
				checksum <= checksum_next;
			end if;
		end if;
	end process;

			--else if (i2 < 128)
			--	reg_next(i2) <= h2fData_in when chanAddr_in = i2 and h2fValid_in = '1';
			--	i2 <= i2 + 1;
	---- Drive register inputs for each channel when the host is writing
	--for i in '0' to "1111111" loop 
	reg_next(to_integer(signed(chanAddr_in))) <= h2fData_in when h2fValid_in = '1'
		else reg(to_integer(signed(chanAddr_in)));

	f2hData_out <= reg(to_integer(signed(chanAddr_in)));
	--end loop;

	--reg0_next <=
	--	h2fData_in when chanAddr_in = "0000000" and h2fValid_in = '1'
	--	else reg0;

	checksum_next <=
		std_logic_vector(unsigned(checksum) + unsigned(h2fData_in)) when h2fValid_in = '1'
		else checksum;
	
	-- Select values to return for each channel when the host is reading
	--with chanAddr_in select f2hData_out <=
	--	sw_in                 when "0000000",
	--	checksum(15 downto 8) when "0000101",
	--	checksum(7 downto 0)  when "0000011",
	--	x"00" when others;

	-- Assert that there's always data for reading, and always room for writing
	f2hValid_out <= '1';
	h2fReady_out <= '1';                                                     --END_SNIPPET(registers)

	-- LEDs and 7-seg display
	led_out <= reg(to_integer(signed(chanAddr_in)));
	flags <= "00" & f2hReady_in & reset_in;
	seven_seg : entity work.seven_seg
		port map(
			clk_in     => clk_in,
			data_in    => checksum,
			dots_in    => flags,
			segs_out   => sseg_out,
			anodes_out => anode_out
		);
end architecture;
