all:
	dasm *.asm -f3 -v0 -o./bin/cart.bin -l./bin/cart.lst -s./bin/cart.sym

run:
	stella ./bin/cart.bin