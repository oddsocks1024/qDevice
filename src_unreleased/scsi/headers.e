OPT MODULE

/*
** Structures for the SCSI Command Descriptor Block, the actual field meanings
** vary depending on the command being sent, which makes it difficult to give
** the fields descriptive names.
*/

-> Structure for 6 byte commands
EXPORT OBJECT cdb6
opcode:CHAR
param1:CHAR
param2:CHAR
param3:CHAR
param4:CHAR
control:CHAR
ENDOBJECT

-> Structure for 10 byte commands
EXPORT OBJECT cdb10
opcode:CHAR
param1:CHAR
param2:CHAR
param3:CHAR
param4:CHAR
param5:CHAR
param6:CHAR
param7:CHAR
param8:CHAR
control:CHAR
ENDOBJECT

->Structure for 12byte commands
EXPORT OBJECT cdb12
opcode:CHAR
param1:CHAR
param2:CHAR
param3:CHAR
param4:CHAR
param5:CHAR
param6:CHAR
param7:CHAR
param8:CHAR
param9:CHAR
param10:CHAR
control:CHAR
ENDOBJECT


/*
** Various headers which are used to process the results from a query
*/

-> Inquiry reply header
EXPORT OBJECT inquiry
peripheral:CHAR
rmb:CHAR
versions:CHAR
aenc:CHAR
additional:CHAR
reserved1:CHAR
reserved2:CHAR
width:CHAR
ENDOBJECT

-> Reply header to requesting serial number (Vital Page $80)
EXPORT OBJECT r_serial
peripheral:CHAR
code:CHAR
reserved:CHAR
length:CHAR
ENDOBJECT

-> CD Table of contents reply header
EXPORT OBJECT toc
datalen:INT
firsttrack:CHAR
lasttrack:CHAR
ENDOBJECT

-> CD Table of contents reply descriptor
EXPORT OBJECT toc_d
reserved:CHAR
adr_ctrl:CHAR
track:CHAR
reserved2:CHAR
addr:LONG
ENDOBJECT

-> Capacity reply header
EXPORT OBJECT capacity
blocks:LONG
bsize:LONG
ENDOBJECT

-> Request sense reply header
EXPORT OBJECT r_sense
errcode:CHAR
segment:CHAR
sensekey:CHAR
info:LONG
senselen:CHAR
cmdinfo:LONG
sensecode:CHAR
sensequal:CHAR
unitcode:CHAR
sksv:CHAR
keyspec:INT
ENDOBJECT

-> Main header for a 6 byte mode sense response
EXPORT OBJECT m_sense6
datalen:CHAR
medium:CHAR
devpar:CHAR
desclen:CHAR
ENDOBJECT

-> Main header for a 10 byte mode sense response
EXPORT OBJECT m_sense10
datalen:INT
medium:CHAR
devpar:CHAR
reserved:INT
desclen:INT
ENDOBJECT

-> BLOCK descriptor
EXPORT OBJECT b_descriptor
blocks:LONG
blocklen:LONG
ENDOBJECT

-> Main header for a log sense response
EXPORT OBJECT l_sense
code:CHAR
reserved:CHAR
len:INT
ENDOBJECT

-> Main header for a log sense ERROR parameter
EXPORT OBJECT l_param
pcode1:CHAR     -> Note the pcode is really a 16bit value, but I've split it
pcode2:CHAR     -> into two bytes (for easier coding) because we NEVER need
pcb:CHAR        -> to consult the first byte
len:CHAR
ENDOBJECT

-> Header for log parameter codes (pcode split for convenience)
EXPORT OBJECT log_param_type_1
pcode1:CHAR
pcode2:CHAR
pcb:CHAR
len:CHAR
ENDOBJECT

-> Header for log parameter codes (pcode NOT split)
EXPORT OBJECT log_param_type_2
pcode:INT
pcb:CHAR
len:CHAR
ENDOBJECT

-> Main header for an ATIP reply
EXPORT OBJECT r_atip
atiplen:INT
reserved:INT
itwp:CHAR
disctype:CHAR
reserved2:CHAR
startmin:CHAR
startsec:CHAR
startframe:CHAR
reserved3:CHAR
endmin:CHAR
endsec:CHAR
endframe:CHAR
ENDOBJECT


-> Main Header for a defect list
EXPORT OBJECT d_list
reserved:CHAR
lists:CHAR
defectlistsize:INT
ENDOBJECT


->Defect List Physical Sector Format
EXPORT OBJECT d_list_psf
cylinders:LONG
sector:LONG
ENDOBJECT

->Feature header for get configuration
EXPORT OBJECT featurehdr
datalen:LONG
reserved:INT
profile:INT
ENDOBJECT

->Feature Descriptor
EXPORT OBJECT featuredesc
code:INT
version:CHAR
len:CHAR
ENDOBJECT

->Profile Descriptor
EXPORT OBJECT profdesc
num:INT
current:CHAR
reserved:CHAR
ENDOBJECT

