OPT MODULE
OPT EXPORT

MODULE '*/scsi/headers',
       '*/listview/outlist'

DEF defectsformatflag,
    defectsflag       
       
PROC process_defects(reply:PTR TO d_list)
DEF param:PTR TO d_list_psf, x=0, str[255]:STRING

    param:=reply + SIZEOF d_list

    IF defectsformatflag=0
        IF defectsflag=0
            outlist('\ebList Type:\en', 'Primary')    
        ELSEIF defectsflag=1
            outlist('\ebList Type:\en', 'Grown')
        ELSE
            outlist('\ebList Type:\en', 'Both Primary and Grown')
        ENDIF
        
        outlist('\ebFormat:\en', 'Physical Sector')
        outlist_i('\ebDefect List Size:\en', reply.defectlistsize, ' bytes')
        outlist_i('\ebNumber of Defects:\en', reply.defectlistsize / 8, NIL)
        outlist(' ', ' ')

        FOR x:=1 TO (reply.defectlistsize / 8)
            StringF(str, 'Cylinder: \d, Head: \d, Sector: \d ($\h)',Shr((param.cylinders AND $FFFFFF00), 8), (param.cylinders AND $FF), param.sector, param.sector)
            outlist('\ebDefect Found:\en', str)
            param:=param + SIZEOF d_list_psf
        ENDFOR

    ELSEIF defectsformatflag=1
        IF defectsflag=0
            outlist('\ebList Type:\en', 'Primary')    
        ELSEIF defectsflag=1
            outlist('\ebList Type:\en', 'Grown')
        ELSE
            outlist('\ebList Type:\en', 'Both Primary and Grown')
        ENDIF    
    
        outlist('\ebFormat:\en', 'Bytes From Index')
        outlist_i('\ebDefect List Size:\en', reply.defectlistsize, ' bytes')
        outlist_i('\ebNumber of Defects:\en', reply.defectlistsize / 8, NIL)
        outlist(' ', ' ')

        FOR x:=1 TO (reply.defectlistsize / 8)
            StringF(str, 'Cylinder: \d, Head: \d, Bytes From Index: \d ($\h)',Shr((param.cylinders AND $FFFFFF00), 8), (param.cylinders AND $FF), param.sector, param.sector)
            outlist('\ebDefect Found:\en', str)
            param:=param + SIZEOF d_list_psf
        ENDFOR

    ELSE
        IF defectsflag=0
            outlist('\ebList Type:\en', 'Primary')    
        ELSEIF defectsflag=1
            outlist('\ebList Type:\en', 'Grown')
        ELSE
            outlist('\ebList Type:\en', 'Both Primary and Grown')
        ENDIF     
        
        outlist('\ebFormat:\en', 'Block')
        outlist_i('\ebDefect List Size:\en', reply.defectlistsize, ' bytes')
        outlist_i('\ebNumber of Defects:\en', reply.defectlistsize / 4, NIL)
        outlist(' ', ' ')
    
        FOR x:=1 TO (reply.defectlistsize / 8)
            StringF(str, 'Defective Block Address: \d ($\h)', Long(param), Long(param))
            outlist('\ebDefect Found:\en', str)
            param:=param + 4
        ENDFOR

    ENDIF

ENDPROC
