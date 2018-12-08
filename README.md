# atari_2600
TinyFPGA BX implementation of Atari 2600 for the FPGC LCD games console

## Hardware

This implementation runs on the [TinyFPGA BX Field Programmable Games Console](https://github.com/Fabien-Chouteau/field-programmable-game-console).

![TinyFPGA BX Field Programmable Games Console](https://discourse.tinyfpga.com/uploads/default/optimized/1X/f4435f46beb1bc25ac96b8b072648f0aa48cb1bf_1_690x388.jpeg "TinyFPGA BX Field Programmable Games Console")

See the [discussion on the TinyFPGA Forum](https://discourse.tinyfpga.com/t/bx-portable-game-console-project-collaboration).

## Build

To build a bit stream for an Atari 2600 game and upload it, do

```
git clone https://github.com/lawrie/atari_2600
cd atari_2600
./asm pong
make
```

You will need a Linux system with the TinyFPGA tools installed as described in the [TinyFPGA BX User Guide](https://tinyfpga.com/bx/guide.html).

