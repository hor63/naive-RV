riscv32-unknown-elf-gcc -B/home/hor/riscv/build-riscv-toolchain/build-newlib/riscv32-unknown-elf/newlib/ -isystem /home/hor/riscv/build-riscv-toolchain/build-newlib/riscv32-unknown-elf/newlib/targ-include -isystem /home/hor/riscv/riscv-gnu-toolchain/newlib/newlib/libc/include -B/home/hor/riscv/build-riscv-toolchain/build-newlib/riscv32-unknown-elf/libgloss/riscv32 -L/home/hor/riscv/build-riscv-toolchain/build-newlib/riscv32-unknown-elf/libgloss/libnosys -L/home/hor/riscv/riscv-gnu-toolchain/newlib/libgloss/riscv32    -MMD -MP -I. -I/home/hor/riscv/riscv-gnu-toolchain/newlib/libgloss/riscv -O2 -D_POSIX_MODE -ffunction-sections -fdata-sections   -mcmodel=medlow  -march=rv32im -mabi=ilp32 -c crt0.S