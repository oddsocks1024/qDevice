OPT MODULE
OPT EXPORT

MODULE 'libraries/mui',
       'amigalib/boopsi'


OBJECT listentry -> Entries for the listview
field
value
driver
unit
ENDOBJECT

DEF mui_output_lst

/*
** Adds entries into the listview where both parameters are strings. The first
** string is column one, the second is column two.
*/
PROC outlist(str:PTR TO CHAR, str2:PTR TO CHAR)
DEF txt:listentry

    txt.field:=str
    txt.value:=str2
    txt.driver:=NIL
    txt.unit:=NIL
    doMethodA(mui_output_lst, [MUIM_List_InsertSingle, txt, MUIV_List_Insert_Bottom])
ENDPROC

/*
** Adds entries into the listview where the first parameter is a string, the
** second is an integer, and the third is an optional string. The first string
** is column one, the integer is converted into a string and is column two.
** In the case of the last string (if present) this is appended in column two
** and is usually used for display a value type (eg bytes)
*/
PROC outlist_i(str:PTR TO CHAR, int, valtype:PTR TO CHAR)
DEF txt:listentry,
    str2[80]:STRING

    IF valtype=NIL THEN StringF(str2, '\d', int) ELSE StringF(str2, '\d\s', int, valtype)

    txt.field:=str
    txt.value:=str2
    txt.driver:=NIL
    txt.unit:=NIL
    doMethodA(mui_output_lst, [MUIM_List_InsertSingle, txt, MUIV_List_Insert_Bottom])
ENDPROC

/*
** Almost identical to outlist_i, except the integer is converted into Hex
** before being made into a string
*/
PROC outlist_h(str:PTR TO CHAR, int, valtype:PTR TO CHAR)
DEF txt:listentry,
    str2[80]:STRING

    IF valtype=NIL THEN StringF(str2, '$\h', int) ELSE StringF(str2, '$\h\s', int, valtype)

    txt.field:=str
    txt.value:=str2
    txt.driver:=NIL
    txt.unit:=NIL
    doMethodA(mui_output_lst, [MUIM_List_InsertSingle, txt, MUIV_List_Insert_Bottom])
ENDPROC

/*
** This procedure adds special entries into the listview which the user may
** double click. They have a specific format, with additional information
** that is hidden from the display of the listview, but can be queried if
** a user double clicks an entry.
*/
PROC outlist_d(str:PTR TO CHAR, driver:PTR TO CHAR, unit)
DEF txt:listentry, buildstr[99]:STRING

    StringF(buildstr, '\eb\s [\d]:\en', driver, unit)
    txt.field:=buildstr
    txt.value:=str
    txt.driver:=driver
    txt.unit:=unit
    doMethodA(mui_output_lst, [MUIM_List_InsertSingle, txt, MUIV_List_Insert_Bottom])
ENDPROC
