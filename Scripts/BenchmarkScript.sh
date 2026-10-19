#!/bin/bash

#btw, this only is meant for linux, don't try it on windows unless you know how to modify and configure this stuff

# "having bash script run itself with sudo priviledges"
# Check if the script is running as root; if not, re-execute itself with sudo
[ "$EUID" -ne 0 ] && exec sudo "$0" "$@"

#Environmental setup, for reproducibility:

#What I will vs will not do:

#What I will do:
#1.) Disable Turbo Boost --> Increases throughput+latency consistency
#2.) Lock the Frequency --> Increases throughput+latency consistency
#3.) Disable C states (besides C0, which will run 100% of the time) --> Reduces jitter and performance dips

#What I will not do: (not really needed, as it isn't going to effect the results for this project as much as the previous ones)
#1.) Core Isolation (especially to 1 core)
#2.) Disable SMT/Hyper Threading

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
#DIR='/dev/nvme1n1p4'

#mount your partition
#sudo mount DIR /mnt/testpart

#First, go to your root (if your partition is)
#sudo mkdir -p "/mnt/testpart/test"
#sudo fallocate -l 12G "/mnt/testpart/test/fio.dat" #allocates 12GiB file for fio testing
#filedirectory="/mnt/testpart/test/fio.dat" #you will use this in your .fio jobfiles

DIR='/home/timrota/AdvancedComputerSystemsProjects/ClasswideProjects/Project3SSD'
sudo mkdir -p "$DIR/TestData"

#only allocate the file if it does NOT already exist
if [ ! -f "$DIR/testfile/fio.dat"]; then
    echo "Allocating FIO test file at $DIR/TestData/"
    sudo fallocate -l 12G "$DIR/TestData/fio.dat"
else
    echo "FIO test file already exists at $DIR/TestData/fio.dat - skipping allocation"
fi
filedirectory="$DIR/TestData/fio.dat"

touch ZeroQueueBaselines.json
touch BlockSizeSweep.json
touch ReadWriteMixSweep.json
touch QueueDepthParallelismSweep.json
touch TailLatencyCharacterization.json
touch WorkingSetLBARangeDeviceStateNote.json
touch MisleadingSetup.json

> ZeroQueueBaselines.json
> BlockSizeSweep.json
> ReadWriteMixSweep.json
> QueueDepthParallelismSweep.json
> TailLatencyCharacterization.json
> WorkingSetLBARangeDeviceStateNote.json
> MisleadingSetup.json

#Now benchmark time

#1.) Zero-Queue Baselines: QD=1 latency for 4KiB random read/write and 128KiB sequential read/write; include p95/p99
echo "1.) Zero-Queue Baselines: Running..."
fio ZeroQueueBaselines.fio --filename="$filedirectory" --output-format=json >> ZeroQueueBaselines.json
#2.) Block-Size Sweep: Throughput and latency from the same runs for random and sequential patterns
echo "2.) Block-Size Sweep: Running..."
fio BlockSizeSweep.fio --filename="$filedirectory" --output-format=json >> BlockSizeSweep.json
#3.) Read/write mix sweep under fixed block size and pattern
echo "3.) Read/Write Mix Sweep: Running..."
fio ReadWriteMixSweep.fio --filename="$filedirectory" --output-format=json >> ReadWriteMixSweep.json
#4.) Queue-Depth/Parallelism Sweep: Single throughput-vs-latency curve, knee identification, and Little's Law discussion
echo "4.) Queue-Depth/Parallelism Sweep: Running..."
fio QueueDepthParallelismSweep.fio --filename="$filedirectory" --output-format=json >> QueueDepthParallelismSweep.json
#5.) Tail-latency characterization at mid-QD and near-knee QD
echo "5.) Tail-latency Characterization: Running..."
fio TailLatencyCharacterization.fio --filename="$filedirectory" --output-format=json >> TailLatencyCharacterization.json
#6.) Working-Set/LBA-Range and Device-State note: Discuss burst vs. steady-state if observable
echo "6.) Working-Set/LBA-Range and Device-State: Running..."
fio WorkingSetLBARangeDeviceStateNote.fio --filename="$filedirectory" --output-format=json >> WorkingSetLBARangeDeviceStateNote.json
#7.) Demonstrate or explain one misleading setup, such as buffered I/O /page-cache effects, wrong effective queue depth, insufficient preconditioning, or thermal throttling
echo "7.) Misleading Results: Running... (Optional)"
fio MisleadingSetup.fio --filename="$filedirectory" --output-format=json >> MisleadingSetup.json


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
