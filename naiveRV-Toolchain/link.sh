#!/bin/sh

CMD=$1

while [ ! -z "$2" ]
do
    OPTS="$OPTS $2"
    shift
done

echo "CMD=$CMD"
echo "OPTS=$OPTS"

echo "Command = \"$CMD -nostartfiles crt0.o /opt/riscv/lib/gcc/riscv32-unknown-elf/12.2.0/crtbegin.o $OPTS \""

$CMD -nostartfiles crt0.o /opt/riscv/lib/gcc/riscv32-unknown-elf/12.2.0/crtbegin.o $OPTS


# /opt/riscv/libexec/gcc/riscv32-unknown-elf/12.2.0/collect2 -v -plugin /opt/riscv/libexec/gcc/riscv32-unknown-elf/12.2.0/liblto_plugin.so -plugin-opt=/opt/riscv/libexec/gcc/riscv32-unknown-elf/12.2.0/lto-wrapper -plugin-opt=-fresolution=/tmp/ccBvDTlf.res -plugin-opt=-pass-through=-lgcc -plugin-opt=-pass-through=-lc -plugin-opt=-pass-through=-lgloss -plugin-opt=-pass-through=-lgcc --sysroot=/opt/riscv/riscv32-unknown-elf -melf32lriscv -o test crt0.o /opt/riscv/lib/gcc/riscv32-unknown-elf/12.2.0/crtbegin.o -L/opt/riscv/lib/gcc/riscv32-unknown-elf/12.2.0 -L/opt/riscv/lib/gcc/riscv32-unknown-elf/12.2.0/../../../../riscv32-unknown-elf/lib -L/opt/riscv/riscv32-unknown-elf/lib test.o -lgcc --start-group -lc -lgloss --end-group -lgcc /opt/riscv/lib/gcc/riscv32-unknown-elf/12.2.0/crtend.o -T test.ld
