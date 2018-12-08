PIN_FILE = pcb.pcf

upload: hardware.bin
	tinyprog -p hardware.bin

hardware.bin: hardware.asc
	icetime -d hx8k -c 16 -mtr hardware.rpt hardware.asc
	icepack hardware.asc hardware.bin

hardware.blif: verilog/*.v rom.mem colors.mem
	yosys -ql hardware.log -p 'synth_ice40 -top mcu -blif hardware.blif' verilog/*.v

hardware.asc: $(PIN_FILE) hardware.blif
	arachne-pnr -r -m 400 -d 8k -P cm81 -o hardware.asc -p $(PIN_FILE) hardware.blif

clean:
	rm -f hardware.blif hardware.log hardware.asc hardware.rpt hardware.bin
