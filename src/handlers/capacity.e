OPT MODULE
OPT EXPORT

MODULE '*/listview/outlist',
       '*/scsi/headers'

/*
** This procedure handles the data returned from a capacity query
*/
PROC process_capacity(reply:PTR TO capacity)
DEF buildstr[99]:STRING, tcap, vcap

    tcap:=Div(Mul(Div(reply.blocks, 1024), reply.bsize), 1024)
    vcap:=Div(Mul(Div(reply.blocks, 1000), reply.bsize), 1000)

    outlist_i('\ebLast Block:\en', reply.blocks, NIL)
    outlist_i('\ebBlock Size:\en', reply.bsize, ' bytes')

    ->Calculations may seem really weird and convoluted, but its to try and avoid
    ->floating point maths and rounding errors
    IF tcap<1024 THEN StringF(buildstr, '~ \dMB', tcap) ELSE StringF(buildstr, '~ \d.\d GB  (\d MB)', Div(tcap, 1024), (Mod((tcap*10), 10240)/1024), tcap)
    outlist('\ebTrue Capacity:\en', buildstr)
    IF vcap<1000 THEN StringF(buildstr, '~ \dmb', vcap) ELSE StringF(buildstr, '~ \d.\d gb  (\d mb)', Div(vcap, 1000), (Mod(vcap, 1000)/100), vcap)
    outlist('\ebVendor Capacity:\en', buildstr)

ENDPROC
