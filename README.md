# LogiFindFPGATest
This is a Quartus Prime FPGA project testing the functionality of the LogiFind Altera Cyclone IV EP4CE6E22C8N Development Board. This product can also be found on eBay where I bought it from. I hope to provide base code that will help others in their learning with this development board.

## Where to get FPGA
The original manufacturer is a company called LogiFind.
* [LogiFind](http://logifind.com/fpga-cpld-dsp/altera-cyclone-iv-fpga-development-board-ep4ce6e22c8n-1172.html)
* [eBay](http://www.ebay.com/itm/Altera-Cyclone-IV-FPGA-EP4CE6E22C8N-V2-Development-Board-USB-BlasterProgrammer-/152251880703?hash=item2372eb54ff:g:8HMAAOSwYIxX5KVZ)

## Additional Resources
LogiFind supplies datasheets for each chip on the development board, user guide, development board schematic, 8 sample projects, USB blaster driver, UART COM PL2303 driver, PCB design, etc in a RAR file. Really, I am surprised at the amount of information they have included. I expected a lot less.

Some users commented about the link being unsafe when their virus protection software scanned it, so I have uploaded it to my website in case anyone would rather use that link. Also, there were a few schematics and files that were completely in Chinese that I translated(with the power of the internet) and saved into English documents. Another reason to use my link instead of theirs.
* [My Link](http://www.addielli.com/easyFPGA2.0.zip)
* [Original Link](http://logifind.oss-cn-hongkong.aliyuncs.com/easyFPGA.rar)

## Hardware Description Language (HDL)
I use a few SystemVerilog features in this project such as enums, packages, and floating-point rounding. Thus, SystemVerilog must be enabled to run this project. If you are receiving errors about the line:
`import UART_CONSTANTS::*;`

Then, you likely do not have SystemVerilog enabled for the compiler.

# [Downloading Project and Running it on Your FPGA](https://github.com/addisonElliott/LogiFindFPGATest/wiki/Downloading-Project-and-Running-it-on-Your-FPGA)
Detailed guide can be found by clicking the link above. The page can also be found by going to the Wiki section of the Github project.
