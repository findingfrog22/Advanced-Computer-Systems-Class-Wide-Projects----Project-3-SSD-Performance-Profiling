#!/bin/bash

#btw, this only is meant for linux, don't try it on windows unless you know how to modify and configure this stuff

# "having bash script run itself with sudo priviledges"
# Check if the script is running as root; if not, re-execute itself with sudo
[ "$EUID" -ne 0 ] && exec sudo "$0" "$@"

#Environmental setup, for reproducibility:

#What I will vs will not do:
# - I had to make compromises to ensure that Intel MLC could work, while trying to be as consistent as I can
#What I will do:
#1.) Disable Turbo Boost --> Increases throughput+latency consistency
#2.) Lock the Frequency --> Increases throughput+latency consistency
#3.) Disable C states (besides C0, which will run 100% of the time) --> Reduces jitter and performance dips

#What I will not do: (mainly due to Intel MLC Quirks)
#1.) Core Isolation (especially to 1 core) --> Intel MLC likes to use all cores for latency and bandwidth
#2.) Disable SMT/Hyper Threading --> Intel MLC handles thread mapping with SMT/Hyperthreading, disabling it throws of HWID indexing

#set intel pstate to passive mode, allows for direct frequency change instead of preset governors
echo passive | tee /sys/devices/system/cpu/intel_pstate/status

#Setting governor to userspace (allows for direct frequency locking)
cpupower frequency-set -g userspace #this sets all cores to userspace mode, which allows for pinning exact frequency



#First, Disable Turbo Boost
echo 1 | tee /sys/devices/system/cpu/intel_pstate/no_turbo #this disables turbo boost on all cores

#Then, Disable C states
cpupower idle-set -D 0 #forces C0 active state by limiting it to 0 microseconds allowed in sleep state

#Finally, lock the frequency to 1.40GHz
cpupower frequency-set -f 1400MHz #this sets all cores to 1.4GHz (unit is in KHz by default)
# Clear explicit frequency constraints
cpupower frequency-set -d 1400MHz #sets lower frequency minimum
cpupower frequency-set -u 1400MHz #sets max frequency
cpupower frequency-info #this prints out the current frequency info for all cores, which should now be in userspace mode
#cpupower -c 0 monitor

#Config, here is your partition directory
DIR='/dev/nvme1n1p4'

#First, go to your root (if your partition is)
sudo fallocate -l 12G "$DIR/fio.dat" #allocates 12GiB file for fio testing
filedirectory="$DIR/fio.dat" #you will use this in your .fio jobfiles

#Now benchmark time

#1.) Zero-Queue Baselines: QD=1 latency for 4KiB random read/write and 128KiB sequential read/write; include p95/p99
fio ZeroQueueBaselines.fio --filename="$filedirectory" --output-format=json
#2.) Block-Size Sweep: Throughput and latency from the same runs for random and sequential patterns
fio BlockSizeSweep.fio --filename="$filedirectory" --output-format=json
#3.) Read/write mix sweep under fixed block size and pattern
fio ReadWriteMixSweep.fio --filename="$filedirectory" --output-format=json
#4.) Queue-Depth/Parallelism Sweep: Single throughput-vs-latency curve, knee identification, and Little's Law discussion
fio QueueDepthParallelismSweep.fio --filename="$filedirectory" --output-format=json
#5.) Tail-latency characterization at mid-QD and near-knee QD
fio TailLatencyCharacterization.fio --filename="$filedirectory" --output-format=json
#6.) Working-Set/LBA-Range and Device-State note: Discuss burst vs. steady-state if observable
fio WorkingSetLBARangeDeviceStateNote.fio --filename="$filedirectory" --output-format=json
#7.) Demonstrate or explain one misleading setup, such as buffered I/O /page-cache effects, wrong effective queue depth, insufficient preconditioning, or thermal throttling
fio MisleadingSetup.fio --filename="$filedirectory" --output-format=json

#NOTE: how to compile and run properly: gcc project2cache.cpp -lstdc++ -o project2cache.exe
#that -lstdc++ is what causes the linker for the libraries to work
#NOTE: you must also run this with sudo or else the perf benchmark counters won't work


#undoing the testing environment to return the system back to normal config
#puts intel pstate back to active mode, which allows for dynamic frequency scaling
echo active | tee /sys/devices/system/cpu/intel_pstate/status
cpupower frequency-set -g powersave
# Clear explicit frequency constraints
#cpupower frequency-set -u 100% -d 0% #this is redundant due to the change in governor
# 1. Re-enable C-states and clear latency constraints
cpupower idle-set -D 0ms
cpupower idle-set -E
#re-enable turbo boost
echo 0 | tee /sys/devices/system/cpu/intel_pstate/no_turbo
#then restart your computer to undo the rest
