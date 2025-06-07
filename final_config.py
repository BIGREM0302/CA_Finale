import m5
from m5.objects import *
import argparse
import os

parser = argparse.ArgumentParser()

# Program binary
parser.add_argument("binary", help="Binary to run")
parser.add_argument("bin_args", nargs='*', help="Arguments for the binary")

# ------------------------ CPU Type ------------------------
parser.add_argument("--isa_type", type=int, default=32, choices=[32, 64], help="ISA type (32 or 64)")

# ------------------- L1 Cache Arguments -------------------
parser.add_argument("--l1i_size", type=str, default="4kB",
                    help="L1 instruction cache size")
parser.add_argument("--l1d_size", type=str, default="4kB",
                    help="L1 data cache size")

parser.add_argument("--l1i_assoc", type=int, default=2,
                    help="L1 instruction cache associativity")
parser.add_argument("--l1d_assoc", type=int, default=2,
                    help="L1 data cache associativity")

parser.add_argument("--l1i_tag_latency", type=int, default=2,
                    help="L1 instruction cache tag latency (cycles)")
parser.add_argument("--l1i_data_latency", type=int, default=2,
                    help="L1 instruction cache data latency (cycles)")
parser.add_argument("--l1i_response_latency", type=int, default=2,
                    help="L1 instruction cache response latency (cycles)")

parser.add_argument("--l1d_tag_latency", type=int, default=2,
                    help="L1 data cache tag latency (cycles)")
parser.add_argument("--l1d_data_latency", type=int, default=2,
                    help="L1 data cache data latency (cycles)")
parser.add_argument("--l1d_response_latency", type=int, default=2,
                    help="L1 data cache response latency (cycles)")

# ------------------- L2 Cache Arguments -------------------
parser.add_argument("--l2_size",  type=str, default="64kB",
                    help="L2 cache size")
parser.add_argument("--l2_assoc", type=int, default=8,
                    help="L2 cache associativity")

parser.add_argument("--l2_tag_latency", type=int, default=20,
                    help="L2 cache tag latency (cycles)")
parser.add_argument("--l2_data_latency", type=int, default=20,
                    help="L2 cache data latency (cycles)")
parser.add_argument("--l2_response_latency", type=int, default=20,
                    help="L2 cache response latency (cycles)")

args = parser.parse_args()

# Create the system
system = System()

system.clk_domain = SrcClockDomain()
system.clk_domain.clock = "1GHz"
system.clk_domain.voltage_domain = VoltageDomain()

system.mem_mode = "timing"
system.mem_ranges = [AddrRange("512MiB")]

# Create a simple CPU
system.cpu = RiscvTimingSimpleCPU()

if args.isa_type == 32:
    system.cpu.isa = RiscvISA(riscv_type="RV32")
    print("ISA type: 32 bit RISC-V")
else:
    print("ISA type: 64 bit RISC-V")

# The main memory bus
system.membus = SystemXBar()

#
# ------------ L1 and L2 caches ------------
#

# -- L1 Instruction Cache --
system.l1icache = Cache(
    clk_domain = system.clk_domain,
    size = args.l1i_size,
    assoc = args.l1i_assoc,
    tag_latency = args.l1i_tag_latency,
    data_latency = args.l1i_data_latency,
    response_latency = args.l1i_response_latency,
    mshrs = 4,
    tgts_per_mshr = 20
)

# -- L1 Data Cache --
system.l1dcache = Cache(
    clk_domain = system.clk_domain,
    size = args.l1d_size,
    assoc = args.l1d_assoc,
    tag_latency = args.l1d_tag_latency,
    data_latency = args.l1d_data_latency,
    response_latency = args.l1d_response_latency,
    mshrs = 4,
    tgts_per_mshr = 20
)

# Create a (small) L2 bus to connect L1s and L2
system.l2bus = L2XBar()

# -- L2 Unified Cache --
system.l2cache = Cache(
    clk_domain = system.clk_domain,
    size = args.l2_size,
    assoc = args.l2_assoc,
    tag_latency = args.l2_tag_latency,
    data_latency = args.l2_data_latency,
    response_latency = args.l2_response_latency,
    mshrs = 20,
    tgts_per_mshr = 12
)

# Connect L1 <-> CPU
system.cpu.icache_port = system.l1icache.cpu_side
system.cpu.dcache_port = system.l1dcache.cpu_side

# Corrected: Connect L1 caches to L2 bus
system.l1icache.mem_side = system.l2bus.cpu_side_ports
system.l1dcache.mem_side = system.l2bus.cpu_side_ports

# Corrected: Connect L2 cache to L2 bus & membus
system.l2cache.cpu_side = system.l2bus.mem_side_ports
system.l2cache.mem_side = system.membus.cpu_side_ports

#
# -----------------------------------------
#

# Interrupt controller for the CPU
system.cpu.createInterruptController()

# Create DDR3 memory controller
system.mem_ctrl = MemCtrl()
system.mem_ctrl.dram = DDR3_1600_8x8()
system.mem_ctrl.dram.range = system.mem_ranges[0]
system.mem_ctrl.port = system.membus.mem_side_ports

# System port (allows kernel stats, etc.)
system.system_port = system.membus.cpu_side_ports

# Workload
system.workload = SEWorkload.init_compatible(args.binary)

# Create a Process for the binary
process = Process()
# process.cmd = [args.binary]
process.cmd = [args.binary] + args.bin_args
system.cpu.workload = process
system.cpu.createThreads()

# Instantiate root and begin simulation
root = Root(full_system=False, system=system)
m5.instantiate()

print("Beginning simulation!")
exit_event = m5.simulate()
print(f"Exiting @ tick {m5.curTick()} because {exit_event.getCause()}")
