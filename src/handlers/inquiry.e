OPT MODULE
OPT EXPORT

MODULE '*/scsi/headers',
       '*/scsi/params',
       '*/listview/outlist'

ENUM AFLG_INQUIRY_SILENT=10, AFLG_INQUIRY_VERBOSE, AFLG_INQUIRY_PROBE, AFLG_INQUIRY_SERIAL, AFLG_CAPTURE

DEF global_devtype

/*
** This procedure handles the data returned from an inquiry command. It has
** three modes of operation depending on the value of aflag. These are full
** (for full inquiry), minimum (for probes) and silent for passing the device
** type to the mode sense handler
*/
PROC process_inquiry(device:PTR TO CHAR, unit, reply:PTR TO inquiry, aflg)
DEF devtypestr[40]:STRING, buildstr[99]:STRING, vendor[8]:STRING,
    product[16]:STRING, revision[4]:STRING, devtype=0

    devtype:=(reply.peripheral AND %00011111)
    global_devtype:=devtype

    SELECT devtype
        CASE DEV_DIRECT
            StrCopy(devtypestr, 'DIRECT ACCESS (eg Disk)')
        CASE DEV_SEQUENTIAL
            StrCopy(devtypestr, 'SEQUENTIAL ACCESS (eg Tape)')
        CASE DEV_PRINTER
            StrCopy(devtypestr, 'PRINTER')
        CASE DEV_PROCESSOR
            StrCopy(devtypestr, 'PROCESSOR')
        CASE DEV_WRITEONCE
            StrCopy(devtypestr, 'WRITE-ONCE (eg Optical Disc)')
        CASE DEV_CDROM
            StrCopy(devtypestr, 'CD-ROM')
        CASE DEV_SCANNER
            StrCopy(devtypestr, 'SCANNER')
        CASE DEV_OPTICAL
            StrCopy(devtypestr, 'OPTICAL MEMORY')
        CASE DEV_CHANGER
            StrCopy(devtypestr, 'MEDIUM CHANGER (eg Jukebox)')
        CASE DEV_COMMS
            StrCopy(devtypestr, 'COMMUNICATIONS')
        DEFAULT
            StrCopy(devtypestr, 'UNKNOWN')
    ENDSELECT

    MidStr(vendor, reply, 8, 7)
    MidStr(product, reply, 16, 16)
    MidStr(revision, reply, 32, 4)

    IF aflg=AFLG_INQUIRY_PROBE
        StringF(buildstr, '\s \s \s :\s', vendor, product, revision, devtypestr)
        outlist_d(buildstr, device, unit)
    ELSEIF aflg=AFLG_INQUIRY_VERBOSE
        outlist('\ebDriver:\en', device)
        outlist_i('\ebUnit:\en', unit, NIL)
        outlist('\ebVendor:\en', vendor)
        outlist('\ebProduct:\en', product)
        outlist('\ebRevision:\en', revision)
        outlist('\ebType:\en', devtypestr)
        IF (reply.rmb AND %10000000) = 128 THEN outlist('\ebRemovable Media:\en:', 'Yes') ELSE outlist('\ebRemovable Media:\en:', 'No')
        outlist_i('\ebVendor Type Modifier:\en', (reply.rmb AND %01111111), NIL)
        outlist_i('\ebISO Version:\en', (reply.versions AND %11000000), NIL)
        outlist_i('\ebECMA Version:\en', (reply.versions AND %00111000), NIL )
        outlist_i('\ebANSI Version:\en', (reply.versions AND %00000111), ' (SCSI Version)')
        IF (reply.aenc AND %10000000) = 128 THEN outlist('\ebAENC Support:\en', 'Yes') ELSE outlist('\ebAENC Support:\en', 'No')
        IF (reply.aenc AND %01000000) = 64 THEN outlist('\ebTrmIOP Support:\en', 'Yes') ELSE outlist('\ebTrmIOP Support:\en', 'No')
        IF (reply.width AND %10000000) = 128 THEN outlist('\ebRelative Addressing:\en', 'Yes') ELSE outlist('\ebRelative Addressing:\en', 'No')
        IF (reply.width AND %01000000) = 64 THEN outlist('\eb32bit Support:\en', 'Yes') ELSE outlist('\eb32bit Support:\en', 'No')
        IF (reply.width  AND %00100000) = 32 THEN outlist('\eb16bit Support\en', 'Yes') ELSE outlist('\eb16bit Support\en', 'No')
        outlist('\eb8bit Support\en', 'Yes')
        IF (reply.width AND %00010000) = 16 THEN outlist('\ebSynchronous Support:\en', 'Yes') ELSE outlist('\ebSynchronous Support:\en', 'No')
        IF (reply.width AND %00001000) = 8 THEN outlist('\ebLinked Support:\en', 'Yes') ELSE outlist('\ebLinked Support:\en', 'No')
        IF (reply.width AND %00000010) = 2 THEN outlist('\ebCommand Queuing Support:\en', 'Yes') ELSE outlist('\ebCommand Queuing Support:\en', 'No')
        IF (reply.width AND %00000001) = 1 THEN outlist('\ebSupported Reset Type:\en', 'Soft') ELSE outlist('\ebSupported Reset Type:\en', 'Hard')
    ENDIF
ENDPROC


/*
** This procedure handles the data returned from an inquiry command, requesting
** vital page $80 (product serial number). It includes a limited amount of
** fallback as some buggy devices return the wrong page.
*/
PROC process_serial(reply:PTR TO r_serial)
DEF serial[100]:STRING, i=0, str[255]:STRING

    outlist_h('\ebPage Code\en', reply.code, NIL)
    outlist_i('\ebPage Length\en', reply.length, NIL)

    SELECT $FF OF reply.code
        CASE $0
            FOR i:=0 TO (reply.length-1)
            outlist_h('\ebKnown Page:\en', Char(reply+4+i), NIL)
            ENDFOR
        CASE $1 TO $7F
            outlist_i('\ebASCII Length:\en', Char(reply+4), NIL)
            StrCopy(str, (reply+5), Min(Char(reply+4), 255))
            outlist('\ebText:\en', str)
        CASE $80
            StrCopy(serial, (reply+4), Min(reply.length, 100))
            outlist('\ebSerial Number:\en', serial)
        CASE $81
            outlist('\ebOperating Definitions:\en', ' ')
        CASE $82
            outlist('\ebASCII Operating Definition:\en', ' ')
        CASE $83 TO $EF
            outlist('\ebVendor Specific Page:\en', ' ')
        DEFAULT
            outlist('\ebUnknown Page:\en', ' ')
    ENDSELECT
ENDPROC
