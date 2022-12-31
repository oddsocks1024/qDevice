OPT MODULE
OPT EXPORT

MODULE '*/listview/outlist',
       '*/scsi/headers'

/*
** This procedure handles the data returned from a Read Table of Contents
** query
*/
PROC process_toc(reply:PTR TO toc)
DEF track:PTR TO toc_d, i

    outlist_i('\ebStarting Track:\eb', reply.firsttrack, NIL)
    outlist_i('\ebLast Track:\eb', reply.lasttrack, NIL)

    track:=reply + SIZEOF toc

    FOR i:=reply.firsttrack TO reply.lasttrack
        outlist(' ', ' ')
        outlist_i('\ebTrack Number:\en', track.track, NIL)
        IF (track.adr_ctrl AND %00000100)=0
            outlist('\ebType:\en', 'AUDIO')
            IF (track.adr_ctrl AND %00001000)=0 THEN outlist('\ebAudio Channels:\en', '2') ELSE outlist('\ebAudio Channels:\en', '4')
            IF (track.adr_ctrl AND %00000001)=0 THEN outlist('\ebEmphasis:\en', 'Audio IS pre-emphasised') ELSE outlist('\ebEmphasis:\en', 'Audio NOT pre-emphasised')
        ELSE
            outlist('\ebTrack Type:\en', 'DATA')
        ENDIF
        IF (track.adr_ctrl AND %00000010)=0 THEN outlist('\ebCopyright:\en', 'Digital Copy Prohibited') ELSE outlist('\ebCopyright:\en', 'Digital Copy Permitted')
        track:=track + SIZEOF toc_d
    ENDFOR

ENDPROC
