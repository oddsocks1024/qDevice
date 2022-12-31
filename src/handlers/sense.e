OPT MODULE
OPT EXPORT

MODULE '*/listview/outlist',
       '*/scsi/headers'

/*
** This procedure handles the data returned from a request sense key query
*/
PROC process_sense(reply:PTR TO r_sense)

    SELECT $F OF (reply.sensekey AND %00001111)
        CASE $0
            outlist_h('\ebSense Key:\en', 0, ' : No Specific Sense Key Info Available')
        CASE $1
            outlist_h('\ebSense Key:\en', 1, ' : Command recovered successfully from error')
        CASE $2
            outlist_h('\ebSense Key:\en', 2, ' : Unit is not ready for commands')
        CASE $3
            outlist_h('\ebSense Key:\en', 3, ' : Medium Error. The medium may contain errors or defects.')
        CASE $4
            outlist_h('\ebSense Key:\en', 4, ' : DEVICE REPORTED HARDWARE FAILURE!!!')
        CASE $5
            outlist_h('\ebSense Key:\en', 5, ' : This device does not support that command')
        CASE $6
            outlist_h('\ebSense Key:\en', 6, ' : Unit Attention, possible media change in progress')
        CASE $7
            outlist_h('\ebSense Key:\en', 7, ' : Medium is write-protected')
        CASE $8
            outlist_h('\ebSense Key:\en', 8, ' : Attempt to read unformatted medium')
        CASE $9
            outlist_h('\ebSense Key:\en', 9, ' : Vendor specific sense key')
        CASE $A
            outlist_h('\ebSense Key:\en', 10, ' : Copy/Compare command aborted due to read/write error')
        CASE $B
            outlist_h('\ebSense Key:\en', 11, ' : Command was aborted by the device')
        CASE $C
            outlist_h('\ebSense Key:\en', 12, ' : Equal comparison satisfied')
        CASE $D
            outlist_h('\ebSense Key:\en', 13, ' : Volume Overflow')
        CASE $E
            outlist_h('\ebSense Key:\en', 14, ' : Miscompare')
        DEFAULT
            outlist_h('\ebSense Key:\en', 15, ' : Reserved Sense Key')
    ENDSELECT

    IF reply.sensecode > NIL
        outlist_h('\ebAdditional Sense Code:\en', reply.sensecode, NIL)
        outlist_h('\ebSense Code Qualifier:\en', reply.sensequal, NIL)
    ENDIF

ENDPROC
