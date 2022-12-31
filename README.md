# Q-Device!
## Summary

Q-Device! is a graphical tool for querying and controlling IDE and SCSI devices
attached to the Commodore Amiga. These devices contain pages of information
that describe the device's features, modes of operation and diagnostic status.
In many cases these pages are configurable to allow the user or the
manufacturer to tweak the device's operation. Q-Device! is capable of decoding
much of this information and presenting it to the user.

- GUI based upon the MUI toolkit
- Device probing - scans the SCSI/IDE bus for active devices
- Device inquiry - Product, Vendor, Revision, Type, RMB Info, ISO, ECMA and ANSI versions, AENC, TrmIOP, Relative Addressing, Bus Width, Synchronous, Linked, Command Queuing and Reset Type
- Device capacity - Number of Blocks, Block Size, True Capacity and Vendor Capacity
- Product serial number retrieval
- Media ejection and insertion
- Power up/down devices
- Locking and unlocking for removable media devices
- Rewind/Rezero for tape devices
- Unit readiness test
- Read CD Table of Contents - Starting Track, Ending Track, Track Type, Track Copyright, Audio Channels, Audio Emphasis
- Device self diagnostic tests - Simple 1 & 2 and Deep 1 & 2
- Media defect discovery
- Device parameter page decoding (54 supported page types)
- Firmware log decoding (33 recognised types, 13 decodable)
- Basic ATIP support


Originally written under a custom licence, Q-Device! is now available under
the GPL v2, which supercedes any previous licencing.

## Misc

- Initial Release: Circa 2003
- Last Update: 2005
- Language: Amiga E and C
- OS: AmigaOS (qdd component Linux, Solaris, IRIX)
