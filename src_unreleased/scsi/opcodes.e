OPT MODULE


-> All SCSI Devices
EXPORT CONST
    SCSI_CHANGE_DEFINITION                = $40,
    SCSI_COMPARE                          = $39,
    SCSI_COPY                             = $18,
    SCSI_COPY_AND_VERIFY                  = $3a,
    SCSI_INQUIRY                          = $12,
    SCSI_LOG_SELECT                       = $4c,
    SCSI_LOG_SENSE                        = $4d,
    SCSI_MODE_SELECT_6                    = $15,
    SCSI_MODE_SELECT_10                   = $55,
    SCSI_MODE_SENSE_6                     = $1a,
    SCSI_MODE_SENSE_10                    = $5a,
    SCSI_READ_BUFFER                      = $3c,
    SCSI_RECEIVE_DIAGNOSTIC_RESULTS       = $1c,
    SCSI_REQUEST_SENSE                    = $03,
    SCSI_SEND_DIAGNOSTIC                  = $1d,
    SCSI_TEST_UNIT_READY                  = $00,
    SCSI_WRITE_BUFFER                     = $3b,
    SCSI_GET_CONFIG                       = $46

-> Direct Access Devices
EXPORT CONST
    SCSI_DA_FORMAT_UNIT                   = $04,
    SCSI_DA_LOCK_UNLOCK_CACHE             = $36,
    SCSI_DA_PRE_FETCH                     = $34,
    SCSI_DA_PREVENT_ALLOW_MEDIUM_REMOVAL  = $1e,
    SCSI_DA_READ_6                        = $08,
    SCSI_DA_READ_10                       = $28,
    SCSI_DA_READ_CAPACITY                 = $25,
    SCSI_DA_READ_DEFECT_DATA              = $37,
    SCSI_DA_READ_LONG                     = $3e,
    SCSI_DA_REASSIGN_BLOCKS               = $07,
    SCSI_DA_RECEIVE_DIAGNOSTIC_RESULTS    = $1c,
    SCSI_DA_RELEASE                       = $17,
    SCSI_DA_RESERVE                       = $16,
    SCSI_DA_REZERO_UNIT                   = $01,
    SCSI_DA_SEARCH_DATA_EQUAL             = $31,
    SCSI_DA_SEARCH_DATA_HIGH              = $30,
    SCSI_DA_SEARCH_DATA_LOW               = $32,
    SCSI_DA_SEEK_6                        = $0b,
    SCSI_DA_SEEK_10                       = $2b,
    SCSI_DA_SET_LIMITS                    = $33,
    SCSI_DA_START_STOP_UNIT               = $1b,
    SCSI_DA_SYNCHRONIZE_CACHE             = $35,
    SCSI_DA_VERIFY                        = $2f

-> Sequential Access Devices
EXPORT CONST
    SCSI_SA_ERASE                         = $19,
    SCSI_SA_LOAD_UNLOAD                   = $1b,
    SCSI_SA_LOCATE                        = $2b,
    SCSI_SA_PREVENT_ALLOW_MEDIUM_REMOVAL  = $1e,
    SCSI_SA_READ                          = $08,
    SCSI_SA_READ_BLOCK_LIMITS             = $05,
    SCSI_SA_READ_POSITION                 = $34,
    SCSI_SA_READ_REVERSE                  = $0f,
    SCSI_SA_RECEIVE_DIAGNOSTIC_RESULTS    = $1c,
    SCSI_SA_RECOVER_BUFFERED_DATA         = $14,
    SCSI_SA_RELEASE_UNIT                  = $17,
    SCSI_SA_RESERVE_UNIT                  = $16,
    SCSI_SA_REWIND                        = $01,
    SCSI_SA_SPACE                         = $11,
    SCSI_SA_VERIFY                        = $13,
    SCSI_SA_WRITE                         = $0a,
    SCSI_SA_WRITE_FILEMARKS               = $10

-> Printer Devices
EXPORT CONST
    SCSI_PRT_FORMAT                       = $04,
    SCSI_PRT_PRINT                        = $0a,
    SCSI_PRT_RECEIVE_DIAGNOSTIC_RESULTS   = $1c,
    SCSI_PRT_RECOVER_BUFFERED_DATA        = $14,
    SCSI_PRT_RELEASE_UNIT                 = $17,
    SCSI_PRT_RESERVE_UNIT                 = $16,
    SCSI_PRT_SLEW_AND_PRINT               = $0b,
    SCSI_PRT_STOP_PRINT                   = $1b,
    SCSI_PRT_SYNCHRONIZE_BUFFER           = $10

-> Processor Devices
EXPORT CONST
    SCSI_CPU_RECEIVE                      = $08,
    SCSI_CPU_RECEIVE_DIAGNOSTIC_RESULTS   = $1c,
    SCSI_CPU_SEND                         = $0a

-> Write Once Devices
EXPORT CONST
    SCSI_WO_LOCK_UNLOCK_CACHE             = $36,
    SCSI_WO_LOG_SELECT                    = $4c,
    SCSI_WO_LOG_SENSE                     = $4d,
    SCSI_WO_MEDIUM_SCAN                   = $38,
    SCSI_WO_MODE_SELECT_6                 = $15,
    SCSI_WO_MODE_SELECT_10                = $55,
    SCSI_WO_MODE_SENSE_6                  = $1a,
    SCSI_WO_MODE_SENSE_10                 = $5a,
    SCSI_WO_PRE_FETCH                     = $34,
    SCSI_WO_PREVENT_ALLOW_MEDIUM_REMOVAL  = $1e,
    SCSI_WO_READ_6                        = $08,
    SCSI_WO_READ_10                       = $28,
    SCSI_WO_READ_12                       = $a8,
    SCSI_WO_READ_CAPACITY                 = $25,
    SCSI_WO_READ_LONG                     = $3e,
    SCSI_WO_REASSIGN_BLOCKS               = $07,
    SCSI_WO_RECEIVE_DIAGNOSTIC_RESULTS    = $1c,
    SCSI_WO_RELEASE                       = $17,
    SCSI_WO_RESERVE                       = $16,
    SCSI_WO_REZERO_UNIT                   = $01,
    SCSI_WO_SEARCH_DATA_EQUAL_10          = $31,
    SCSI_WO_SEARCH_DATA_EQUAL_12          = $b1,
    SCSI_WO_SEARCH_DATA_HIGH_10           = $30,
    SCSI_WO_SEARCH_DATA_HIGH_12           = $b0,
    SCSI_WO_SEARCH_DATA_LOW_10            = $32,
    SCSI_WO_SEARCH_DATA_LOW_12            = $b2,
    SCSI_WO_SEEK_6                        = $0b,
    SCSI_WO_SEEK_10                       = $2b,
    SCSI_WO_SET_LIMITS_10                 = $33,
    SCSI_WO_SET_LIMITS_12                 = $b3,
    SCSI_WO_START_STOP_UNIT               = $1b,
    SCSI_WO_SYNCHRONIZE_CACHE             = $35,
    SCSI_WO_VERIFY_10                     = $2f,
    SCSI_WO_VERIFY_12                     = $af,
    SCSI_WO_WRITE_6                       = $0a,
    SCSI_WO_WRITE_10                      = $2a,
    SCSI_WO_WRITE_12                      = $aa,
    SCSI_WO_WRITE_AND_VERIFY_10           = $2e,
    SCSI_WO_WRITE_AND_VERIFY_12           = $ae,
    SCSI_WO_WRITE_LONG                    = $3f

-> CD-ROM Devices
EXPORT CONST
    SCSI_CD_LOCK_UNLOCK_CACHE             = $36,
    SCSI_CD_LOG_SELECT                    = $4c,
    SCSI_CD_LOG_SENSE                     = $4d,
    SCSI_CD_MODE_SELECT_6                 = $15,
    SCSI_CD_MODE_SELECT_10                = $55,
    SCSI_CD_MODE_SENSE_6                  = $1a,
    SCSI_CD_MODE_SENSE_10                 = $5a,
    SCSI_CD_PAUSE_RESUME                  = $4b,
    SCSI_CD_PLAY_AUDIO_10                 = $45,
    SCSI_CD_PLAY_AUDIO_12                 = $a5,
    SCSI_CD_PLAY_AUDIO_MSF                = $47,
    SCSI_CD_PLAY_AUDIO_TRACK_INDEX        = $48,
    SCSI_CD_PLAY_TRACK_RELATIVE_10        = $49,
    SCSI_CD_PLAY_TRACK_RELATIVE_12        = $a9,
    SCSI_CD_PRE_FETCH                     = $34,
    SCSI_CD_PREVENT_ALLOW_MEDIUM_REMOVAL  = $1e,
    SCSI_CD_READ_6                        = $08,
    SCSI_CD_READ_10                       = $28,
    SCSI_CD_READ_12                       = $a8,
    SCSI_CD_READ_CD_ROM_CAPACITY          = $25,
    SCSI_CD_READ_HEADER                   = $44,
    SCSI_CD_READ_LONG                     = $3e,
    SCSI_CD_READ_SUB_CHANNEL              = $42,
    SCSI_CD_READ_TOC                      = $43,
    SCSI_CD_RECEIVE_DIAGNOSTIC_RESULT     = $1c,
    SCSI_CD_RELEASE                       = $17,
    SCSI_CD_RESERVE                       = $16,
    SCSI_CD_REZERO_UNIT                   = $01,
    SCSI_CD_SEARCH_DATA_EQUAL_10          = $31,
    SCSI_CD_SEARCH_DATA_EQUAL_12          = $b1,
    SCSI_CD_SEARCH_DATA_HIGH_10           = $30,
    SCSI_CD_SEARCH_DATA_HIGH_12           = $b0,
    SCSI_CD_SEARCH_DATA_LOW_10            = $32,
    SCSI_CD_SEARCH_DATA_LOW_12            = $b2,
    SCSI_CD_SEEK_6                        = $0b,
    SCSI_CD_SEEK_10                       = $2b,
    SCSI_CD_SET_LIMITS_10                 = $33,
    SCSI_CD_SET_LIMITS_12                 = $b3,
    SCSI_CD_START_STOP_UNIT               = $1b,
    SCSI_CD_SYNCHRONIZE_CACHE             = $35,
    SCSI_CD_VERIFY_10                     = $2f,
    SCSI_CD_VERIFY_12                     = $af

-> Scanner Devices
EXPORT CONST
    SCSI_SC_GET_DATA_BUFFER_STATUS        = $34,
    SCSI_SC_GET_WINDOW                    = $25,
    SCSI_SC_OBJECT_POSITION               = $31,
    SCSI_SC_READ                          = $28,
    SCSI_SC_RECEIVE_DIAGNOSTIC_RESULTS    = $1c,
    SCSI_SC_RELEASE_UNIT                  = $17,
    SCSI_SC_RESERVE_UNIT                  = $16,
    SCSI_SC_SCAN                          = $1b,
    SCSI_SC_SET_WINDOW                    = $24,
    SCSI_SC_SEND                          = $2a

-> Optical Memory Devices
EXPORT CONST
    SCSI_OM_ERASE_10                      = $2c,
    SCSI_OM_ERASE_12                      = $ac,
    SCSI_OM_FORMAT_UNIT                   = $04,
    SCSI_OM_LOCK_UNLOCK_CACHE             = $36,
    SCSI_OM_PRE_FETCH                     = $34,
    SCSI_OM_PREVENT_ALLOW_MEDIUM_REMOVAL  = $1e,
    SCSI_OM_READ_6                        = $08,
    SCSI_OM_READ_10                       = $28,
    SCSI_OM_READ_12                       = $a8,
    SCSI_OM_READ_CAPACITY                 = $25,
    SCSI_OM_READ_DEFECT_DATA_10           = $37,
    SCSI_OM_READ_DEFECT_DATA_12           = $b7,
    SCSI_OM_READ_GENERATION               = $29,
    SCSI_OM_READ_LONG                     = $3e,
    SCSI_OM_READ_UPDATED_BLOCK            = $2d,
    SCSI_OM_REASSIGN_BLOCKS               = $07,
    SCSI_OM_RECEIVE_DIAGNOSTIC_RESULTS    = $1c,
    SCSI_OM_RELEASE                       = $17,
    SCSI_OM_RESERVE                       = $16,
    SCSI_OM_REZERO_UNIT                   = $01,
    SCSI_OM_SEARCH_DATA_EQUAL_10          = $31,
    SCSI_OM_SEARCH_DATA_EQUAL_12          = $b1,
    SCSI_OM_SEARCH_DATA_HIGH_10           = $30,
    SCSI_OM_SEARCH_DATA_HIGH_12           = $b0,
    SCSI_OM_SEARCH_DATA_LOW_10            = $32,
    SCSI_OM_SEARCH_DATA_LOW_12            = $b2,
    SCSI_OM_SEEK_6                        = $0b,
    SCSI_OM_SEEK_10                       = $2b,
    SCSI_OM_SET_LIMITS_10                 = $33,
    SCSI_OM_SET_LIMITS_12                 = $b3,
    SCSI_OM_START_STOP_UNIT               = $1b,
    SCSI_OM_SYNCHRONIZE_CACHE             = $35,
    SCSI_OM_UPDATE_BLOCK                  = $3d,
    SCSI_OM_VERIFY_10                     = $2f,
    SCSI_OM_VERIFY_12                     = $af,
    SCSI_OM_WRITE_6                       = $0a,
    SCSI_OM_WRITE_10                      = $2a,
    SCSI_OM_WRITE_12                      = $aa,
    SCSI_OM_WRITE_AND_VERIFY_10           = $2e,
    SCSI_OM_WRITE_AND_VERIFY_12           = $ae,
    SCSI_OM_WRITE_LONG                    = $3f

-> Media Changer Devices
EXPORT CONST
    SCSI_MC_EXCHANGE_MEDIUM               = $a6,
    SCSI_MC_INITIALIZE_ELEMENT_STATUS     = $07,
    SCSI_MC_MOVE_MEDIUM                   = $a5,
    SCSI_MC_POSITION_TO_ELEMENT           = $2b,
    SCSI_MC_PREVENT_ALLOW_MEDIUM_REMOVAL  = $1e,
    SCSI_MC_READ_ELEMENT_STATUS           = $b8,
    SCSI_MC_RECEIVE_DIAGNOSTIC_RESULTS    = $1c,
    SCSI_MC_RELEASE                       = $17,
    SCSI_MC_REQUEST_VOLUME_ELEMENT_ADDRESS= $b5,
    SCSI_MC_RESERVE                       = $16,
    SCSI_MC_REZERO_UNIT                   = $01,
    SCSI_MC_SEND_VOLUME_TAG               = $b6

-> Communications Devices
EXPORT CONST
    SCSI_COM_GET_MESSAGE_6                = $08,
    SCSI_COM_GET_MESSAGE_10               = $28,
    SCSI_COM_GET_MESSAGE_12               = $a8,
    SCSI_COM_RECEIVE_DIAGNOSTIC_RESULTS   = $1c,
    SCSI_COM_SEND_MESSAGE_6               = $0a,
    SCSI_COM_SEND_MESSAGE_10              = $2a,
    SCSI_COM_SEND_MESSAGE_12              = $aa