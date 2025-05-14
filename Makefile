-include gem5_args.conf

# Define the base path variable
ROOT := /workspace/final/

# Path to directories
ENV_DIR := /gem5/
RISCV_DIR := /opt/riscv/bin

# Compiler and assembler
CC   := $(RISCV_DIR)/riscv64-unknown-linux-gnu-gcc
DP   := $(RISCV_DIR)/riscv64-unknown-linux-gnu-objdump
HEX  := $(RISCV_DIR)/riscv64-unknown-linux-gnu-objcopy
CPP  := $(RISCV_DIR)/riscv64-unknown-linux-gnu-g++

# Program name
PROG := main
PROG_MCM = matrix_chain_multiplication.s

# Target files
CPP_SRC := $(PROG).cpp
C_SRC   := $(PROG).c
ASM_SRC := $(PROG).s

CPP_OUT := $(PROG)
C_OUT   := $(PROG)
ASM_OUT := $(PROG)
HEX_OUT := $(PROG).hex

DP_ASM  := $(PROG).asm
DP_EXEC := $(PROG)

# Compiler options
ARCH_FLAGS := -march=rv32gcv -mabi=ilp32
STATIC_FLAG := -static

.PHONY: all g++ gcc asm dump_asm dump_hex calc_size gem5 profile clean

# Final Project Instructions
P0 := $(ROOT)testcase/public/testcase_00.txt $(ROOT)answer/public/answer_00.txt
P1 := $(ROOT)testcase/public/testcase_01.txt $(ROOT)answer/public/answer_01.txt
P2 := $(ROOT)testcase/public/testcase_02.txt $(ROOT)answer/public/answer_02.txt
P3 := $(ROOT)testcase/public/testcase_03.txt $(ROOT)answer/public/answer_03.txt
P4 := $(ROOT)testcase/public/testcase_04.txt $(ROOT)answer/public/answer_04.txt
P5 := $(ROOT)testcase/public/testcase_05.txt $(ROOT)answer/public/answer_05.txt

# Compile C++ code with MCM assembly code
g++_final: $(CPP_SRC)
	$(CPP) $(ARCH_FLAGS) $(CPP_SRC) $(PROG_MCM) -o $(CPP_OUT) $(STATIC_FLAG)
	@echo "C++ code compiled to $(CPP_OUT)"

# Emulate the program on gem5 for testcases P0 to P5
gem5_public_all:
	@echo "eg: make gem5_public_all GEM5_ARGS="--l1i_size 1kB --l1i_assoc 2 --l1d_size 1kB --l1d_assoc 2 --l2_size 16kB --l2_assoc 4""
	@echo "Running gem5 simulation for all testcases"
	cd $(ENV_DIR); \
	rm -rf m5out_public; \
	for idx in 0 1 2 3 4 5; do \
		case $$idx in \
			0) param="$(P0)";; \
			1) param="$(P1)";; \
			2) param="$(P2)";; \
			3) param="$(P3)";; \
			4) param="$(P4)";; \
			5) param="$(P5)";; \
		esac; \
		# 'set --' splits the pair into positional parameters $$1 and $$2 \
		set -- $$param; \
		echo "Running gem5 with testcase: $$1 and answer: $$2"; \
		build/RISCV/gem5.opt --debug-flags=Exec --debug-file=out_exec_$$idx.txt \
			--outdir="$(ROOT)m5out_public" $(ROOT)final_config.py $(ROOT)$(PROG) $$1 $$2 $(GEM5_ARGS); \
	done; \

# Emulate the program on gem5 for single testcases
gem5_public:
	@echo "eg: make gem5_public ARGS="P0" GEM5_ARGS="--l1i_size 1kB --l1i_assoc 2 --l1d_size 1kB --l1d_assoc 2 --l2_size 16kB --l2_assoc 4""
	@echo "Running gem5 simulation for a single testcase"
	cd $(ENV_DIR); \
	case "$(ARGS)" in \
		P0) param="$(P0)"; idx=0;; \
		P1) param="$(P1)"; idx=1;; \
		P2) param="$(P2)"; idx=2;; \
		P3) param="$(P3)"; idx=3;; \
		P4) param="$(P4)"; idx=4;; \
		P5) param="$(P5)"; idx=5;; \
		*) echo "Invalid ARGS: $(ARGS). Use P0~P5"; exit 1;; \
	esac; \
	rm -rf m5out_public/out_exec_$$idx.txt; \
	set -- $$param; \
	echo "Running gem5 with testcase: $$1 and answer: $$2"; \
	build/RISCV/gem5.opt --debug-flags=Exec --debug-file=out_exec_$$idx.txt \
		--outdir="$(ROOT)m5out_public" $(ROOT)final_config.py $(ROOT)$(PROG) $$1 $$2 $(GEM5_ARGS);

testbench_public:
	@echo "Testbench executed"
	python3 testbench.py

score_public:
	@echo "Scoring with performance testcases"
	python3 score.py

# Clean up generated files
clean:
	rm -f $(PROG) $(HEX_OUT) $(ASM_OUT).o $(DP_ASM)
	rm -rf ./answer
	rm -rf ./m5out_public
	rm -rf ./m5out_private
	@echo "Cleaned up generated files"
