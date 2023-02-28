# Makefile automatically generated by ghdl
# Version: GHDL 1.0.0 (Ubuntu 1.0.0+dfsg-6) [Dunoon edition] - GCC back-end code generator
# Command used to generate this makefile:
# ghdl-gcc --gen-makefile --std=08 --work=cpu_register_file naive_RV

GHDL=ghdl-gcc
GHDLFLAGS= --std=08

# Default target
all: naive_RV

dep:
	$(GHDL) --gen-depends $(GHDLFLAGS) naive_RV > Makefile.dep

# Elaboration target
naive_RV: pkg_cpu_global.o pkg_cpu_register_file.o ent_cpu_register_file.o \
	pkg_cpu_instr_decoder.o ent_cpu_instr_decoder.o \
	naive_RV.o
	$(GHDL) -e $(GHDLFLAGS) $@

# Run target
run: naive_RV
	$(GHDL) -r naive_RV $(GHDLRUNFLAGS)

pkg_cpu_global.o: pkg_cpu_global.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
pkg_cpu_register_file.o: pkg_cpu_register_file.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
pkg_cpu_instr_decoder.o: pkg_cpu_instr_decoder.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
ent_cpu_register_file.o: ent_cpu_register_file.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<
ent_cpu_instr_decoder.o: ent_cpu_instr_decoder.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<

naive_RV.o: naive_RV.vhdl
	$(GHDL) -a $(GHDLFLAGS) $<

# Files dependences
-include Makefile.dep
