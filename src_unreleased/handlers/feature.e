OPT MODULE
OPT EXPORT

MODULE '*/listview/outlist',
       '*/scsi/headers',
       '*/scsi/params'


PROC process_feature(reply:PTR TO featurehdr)
DEF ftrd:PTR TO featuredesc


    outlist_i('\ebFeature Data Length:\en', reply.datalen, ' bytes')

    IF reply.profile = 0
        outlist('\ebCurrent Profile:\en', 'No Current Profile')
    ELSEIF reply.profile = $2
        outlist('\ebCurrent Profile:\en', 'Removable Disk')
    ELSEIF reply.profile= $8
        outlist('\ebCurrent Profile:\en', 'CD-ROM')
    ELSEIF reply.profile= $10
        outlist('\ebCurrent Profile:\en', 'DVD-ROM')
    ELSEIF reply.profile= $12
        outlist('\ebCurrent Profile:\en', 'DVD-RAM')
    ELSE
        outlist_i('\ebCurrent Profile:\en', reply.profile, '(unknown)')
    ENDIF

    outlist(' ', ' ')

    ftrd:=reply + SIZEOF featurehdr

    WHILE ftrd < (reply + SIZEOF featurehdr + reply.datalen - 4)
        ->outlist_i('ftrd', ftrd, NIL)
        ->outlist_i('arse', reply + SIZEOF featurehdr + reply.datalen, NIL)
        outlist_h('\ebFeature Code:\en', ftrd.code, NIL)
        outlist_i('\ebFeature Version:\en', ftrd.version, NIL)
        outlist_i('\ebLength:\en', ftrd.len, ' bytes')

        SELECT  ftrd.code
            CASE $0
                process_feature0(ftrd)
            CASE $1
                process_feature1(ftrd)
            CASE $3
                process_feature3(ftrd)
            CASE $10
                process_feature10(ftrd)
            CASE $1F
                process_feature1F(ftrd)
            CASE $20
                process_feature20(ftrd)
            CASE $23
                process_feature23(ftrd)
            CASE $24
                process_feature24(ftrd)
            CASE $100
                process_feature100(ftrd)
            CASE $101
                process_feature101(ftrd)
            DEFAULT
                outlist(' ', 'Feature code not yet supported')

        ENDSELECT


        outlist(' ', ' ')
        ftrd:=ftrd + SIZEOF featuredesc + ftrd.len

    ENDWHILE

    ->IF ftrd.code = 0

    ->ELSE
    ->    outlist_i('\eb Feature Code:\en', ftrd.code, 'Not Supported Yet')
    ->    outlist(' ', ' ')
    ->ENDIF

ENDPROC

PROC process_feature0(feature)

ENDPROC

PROC process_feature1(feature)

ENDPROC

PROC process_feature3(feature)

ENDPROC

PROC process_feature10(feature)

ENDPROC

PROC process_feature1F(feature)

ENDPROC

PROC process_feature20(feature)

ENDPROC

PROC process_feature23(feature)

ENDPROC

PROC process_feature24(feature)

ENDPROC

PROC process_feature100(feature)

ENDPROC

PROC process_feature101(feature)

ENDPROC
