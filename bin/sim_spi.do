vsim -modelsimini build/modelsim.ini -t 1ps -L irz -L spi spi.spi_tb
run -all
quit -f
