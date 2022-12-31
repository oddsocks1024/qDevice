OPT MODULE

-> Sub-parameters sent to the target
EXPORT CONST
    P_EJECT           = %00000010,
    P_INSERT          = %00000011,
    P_LOCK            = %00000001,
    P_UNLOCK          = %00000000,
    P_START           = %00000001,
    P_STOP            = %00000000,
    P_DIAG_SIMPLE1    = %00000100,
    P_DIAG_SIMPLE2    = %00010100,
    P_DIAG_COMPLEX1   = %00000111,
    P_DIAG_COMPLEX2   = %00010111,
    P_LOG_LIST        = %01000000,
    P_LOG_BUFFER      = %01000001, -> Log Page $1
    P_LOG_WRITE       = %01000010, -> Log Page $2
    P_LOG_READ        = %01000011, -> Log Page $3
    P_LOG_REVREAD     = %01000100, -> Log Page $4
    P_LOG_VERIFY      = %01000101, -> Log Page $5
    P_LOG_NMERRORS    = %01000110, -> Log Page $6
    P_LOG_EVENTS      = %01000111, -> Log Page $7
    P_LOG_TEMP        = %01001101, -> Log Page $D
    P_LOG_IE          = %01101111, -> Log Page $2F
    P_LOG_SMARTSENSE  = %01110000, -> Log Page $30 - Alternate 1
    P_LOG_PERFORMANCE = %01110000, -> Log Page $30 - Alternate 2
    P_LOG_PHYSICAL    = %01110010, -> Log Page $32
    P_LOG_LBA         = %01110011, -> Log Page $33
    P_LOG_CACHE       = %01110101, -> Log Page $35
    P_LOG_IBMTEMP     = %01110110, -> Log Page $36
    P_ALLPAGES        = $3F

-> Device Type Constants
EXPORT CONST
    DEV_DIRECT      = 0,
    DEV_SEQUENTIAL  = 1,
    DEV_PRINTER     = 2,
    DEV_PROCESSOR   = 3,
    DEV_WRITEONCE   = 4,
    DEV_CDROM       = 5,
    DEV_SCANNER     = 6,
    DEV_OPTICAL     = 7,
    DEV_CHANGER     = 8,
    DEV_COMMS       = 9
