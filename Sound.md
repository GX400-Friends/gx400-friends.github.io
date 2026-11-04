# Sound

## Z80 CPU

The Z80 is an 8-bit microprocessor made by Zilog in 1976. It has an 8-bit data bus and a 16-bit address bus. In Nemesis, it is equipped with 16 kB of ROM, containing the program and the audio data, and 2 kB of RAM, for variables. In addition to ROM and RAM, the following peripherals are connected:

* Two AY-3-8910 Programmable Sound Generators (PSG,) one for music, and the other for sound effects;
* A Konami-custom K0005289 chip, for additional music;
* An 8-bit latch that holds the command sent by the main CPU;
* A second 8-bit latch that controls two togglable low-pass filters on the AY-3-8910 PSGs.

In this architechure, the peripherals are accessed as if they were memory. It means that they are connected to the address and data buses of the processor, and enabled when “the right addresses” are used. Since memory and certain peripherals put values on the data bus, at maximum one of them can be enabled at any time. This is achieved by the address decoder, that generates a Chip Enable signal for each of the devices on the bus. When a device’s Chip Enable is not active, it doesn’t respond to address changes, and leaves its data output at high impedance, so that it doesn’t force any value on the bus.

## Address Decoder

After reset, the Z80 starts executing instructions from address `h0000`. Therefore, the ROM needs to be located at addresses `h0000–h3FFF` (16 kB.) This is done by activating the ROM’s Chip Enable (`/CE`) pin (by setting it to zero, because it is active low) when address lines `A14` and `A15` are both zero (because those are the two address bits that stay constant for all addresses between `h0000` and `h3FFF`.) This is achieved by the LS138 3-Line to 8-Line decoder labelled “10C” on the schematic.

### ROM

This LS138 takes address lines `A13–A15` as inputs A/B/C, which form a 3-bit number between 0 and 7, and activates, among ouputs `Y0` to `Y7`, the one that corresponds to that number (by setting it to zero, because, like the ROM’s Chip Enable, the LS138 outputs are active low.) So when `A13`, `A14` and `A15` are all zero (`A[15:13] = b000`,) output `Y0` is zero, and all other outputs are one. And when `A13` is one, and `A14` and `A15` are zero (`A[15:13] = b001`,) output `Y1` is zero. `Y0` and `Y1` are combined by an AND gate that controls the ROM’s Chip Enable. Therefore, when either `Y0` or `Y1` is zero, the ROM is enabled.

### RAM

The third output of the LS138 at 10C, `Y2`, is activated when `A[15:13] = b010`, and controls the RAM’s Chip Enable. Therefore, the RAM is located at addresses `h4000–h7FFF`. But there are only 2 kB of RAM, which requires 11 address lines, so the range for the RAM is `h4000–h47FF`[^1].

### Sound Command

Ignoring outputs `Y5` and `Y6` for a moment, let’s look at `Y7`. It is enabled when `A[15:13] = b111`, and enables a second LS138, labelled “11C.” Its inputs, this time, are address lines `A0–A2`. The first used output on that second LS138 is `Y1`, which is enabled when `A[15:13] = b111` and `A[2:0] = b010`, which corresponds to address `hE002`. `Y1` is connected the the Chip Enable of LS374 11A, which is the Octal D Flip-Flop that holds the sound command sent from the main CPU. Therefore, when the Z80 reads at address `hE007`, the result is the last sound command received.

### Togglable Low-Pass Filters

Another D flip-flop is connected on output `Y7` of decoder 11C. It’s an LS174 Hex D Flip-Flop, but it’s the clock input that is driven by the decoder. `A11` and `A12` are connected to input `D` of flip-flops 5 and 6, respectively, the output of which drive a CD4066 Quad Bilateral Switch which toggles low-pass filters at the output of the AY-3-8910 PSGs.

This gives us four memory addresses of interest, when `A[15:13] = b111`, `A[2:0] = b111`:

* `hE007` when `A[12:11] = 0b00`: both filters are disabled;
* `hE807` when `A[12:11] = 0b01`: filter on PSG 7E is enabled;
* `hF007` when `A[12:11] = 0b10`: filter on PSG 8E is enabled;
* `hF807` when `A[12:11] = 0b11`: both filters are enabled.

When one of these addresses is accessed by the Z80, whether it’s for a read or write operation, the clock input of the flip-flop is triggered, and the values of `A11` and `A12` are latched on the output of flip-flops 5 and 6, which enables or disables the filters as described. This happens when the `/MREQ`(Memory Request) line on the Z80 is released, because this signal is used to enable the first LS138 decoder.

[^1]: Technically, since `A11` and `A12` are ignored when decoding the RAM’s Chip Enable, the RAM is duplicated eight times in the address space: at `h4000–h47FF`, `h4800–h4FFF`, `h5000–h57FF`, etc, until `h7800–h7FFF`, and can be accessed at any of these address ranges. But in practice, only the first one is usually used.
