# Advanced-Computer-Systems-Class-Wide-Projects----Project-3-SSD-Performance-Profiling

Measurement Discipline (System Configuration):
- System Specs:
- CPU: Intel Core i5 1135G7, 4c/8t, 400MHz-4.20GHz
- --> Turbo boost disabled via Intel P_State governor modifications
- RAM: 8GB LPDDR4X 4267MHz (Dual Channel)
- OS: Linux Debian Trixie 13.7.0
- Compiler/Tools:
- GCC 14.2.0 (Default with Debian 13)
- Governor: intel cpu_freq
- VSCode IDE
- FIO (version 3.39)
- TBD

Environment Specific Setup:
- All CPU cores were locked to 1.40GHz constant
- Turbo boost disabled
- SMT/Hyperthreading enabled
- Idle/Sleep C states disabled (100% Active C0 state)
- No core/thread pinning was used

Project-specific:
- Partition size: 32GiB (32,768MiB)
- Filesystem: EXFAT
- SSD Model: Intel H10 32GB+512GB (Optane 32GB (PCIe 3.0 x2) + QLC 512GB (PCIe 3.0 x2), M.2 NVMe)
- --> In RAID (Intel RST) mode, but Debian only uses the 512GB QLC part, and doesn't use the optane caching at all. Hence the tests are only performed on the QLC portion of the drive.
- Methodology: Will be using filesystem instead of RAW due to it being non-destructive

Pre-experiment Hypothesis:
- Random reads will be significantly worse than sequential reads. Larger block sizes increase fragmentation, increase garbage collection, and slow down performance of the SSD. Small block sizes benefit from caching when sequential but not random.

How to use:
- TBD

AI Use/Notes:
- TBD
