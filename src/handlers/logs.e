OPT MODULE
OPT EXPORT

MODULE '*/listview/outlist',
       '*/scsi/headers'

/*
** Handler for processing buffer logs
** Page Code: $1
*/
PROC process_log_buffer(reply:PTR TO l_sense) ->DONE
DEF param:PTR TO log_param_type_1,
    str[70]:STRING

    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    param:=reply + SIZEOF l_sense
        
    WHILE (param < (reply + reply.len + SIZEOF l_sense))
    
        IF (param.pcode2 AND %00000001) = 0
            StrCopy(str, 'Buffer Under-Runs', ALL)
        ELSE
            StrCopy(str, 'Buffer Over-Runs', ALL)
        ENDIF

        IF (param.pcode2 AND %00011110) = 0
            StrAdd(str, ' (Cause: Not Defined')
        ELSEIF (param.pcode2 AND %00011110) = 2
            StrAdd(str, ' (Cause: Bus Busy')
        ELSEIF (param.pcode2 AND %00011110) = 4
            StrAdd(str, ' (Cause: Transfer Rate Too Slow')
        ELSE
            StrAdd(str, ' (Cause: Reserved')
        ENDIF

        IF (param.pcode2 AND %11100000) = 0
            StrAdd(str, ', Basis: Not Defined)')
        ELSEIF (param.pcode2 AND %11100000) = 32
            StrAdd(str, ', Basis: Per Command)')
        ELSEIF (param.pcode2 AND %11100000) = 64
            StrAdd(str, ', Basis: Per Failed Reconnect)')
        ELSEIF (param.pcode2 AND %11100000) = 96
            StrAdd(str, ', Basis: Per Unit of Time)')
        ELSE
            StrAdd(str, ', Reserved)')
        ENDIF
        
        outlist('\ebCounter Type:\en', str)
        outlist_i('\ebCounter Total:\en', Int(param + SIZEOF log_param_type_1), NIL)
                
        param:= param + SIZEOF log_param_type_1 + param.len
    ENDWHILE
        
ENDPROC       
       
       
/*
** Handler for processing various error logs. ->DONE
** Page Codes: $2, $3, $4, $5
*/
PROC process_log_errors(reply:PTR TO l_sense)
DEF param:PTR TO log_param_type_2,
    str[55]:STRING,
    vstr[10]:STRING
    
    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    param:=reply + SIZEOF l_sense

    WHILE param < (reply + reply.len + SIZEOF l_sense)
    
        IF param.pcode = $0
            StrCopy(str, '\ebErrors Corrected w/o Delay:\en')
        ELSEIF param.pcode = $1
            StrCopy(str, '\ebErrors Corrected w/ Delay:\en')
        ELSEIF param.pcode = $2
            StrCopy(str, '\ebTotal Re-writes or Re-reads:\en')
        ELSEIF param.pcode = $3
            StrCopy(str, '\ebTotal Errors Corrected:\en')
        ELSEIF param.pcode = $4
            StrCopy(str, '\ebTimes Correction Algorithm Used:\en')
        ELSEIF param.pcode = $5
            StrCopy(str, '\ebTotal Bytes Processed:\en')
        ELSEIF param.pcode = $6
            StrCopy(str, '\ebUncorrected Errors:\en')
        ELSE
            StrCopy(str, '\ebVendor Parameter\en:')
        ENDIF
        
        IF param.len = 1
            outlist_i(str, Char(param + SIZEOF log_param_type_2), NIL)
        ELSEIF param.len = 2
            outlist_i(str, Int(param + SIZEOF log_param_type_2), NIL)
        ELSEIF param.len = 4
            outlist_i(str, Long(param + SIZEOF log_param_type_2), NIL)
        ELSEIF param.len = 8
            StringF(vstr, '$\h\h', Long(param + SIZEOF log_param_type_2), Long(param + SIZEOF log_param_type_2 + 4))
            outlist(str, vstr)
        ELSE
            outlist(str, 'Cannot Decode')
        ENDIF

        param:= param + SIZEOF log_param_type_2 + param.len
    ENDWHILE

ENDPROC


/*
** Handler for processing non medium error logs ->DONE
** Page Code: $6
*/
PROC process_log_nmerrors(reply:PTR TO l_sense)
DEF param:PTR TO log_param_type_2,
    str[55]:STRING,
    vstr[10]:STRING

    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    param:=reply + SIZEOF l_sense

    WHILE param < (reply + reply.len + SIZEOF l_sense)

        IF param.pcode = $0 THEN StrCopy(str, '\ebNon-Medium Error Count:\en') ELSE  StrCopy(str, '\ebVendor Parameter:\en')

        IF param.len = 1
            outlist_i(str, Char(param + SIZEOF log_param_type_2), NIL)
        ELSEIF param.len = 2
            outlist_i(str, Int(param + SIZEOF log_param_type_2), NIL)
        ELSEIF param.len = 4
            outlist_i(str, Long(param + SIZEOF log_param_type_2), NIL)
        ELSEIF param.len = 8
            StringF(vstr, '$\h\h', Long(param + SIZEOF log_param_type_2), Long(param + SIZEOF log_param_type_2 + 4))
            outlist(str, vstr)
        ELSE
            outlist(str, 'Cannot Decode')
        ENDIF

        
        param:= param + SIZEOF log_param_type_2 + param.len
    ENDWHILE

ENDPROC


/*
** Handler for processing temperature logs
** Page Code: $D
*/
PROC process_log_temperature(reply:PTR TO l_sense)
    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    outlist_i('\ebCurrent Temperature:\en', Char(reply+9),' degrees celsius')
    IF (reply.len > 15) THEN outlist_i('\ebReference Temperature:\en', Char(reply+15), ' degrees celsius')
ENDPROC


/*
** Handler for processing information exception logs
** Page Code: $2F
*/
PROC process_log_ie(reply:PTR TO l_sense) -> DONE
DEF param:PTR TO log_param_type_2
    
    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    param:=reply + SIZEOF l_sense
    
    WHILE param < (reply + reply.len + SIZEOF l_sense)

        outlist_i('\ebParameter Code:\en', param.pcode, NIL)
        outlist_i('\ebParameter Size:\en', param.len, ' bytes')
        outlist_h('\ebSMART Sense Code:\en', Char(param + SIZEOF log_param_type_2), NIL)
        outlist_h('\ebSMART Sense Qualifier:\en', Char(param + SIZEOF log_param_type_2 + 1), NIL)
        param:= param + SIZEOF log_param_type_2 + param.len
    ENDWHILE

ENDPROC


/*
** Handler for processing information exception logs
** Page Code: $30
*/
PROC process_log_smartsense(reply:PTR TO l_sense) -> DONE
DEF param:PTR TO log_param_type_2,
    str[100]:STRING,
    vstr[20]:STRING
    
    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    param:=reply + SIZEOF l_sense
    
    WHILE param < (reply + reply.len + SIZEOF l_sense)

        outlist_h('\ebParameter Code:\en', param.pcode, NIL)
        ->outlist_h('\ebParameter Size:\en', param.len, NIL)
        
        IF param.len = 1
            outlist_i('\ebParameter Value:\en', Char(param + SIZEOF log_param_type_2), NIL)
        ELSEIF param.len = 2
            outlist_i('\ebParameter Value:\en', Int(param + SIZEOF log_param_type_2), NIL)
        ELSE
            StringF(str, 'Normalised: \d, Worst Ever: \d, Warranty Failure Threshold: \d', Char(param + SIZEOF log_param_type_2), Char(param + SIZEOF log_param_type_2 + 1), Char(param + SIZEOF log_param_type_2 + 2 ))
            outlist('\ebParameter Value:\en', str) 
        ENDIF
        
        param:= param + SIZEOF log_param_type_2 + param.len
    ENDWHILE

ENDPROC


/*
** Handler for processing performance logs
** NOTE: This page may be vendor/device dependant
** Page Code: $30
*/
PROC process_log_performance(reply:PTR TO l_sense)

    outlist_i('\ebLog Size:\en', reply.len, ' bytes')

    outlist_i('\ebZero Seeks:\en', Int(reply+8), NIL)
    outlist_i('\ebSeeks (>=2/3) of disk:\en', Int(reply+10), NIL)
    outlist_i('\ebSeeks (>=1/3 AND <2/3) of disk:\en', Int(reply+12), NIL)
    outlist_i('\ebSeeks (>=1/6 AND <1/3) of disk:\en', Int(reply+14), NIL)
    outlist_i('\ebSeeks (>=1/12 AND <1/6) of disk:\en', Int(reply+16), NIL)
    outlist_i('\ebSeeks (>0 and <1/12) of disk:\en', Int(reply+18), NIL)
    outlist_i('\ebOverrun Counter:\en', Int(reply+24), NIL)
    outlist_i('\ebUnderrun Counter:\en', Int(reply+26), NIL)
    outlist_i('\ebDevice Cache Full Read Hits:\en', Long(reply+28), NIL)
    outlist_i('\ebDevice Cache Partial Read Hits:\en', Long(reply+32), NIL)
    outlist_i('\ebDevice Cache Write Hits:\en', Long(reply+36), NIL)
    outlist_i('\ebDevice Cache Fast Writes:\en', Long(reply+40), NIL)

ENDPROC

/*
** Handler for processing physical error sites
** NOTE: This page may be vendor/device dependant
** Page Code: $32
*/
PROC process_log_physical(reply:PTR TO l_sense)

    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    outlist('\ebNote:\en', 'Further decoding of this page is not yet supported')
    
ENDPROC    


/*
** Handler for processing LBA Error Sites
** NOTE: This page may be vendor/device dependant
** Page Code: $33
*/
PROC process_log_lba(reply:PTR TO l_sense)

    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    outlist('\ebNote:\en', 'Further decoding of this page is not yet supported')
    
ENDPROC 


/*
** Handler for processing Cache Utilisation
** NOTE: This page may be vendor/device dependant
** Page Code: $35
*/
PROC process_log_cache(reply:PTR TO l_sense)

    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    
    outlist_i('\ebCumulative Cache Full Hits on Reads:\en', Long(reply+8), NIL)
    outlist_i('\ebCumulative Cache Partial Hits on Reads:\en', Long(reply+12), NIL)
    outlist_i('\ebCumulative Cache Misses on Reads:\en', Long(reply+16), NIL)
ENDPROC


/*
** Handler for processing temperature
** NOTE: This page may be vendor/device dependant
** Page Code: $36
*/
PROC process_log_ibmtemp(reply:PTR TO l_sense)

    outlist_i('\ebLog Size:\en', reply.len, ' bytes')    
    outlist_i('\ebCurrent Temperature:\en', Char(reply+9),' degrees celsius')
    
ENDPROC


