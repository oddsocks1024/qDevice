OPT MODULE
OPT EXPORT

MODULE '*/listview/outlist',
       '*/scsi/headers'

PROC process_atip(reply:PTR TO r_atip)
    outlist_i('\ebATIP Data Length:\en', reply.atiplen, NIL)
    outlist_i('\ebIndicitive Writing Power:\en', (reply.itwp AND %11110000), NIL)
    outlist_i('\ebReference Speed:\en', (Char(reply+4) AND %00000111), NIL)
    IF (reply.disctype AND %01000000) = 64 THEN outlist('\ebDisc Type:\en', 'CD-RW') ELSE outlist('\ebDisc Type:\en', 'CD-R')
    outlist_i('\ebATIP Start Time of Lead-In',reply.startmin, ' minutes')
    outlist_i('\ebATIP Start Time of Lead-In',reply.startsec, ' seconds')
    outlist_i('\ebATIP Start Time of Lead-In',reply.startframe, ' frames')
    outlist_i('\ebATIP Start Time of Lead-Out',reply.endmin, ' minutes')
    outlist_i('\ebATIP Start Time of Lead-Out',reply.endsec, ' seconds')
    outlist_i('\ebATIP Start Time of Lead-Out',reply.endframe, ' frames')
ENDPROC
