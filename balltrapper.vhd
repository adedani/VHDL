--------------------------------------------------------------------
--Ashween Dedani
--03/24/2021
--
--          The obejective of this lab is too trap the led (ball) between the 
--          switches that are onn and increase the counter on the particular
--          side at which the ball falls off.
--
------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use ieee.std_logic_unsigned.all;

entity balltrap is
      Port (clk: in std_logic;
            btnL: in std_logic; --Left/serve 
            btnR: in std_logic; --Right/serve 
            btnD: in std_logic; --RESET /down 
            btnC: in std_logic; --centre
            sw : in std_logic_vector (15 downto 0); 
            led : out std_logic_vector (15 downto 0); 
            seg: out std_logic_vector(6 downto 0); 
            an: out std_logic_vector(3 downto 0) 
 );
end balltrap;

architecture balltrap_ARCH of balltrap is

 ----general definitions-----------------------------------------CONSTANTS 
 constant HIGH: std_logic := '1'; 
 constant BALLSPEED_2HZ: integer := 20000000; 
 constant BALLSPEED_1kHZ: integer := 100000; 
 constant TEN: integer := 10; 
 constant DISABLE_DIGIT: std_logic := '1';
constant ENABLE_DIGIT: std_logic := '0';
constant DISABLE_RESET: std_logic := '0';
 constant ALLZEREOS: std_logic_vector(15 downto 0) := "0000000000000000";
  
-----------------Seven Segment Display-------------------------------
constant ZERO_7SEG: std_logic_vector(3 downto 0) := "0000";
constant ONE_7SEG: std_logic_vector(3 downto 0) := "0001";
constant TWO_7SEG: std_logic_vector(3 downto 0) := "0010";
constant THREE_7SEG: std_logic_vector(3 downto 0) := "0011";
constant FOUR_7SEG: std_logic_vector(3 downto 0) := "0100";
constant FIVE_7SEG: std_logic_vector(3 downto 0) := "0101";
constant SIX_7SEG: std_logic_vector(3 downto 0) := "0110";
constant SEVEN_7SEG: std_logic_vector(3 downto 0) := "0111";
constant EIGHT_7SEG: std_logic_vector(3 downto 0) := "1000";
constant NINE_7SEG: std_logic_vector(3 downto 0) := "1001";
constant A_7SEG: std_logic_vector(3 downto 0) := "1010";
constant B_7SEG: std_logic_vector(3 downto 0) := "1011";
constant C_7SEG: std_logic_vector(3 downto 0) := "1100";
constant D_7SEG: std_logic_vector(3 downto 0) := "1101";
constant E_7SEG: std_logic_vector(3 downto 0) := "1110"; 
constant F_7SEG: std_logic_vector(3 downto 0) := "1111";


 -----internal connections------------------------------------SIGNALS
signal digit3_value: std_logic_vector(3 downto 0);
signal digit2_value: std_logic_vector(3 downto 0);
signal digit1_value: std_logic_vector(3 downto 0);
signal digit0_value: std_logic_vector(3 downto 0);
signal digit3_blank: std_logic;
signal digit2_blank: std_logic;
signal digit1_blank: std_logic;
signal digit0_blank: std_logic; 

signal centre: std_logic;
 signal serveR: std_logic;  --left button
 signal serveL: std_logic; ---- right BUTTON 
 signal reset: std_logic; ----DOWN BUTTON 
 signal shiftEnable: std_logic; 
 signal shiftIn: std_logic; 
 signal LEDS: std_logic_vector(15 downto 0); 
 signal start: std_logic; 
 signal start1: std_logic;
 signal shiftleft: std_logic; 
 signal shiftright: std_logic; 
 signal ballOutOfBounds: std_logic; 
 signal ballBounce: std_logic_vector (15 downto 0); 
 signal move: std_logic_vector (15 downto 0); 
 signal bounceCount: integer; 
 signal display: std_logic; 
 signal digit00: std_logic_vector (0 to 3); 
 signal digit01: std_logic_vector (0 to 3); 
 signal counter1: std_logic; 
 signal counter2: std_logic;
signal Decode: integer range 20 downto 0; 
signal Victory: integer range 20 downto 0; 


-----state machine declarations------------------------CONSTANTS&SIGNALS  
type states is( WAIT_FOR_START, SERVE_BALL, SERVE_BALLR, MOVE_LEFT, MOVE_RIGHT);  
signal currentState: states; 
signal nextState: states;

-------------Seven Segment Driver------------------------------
component SevenSegmentDriver
 port(
 clock: in std_logic;
 reset: in std_logic;
 digit0: in std_logic_vector(3 downto 0);
 digit1: in std_logic_vector(3 downto 0);
 digit2: in std_logic_vector(3 downto 0);
 digit3: in std_logic_vector(3 downto 0);
 blank0: in std_logic;
 blank1: in std_logic;
 blank2: in std_logic;
 blank3: in std_logic;
 sevenSegs: out std_logic_vector(6 downto 0);
 anodes: out std_logic_vector(3 downto 0)
 );
 end component; 

begin

 ------------------------------------------Name change for easier reading
 serveL <= btnL; 
 serveR <= btnR;
 reset <= btnD;
 centre <= btnC; 
led <= LEDS; 
---------------------Driver-----------------------------------
 MY_SEGMENTS: SevenSegmentDriver 
 port map(
            reset => DISABLE_RESET,
            clock => clk,
            digit3 => digit3_value,
            digit2 => digit2_value,
            digit1 => digit1_value,
            digit0 => digit0_value,
            blank3 => digit3_blank,
            blank2 => digit2_blank,
            blank1 => digit1_blank,
            blank0 => digit0_blank,
            SevenSegs => seg,
            anodes => an); 
---------------------------------------------------------------------- 
 -----state-machine-register------------------------------------PROCESS 
-----------------------------------------------------------------------  
STATE_REGISTER: process(reset, clk) 
    begin 
       if (reset = HIGH) then 
              CurrentState <= WAIT_FOR_START; 
       elsif (rising_edge(clk)) then 
             if(shiftEnable = HIGH) then 
                currentState <= nextState; 
              end if; 
        end if; 
 end process;


STATE_TRANSITION: process(currentState, sw, LEDS, reset) 
    begin 
     case(currentState) is 
       when WAIT_FOR_START => 
               ballOutOfBounds <= HIGH; 
               start <= not HIGH; 
               start1 <= not HIGH;
               shiftleft <= not HIGH; 
               shiftright <=  HIGH;
               shiftIn <= not HIGH;
               counter2 <= not HIGH;
               counter1 <= not HIGH;
               
          if(serveL = HIGH) then 
             nextState <= SERVE_BALL; 
          elsif(serveR = HIGH)then
             nextState <= SERVE_BALLR;
          else 
              nextState <= WAIT_FOR_START; 
          end if; 
       
         when SERVE_BALL => 
              ballOutOfBounds <= not HIGH; 
              start <= HIGH; 
              shiftleft <= HIGH; 
              shiftIn <= not HIGH; 
              nextState <= MOVE_RIGHT;
               
        when SERVE_BALLR => 
              ballOutOfBounds <= not HIGH; 
              start1 <= HIGH; 
              shiftright <= not HIGH; 
              shiftIn <= not HIGH; 
              nextState <= MOVE_LEFT;
              
            when MOVE_RIGHT => 
                 ballOutOfBounds <= not HIGH; 
                 start <= not HIGH; 
  
                  if(ballBounce /= AllZEREOS) then 
                      shiftleft <= not HIGH;
                      shiftIn <= HIGH; 
                      shiftright <= not HIGH; 
--                      counter2 <= HIGH; 
                      nextState <= MOVE_LEFT;

                  elsif(LEDS = ALLZEREOS) then 
                       shiftIn <= not HIGH; 
                       counter1 <= HIGH;
                       nextState <= WAIT_FOR_START; 
                      
                   else 
                       shiftIn <= HIGH; 
                       shiftLeft <= HIGH; 
                       counter1 <= not HIGH;
                       nextState <= MOVE_RIGHT; 
                  end if; 
                       
                 when MOVE_LEFT => 
                      ballOutOfBounds <= not HIGH; 
                       start <= not HIGH; 
  
                    if(ballBounce /= ALLZEREOS) then 
                        shiftIn <= HIGH; 
                        shiftLeft <=  HIGH; 
--                        counter2 <= HIGH; 
                        nextState <= MOVE_RIGHT; 
                        
                    elsif(LEDS = ALLZEREOS) then 
                         shiftIn <= not HIGH;
                         counter2 <= HIGH; 
                         nextState <= WAIT_FOR_START;  
                         
                     else 
                          shiftIn <= HIGH; 
                          shiftRight <= not HIGH; 
                          counter2 <= not HIGH; 
                          nextState <= MOVE_LEFT; 
                      end if; 
                      
                end case; 
          end process;

  ------------------------------------------------------------------  
  --Shift Register-------------------------------------------PROCESS 
   -------------------------------------------------------------------  
SHIFT_REGISTER: process(clk,centre) 
     variable count1: integer range 0 to 20;
     variable count2: integer range 0 to 20;
   begin 
      led <= LEDS; 
          if(centre = HIGH)   then 
              count1 := 0;
              count2 := 0;
          elsif(rising_edge(clk)) then 
             if(shiftEnable = HIGH) then
                if(ballOutOfBounds = HIGH) then 
                      LEDS <= ALLZEREOS; 
                 elsif(counter1 = HIGH)then
                      count1 := count1 + 1;
                 elsif(counter2 = HIGH) then
                     count2  :=  count2 + 1;
                elsif(start = HIGH) then 
                     LEDS <= LEDS(15 downto 1) & '1'; 
                elsif(start1 = HIGH) then 
                     LEDS <=   '1' & LEDS(14 downto 0);
                elsif(shiftIn = HIGH) then 
                      if (shiftLeft = HIGH) then 
                         LEDS <= LEDS(14 downto 0) & '0'; 
                       elsif(shiftRight = not HIGH) then 
                          LEDS <= '0'& LEDS(15 downto 1); 
                       end if; 
                  end if; 
               end if; 
            end if; 
            
             Decode <= count1;
             Victory <= count2;
 end process;

 ------------------------------------------------------------------  
 --LED hits a Switch-----------------------------------------PROCESS  
 -------------------------------------------------------------------  
 LED_HIT: process(sw,leds) 
    begin 
       move <= sw; 
       ballBounce <= move and leds;
       
       
 end process; 

 ------------------------------------------------------------------  
 --clock divider-------------------------------------------PROCESS  
 -------------------------------------------------------------------  
 CLOCK_DIVEDER: process(clk, reset) 
        variable counter: integer range 0 to BALLSPEED_2HZ;  
   begin 
           if(reset = HIGH) then 
              counter := 0;
             shiftEnable <= not HIGH; 
           elsif(rising_edge(clk)) then 
               if(counter = BALLSPEED_2HZ) then 
                   shiftEnable <= HIGH; 
                   counter := 0; 
                else 
                    shiftEnable <= not HIGH; 
                   counter := counter + 1; 
                end if; 
          end if; 
 end process;

--------------------------------------------------------------------
----counter---------------------------------------------------------
--------------------------------------------------------------------
 COUNTER: process(Decode, Victory)
 begin
      
      case (Decode) is
           when 0 =>
               digit2_value <= ZERO_7SEG;
               digit3_value <= ZERO_7SEG;
           when 1 =>
               digit2_value <= ONE_7SEG;
               digit3_value <= ZERO_7SEG;
            when 2 =>
               digit2_value <= TWO_7SEG;
               digit3_value <= ZERO_7SEG;
            when 3 =>
               digit2_value <= THREE_7SEG;
               digit3_value <= ZERO_7SEG;
            when 4 =>
               digit2_value <= FOUR_7SEG;
               digit3_value <= ZERO_7SEG;
            when 5 =>
               digit2_value <= FIVE_7SEG;
               digit3_value <= ZERO_7SEG;
            when 6 =>
               digit2_value <= SIX_7SEG;
               digit3_value <= ZERO_7SEG;
            when 7 =>
               digit2_value <= SEVEN_7SEG;
               digit3_value <= ZERO_7SEG;
            when 8 =>
                digit2_value <= EIGHT_7SEG;
                digit3_value <= ZERO_7SEG;
            when 9 =>
                digit2_value <= NINE_7SEG;
                digit3_value <= ZERO_7SEG;
            when others =>
                 digit2_value <= ZERO_7SEG;
                 digit3_value <= ONE_7SEG;
         end case;
             
             
        case(Victory) is
           when 0 =>
               digit0_value <= ZERO_7SEG;
               digit1_value <= ZERO_7SEG;
           when 1 =>
               digit0_value <= ONE_7SEG;
               digit1_value <= ZERO_7SEG;
            when 2 =>
               digit0_value <= TWO_7SEG;
               digit1_value <= ZERO_7SEG;
            when 3 =>
               digit0_value <= THREE_7SEG;
               digit1_value <= ZERO_7SEG;
            when 4 =>
               digit0_value <= FOUR_7SEG;
               digit1_value <= ZERO_7SEG;
            when 5 =>
               digit0_value <= FIVE_7SEG;
               digit1_value <= ZERO_7SEG;
            when 6 =>
               digit0_value <= SIX_7SEG;
               digit1_value <= ZERO_7SEG;
            when 7 =>
               digit0_value <= SEVEN_7SEG;
               digit1_value <= ZERO_7SEG;
            when 8 =>
                digit0_value <= EIGHT_7SEG;
                digit1_value <= ZERO_7SEG;
            when 9 =>
                digit0_value <= NINE_7SEG;
                digit1_value <= ZERO_7SEG;
            when others =>
                 digit0_value <= ZERO_7SEG;
                 digit1_value <= ONE_7SEG;
         end case;
 end process;

end balltrap_ARCH;
