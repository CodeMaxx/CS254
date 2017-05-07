----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    17:34:29 01/23/2017
-- Design Name:
-- Module Name:    Controller_Top_Module - Behavioral
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

entity Controller_Top_Module is
    Port ( data_in_sliders : in  STD_LOGIC_VECTOR (7 downto 0);
           next_data_in_button : in  STD_LOGIC;
			  next_data_out_button : in  STD_LOGIC;
			  start_encrypt_button: in STD_LOGIC;
			  start_decrypt_button: in STD_LOGIC;
			  done: out STD_LOGIC;
           data_out_leds : out  STD_LOGIC_VECTOR (7 downto 0));

end Controller_Top_Module;

architecture Behavioral of Controller_Top_Module is
	component debouncer
		port (clk: in STD_LOGIC;
		      button: in STD_LOGIC;
 				button_deb: out STD_LOGIC);
	end component;

   component encrypter
      port (clk: in STD_LOGIC;
				plaintext: in STD_LOGIC_VECTOR (63 downto 0);
				start: in STD_LOGIC;
				ciphertext: out STD_LOGIC_VECTOR (63 downto 0);
				done: out STD_LOGIC);
	end component;

	component decrypter
      port (clk: in STD_LOGIC;
				ciphertext: in STD_LOGIC_VECTOR (63 downto 0);
				start: in STD_LOGIC;
				plaintext: out STD_LOGIC_VECTOR (63 downto 0);
				done: out STD_LOGIC);
	end component;

	component read_multiple_data_bytes
		port (clk : in  STD_LOGIC;
				data_in : in  STD_LOGIC_VECTOR (7 downto 0);
				next_data : in  STD_LOGIC;
				data_read : out  STD_LOGIC_VECTOR (63 downto 0));
	end component;

	component display_multiple_data_bytes
		port (clk : in  STD_LOGIC;
				data_in : in  STD_LOGIC_VECTOR (63 downto 0);
				next_data : in  STD_LOGIC;
				data_out : in  STD_LOGIC_VECTOR (7 downto 0));
	end component;

signal debounced_next_data_in_button: STD_LOGIC;
signal debounced_next_data_out_button: STD_LOGIC;
signal debounced_start_encrypt_button: STD_LOGIC;
signal debounced_start_decrypt_button: STD_LOGIC;
signal multi_byte_data_read: STD_LOGIC_VECTOR (63 downto 0);
signal ciphertext_out: STD_LOGIC_VECTOR (63 downto 0);
signal plaintext_out: STD_LOGIC_VECTOR (63 downto 0);
signal data_to_be_displayed: STD_LOGIC_VECTOR (63 downto 0);
signal encryption_over: STD_LOGIC;
signal decryption_over: STD_LOGIC;

begin

debouncer1: debouncer  port map (clk => clk,
									      button => next_data_in_button,
									      button_deb => debounced_next_data_in_button);

debouncer2: debouncer  port map (clk => clk,
									      button => next_data_out_button,
									      button_deb => debounced_next_data_out_button);

debouncer3: debouncer  port map (clk => clk,
									      button => start_encrypt_button,
									      button_deb => debounced_start_encrypt_button);

debouncer2: debouncer  port map (clk => clk,
										   button => start_decrypt_button,
										   button_deb => debounced_start_decrypt_button);

data_inp: read_multiple_data_bytes
					  port map (clk => clk,
			  					   data_in => data_in_sliders,
								   next_data => debounced_next_data_in_button,
								   data_read => multi_byte_data_read);

data_out: display_multiple_data_bytes
					  port map (clk => clk,
			  					   data_in => data_to_be_displayed,
								   next_data => debounced_next_data_out_button,
								   data_out => data_out_leds);

encrypter: encrypter port map (clk => clk,
				 					    plaintext => multi_byte_data_read,
									    start => debounced_start_encrypt_button,
									    ciphertext => ciphertext_out,
									    done => encryption_over);

decrypter: decrypter port map (clk => clk,
										 ciphertext => data_saved,
                               start => debounced_start_decrypt_button,
									    plaintext => plaintext_out,
									    done => decryption_over);

steer_enc_or_dec_output_to_display:
 process(clk, debounced_start_encrypt_button, debounced_start_decrypt_button)
 begin
	if (clk'event AND clk = '1') then
		if ((debounced_start_encrypt_button = '1') AND
			 (debounced_start_decrypt_button = '0')) then
			data_to_be_displayed <= ciphertext_out;
		elsif ((debounced_start_encrypt_button = '0') AND
			 (debounced_start_decrypt_button = '1')) then
			data_to_be_displayed <= plaintext_out;
		end if;
   end if;
 end process;

 done <= encryption_over AND decryption_over;

end Behavioral;

