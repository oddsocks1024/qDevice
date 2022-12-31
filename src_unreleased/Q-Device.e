OPT PREPROCESS, OSVERSION=37

/*
    Program:     Q-Device!
    Version:     V0.7
    Author:      Ian Chapman
    Description: A low-level SCSI query, command and diagnostic tool.

    LICENSE: Permission is granted to use this source code in whole or in part,
             providing that the author (Ian Chapman) is credited in your project
             in either the documentation, or the program itself. This applies to
             both free and commercial software. In the case of commerical
             software (including ShareWare), I am entitled to a free, fully
             functional copy of the software.

             NO WARRANTY EITHER EXPRESSED OR IMPLIED AS TO THE FITNESS OF THIS
             CODE FOR ANY PURPOSE. ALL USE IS ENTIRELY AND WHOLLY AT YOUR OWN
             RISK
*/

MODULE  'exec/ports',
        'exec/io',
        'exec/execbase',
        'exec/lists',
        'exec/nodes',
        'exec/tasks',
        'exec/memory',
        'amigalib/io',
        'amigalib/boopsi',
        'devices/scsidisk',
        'mui/betterstring_mcc',
        'libraries/mui',
        'libraries/gadtools',
        'libraries/reqtools',
        'utility/tagitem',
        'utility/hooks',
        'tools/installhook',
        'dos/dos',
        'dos/dosextens',
        'miami/netinclude/pragmas/socket',
        'amitcp/sys/ioctl',
        'amitcp/sys/socket',
        'amitcp/sys/types',
        'amitcp/sys/time',
        'amitcp/netdb',
        'amitcp/netinet/in',
        'muimaster',
        'icon',
        'reqtools',
        '*scsi/opcodes',
        '*scsi/params',
        '*scsi/headers',
        '*handlers/defects',
        '*handlers/inquiry',
        '*handlers/capacity',
        '*handlers/toc',
        '*handlers/atip',
        '*handlers/sense',
        '*handlers/modesense',
        '*handlers/logs',
        '*handlers/feature',
        '*listview/outlist'
        
CONST BUFFSIZE=255, BUFFSIZEBIG=65535

ENUM ID_INQUIRE=1, ID_EJECT, ID_INSERT, ID_LOCK, ID_UNLOCK, ID_CAPACITY, ID_TESTREADY, ID_READTOC,
     ID_POWERUP, ID_POWERDOWN, ID_PROBE, ID_ABOUT, ID_MUIABOUT, ID_ICONIFY, ID_MUISET, ID_DIAGNOSTIC,
     ID_MODESENSE, ID_DOUBLECLICK, ID_PREFS, ID_SAVEPREF, ID_USEPREF, ID_CANCELPREF, ID_SERIAL, ID_ATIP,
     ID_SHOWLOGS, ID_SHOWDEFECTS, ID_SAVELOG, ID_REWIND, ID_GETCONFIG

ENUM NORMAL=0, ERR_MP=1, ERR_IOR, ERR_DEVICE, ERR_NOMUI, ERR_NOICON, ERR_NOAPP,
     ERR_NOBSD, ERR_NOSOCK, ERR_NOCONNECT, ERR_REMOTESCSI, ERR_NOREQTOOLS

ENUM OBID_DRIVER=1, OBID_UNIT, OBID_PROBEFROM, OBID_PROBETO, OBID_HOST,
     OBID_PORT, OBID_AUTOSENSE

DEF app, mui_output_lst, mui_output_lv, mui_status_tb, mui_device_tb, mui_unit_tb, displayhook:hook,
    constructhook:hook, destructhook:hook, devicelist[50]:ARRAY OF LONG, execobject:PTR TO execbase,
    global_devtype=0, host[80]:STRING, port[5]:STRING, driver[80]:STRING, unit[6]:STRING, autosenseflag=0,
    logpath[255]:STRING, alternatelog=0

PROC main() HANDLE
DEF signal, result, running=TRUE,   probefrom[6]:STRING, probeto[6]:STRING, probefromtemp[6]:STRING,
    probetotemp[6]:STRING, hosttemp[80]:STRING, porttemp[5]:STRING, mui_probefrom_tb, mui_probeto_tb,
    mui_host_tb, mui_port_tb,  mui_main_win, mui_prefs_win, mui_inquire_but, mui_eject_but, mui_insert_but,
    mui_lock_but, mui_unlock_but, mui_capacity_but, mui_testready_but, mui_readtoc_but, mui_powerup_but,
    mui_powerdown_but, mui_probe_but, mui_diagnostic_but,  mui_modesense_but, mui_diagnostic_cyc, mui_defects_cyc,
    mui_defectsformat_cyc, mui_prefsave_but, mui_prefuse_but, mui_prefcancel_but, mui_serial_but, mui_atip_but,
    mui_showlogs_but, mui_getconfig_but, mui_autosense_cm, mui_showdefects_but, mui_savelog_but, mui_rewind_but, menu, diagflag=0,
    diskobj=NIL, i, task:PTR TO process, icon[255]:STRING, autosenseflagtemp=0

    grab_devices()
    menu:= [ NM_TITLE, 0, 'Project', 0, 0, 0, 0,
             NM_ITEM,  0, 'About...', '?', 0, 0, ID_ABOUT,
             NM_ITEM,  0, 'About MUI...', 0, 0, 0, ID_MUIABOUT,
             NM_ITEM,  0, NM_BARLABEL, 0, 0, 0, 0,
             NM_ITEM,  0, 'Iconify', 'I', 0, 0, ID_ICONIFY,
             NM_ITEM,  0, 'Quit', 'Q', 0, 0, MUIV_Application_ReturnID_Quit,
             NM_TITLE, 0, 'Query', 0, 0, 0, 0,
             NM_ITEM,  0, 'Probe', 0, 0, 0, ID_PROBE,
             NM_ITEM,  0, 'Full Inquiry', 0, 0, 0, ID_INQUIRE,
             NM_ITEM,  0, 'Capacity', 0, 0, 0, ID_CAPACITY,
             NM_ITEM,  0, 'Test Ready', 0, 0, 0, ID_TESTREADY,
             NM_ITEM,  0, 'Device Parameters', 0, 0, 0, ID_MODESENSE,
             NM_ITEM,  0, 'Show Firmware Logs', 0, 0, 0, ID_SHOWLOGS,
             NM_ITEM,  0, 'Serial #', 0, 0, 0, ID_SERIAL,
             NM_ITEM,  0, 'Read TOC', 0, 0, 0, ID_READTOC,
             NM_ITEM,  0, 'ATIP', 0, 0, 0, ID_ATIP,  
             NM_TITLE, 0, 'Control', 0, 0, 0, 0,
             NM_ITEM,  0, 'Power Up', 0, 0, 0, ID_POWERUP,
             NM_ITEM,  0, 'Power Down', 0, 0, 0, ID_POWERDOWN,
             NM_ITEM,  0, 'Lock', 0, 0, 0, ID_LOCK,
             NM_ITEM,  0, 'UnLock', 0, 0, 0, ID_UNLOCK,
             NM_ITEM,  0, 'Insert', 0, 0, 0, ID_INSERT,
             NM_ITEM,  0, 'Eject', 0, 0, 0, ID_EJECT,
             NM_ITEM,  0, 'Rewind/Rezero', 0, 0, 0, ID_REWIND,
             NM_TITLE, 0, 'Diagnostic', 0, 0, 0, 0,
             NM_ITEM,  0, 'Unit Self Test', 0, 0, 0, ID_DIAGNOSTIC,
             NM_ITEM,  0, 'Show Defects', 0, 0, 0, ID_SHOWDEFECTS,
             NM_TITLE, 0, 'Settings', 0, 0, 0, 0,
             NM_ITEM,  0, 'MUI Settings', 0, 0, 0, ID_MUISET,
             NM_ITEM,  0, 'Preferences', 'P', 0, 0, ID_PREFS,
             NM_ITEM,  0, NM_BARLABEL, 0, 0, 0, 0,
             NM_ITEM,  0, 'Save Preferences', 0, 0, 0, ID_SAVEPREF,
             NM_END,   0, NIL, 0, 0, 0, 0]:newmenu
    
    ->Quick hack to use program icon as AppIcon. A bit limited if Q-Device! is
    ->launched from the CLI
    Forbid()
    task:=FindTask(NIL)
    IF StrCmp(task.task.ln.name, 'Shell Process') = TRUE THEN StrCopy(icon, 'PROGDIR:Q-Device') ELSE StringF(icon, 'PROGDIR:\s', task.task.ln.name)
    Permit()
    
    IF (muimasterbase:=OpenLibrary('muimaster.library', 19))=NIL THEN Raise(ERR_NOMUI)
    IF (iconbase:=OpenLibrary('icon.library', 33))=NIL THEN Raise(ERR_NOICON)
    IF (reqtoolsbase:=OpenLibrary('reqtools.library', 39))=NIL THEN Raise(ERR_NOREQTOOLS)
    
    installhook(displayhook, {disp})
    installhook(constructhook, {construct})
    installhook(destructhook, {destruct})

    mui_output_lv:=ListviewObject,
                    MUIA_Listview_Input, MUI_TRUE,
                    MUIA_CycleChain, 1,
                    MUIA_Listview_List, mui_output_lst:=ListObject,
                        ReadListFrame,
                            MUIA_List_Title, MUI_TRUE,
                            MUIA_List_Format, 'BAR,',
                            MUIA_List_DisplayHook, displayhook,
                            MUIA_List_ConstructHook, constructhook, ->MUIV_List_ConstructHook_String,
                            MUIA_List_DestructHook, destructhook, ->MUIV_List_DestructHook_String,
                            MUIA_ShortHelp, 'Information and diagnostic output',
                        End, -> ReadListFrame
                    End ->Listviewobject

    mui_inquire_but:=make_button('Full Inquiry', 'Display full inquiry information')
    mui_serial_but:=make_button('Serial #', 'Show product serial number')
    mui_eject_but:=make_button('Eject', 'Attempt to eject media')
    mui_insert_but:=make_button('Insert', 'Attempt to insert media')
    mui_lock_but:=make_button('Lock', 'Prevent media from being removed')
    mui_unlock_but:=make_button('UnLock', 'Allow media to be removed')
    mui_capacity_but:=make_button('Capacity', 'Show device capacity')
    mui_testready_but:=make_button('Test Ready', 'Test if unit is ready')
    mui_readtoc_but:=make_button('Read TOC', 'Show CD Table of Contents')
    mui_powerup_but:=make_button('Power Up', 'Attempt to spin-up the device')
    mui_powerdown_but:=make_button('Power Down', 'Attempt to spin-down the device')
    mui_probe_but:=make_button('\eb\eiProbe\en', 'Probe driver for attached devices')
    mui_diagnostic_but:=make_button('Start Self Test', 'Instruct the device to perform a self test')
    mui_modesense_but:=make_button('Device Parameters', 'Return information about the device\as parameters and specs')
    mui_atip_but:=make_button('ATIP', 'Show ATIP information for CD-R/RW')
    mui_getconfig_but:=make_button('Get Config', 'Show feature configuration')
    mui_rewind_but:=make_button('Rewind/Rezero', 'Rewinds the tape for sequential devices\nall other devices perform a rezero')
    mui_showlogs_but:=make_button('Firmware Logs', 'Attempt to display and decode all firmware logs.')
    mui_showdefects_but:=make_button('Show Defects', 'Display drive defects')
    mui_savelog_but:=make_button('Save Output', 'Save listview output to a file')
    mui_prefsave_but:=make_button('Save', 'Save preferences')
    mui_prefuse_but:=make_button('Use', 'Use preferences, changes are lost after reboot')
    mui_prefcancel_but:=make_button('Cancel', 'Discard any changes')
    mui_autosense_cm:=make_checkmark(FALSE, 'Guarantees the preservation of sense data\nMost drivers do not support this so disable\nit if you experience problems')
    SetAttrsA(mui_autosense_cm, [MUIA_ObjectID, OBID_AUTOSENSE, TAG_DONE])
    mui_defects_cyc:=KeyCycle(['Primary List', 'Grown List', 'Both', NIL], "m")
    SetAttrsA(mui_defects_cyc, [MUIA_ShortHelp, 'Choose the type of defects to show\nPrimary = Areas marked as faulty at the factory\nGrown = Areas which have become faulty since', MUIA_CycleChain, 1, TAG_DONE])  
    mui_diagnostic_cyc:=KeyCycle(['Simple 1', 'Simple 2', 'Deep 1', 'Deep 2', NIL], "d")
    SetAttrsA(mui_diagnostic_cyc, [MUIA_ShortHelp, 'Choose diagnostic test', MUIA_CycleChain, 1, TAG_DONE])    
    mui_defectsformat_cyc:=KeyCycle(['Physical Sector', 'Bytes From Index', 'Block', NIL], "f")
    SetAttrsA(mui_defectsformat_cyc, [MUIA_ShortHelp, 'Choose defect output format', MUIA_CycleChain, 1, TAG_DONE])
    

    mui_device_tb:=BetterStringObject, StringFrame,
                    MUIA_String_AdvanceOnCR, MUI_TRUE,
                    MUIA_String_Contents, driver,
                    MUIA_ShortHelp, 'Device driver to use',
                    MUIA_CycleChain, 1,
                    MUIA_ObjectID, OBID_DRIVER,
                   End

    mui_unit_tb:=BetterStringObject, StringFrame,
                    MUIA_String_AdvanceOnCR, MUI_TRUE,
                    MUIA_String_Contents, unit,
                    MUIA_ShortHelp, 'AmigaDOS Unit Number',
                    MUIA_String_Accept, '0123456789',
                    MUIA_String_MaxLen, 6,
                    MUIA_CycleChain, 1,
                    MUIA_ObjectID, OBID_UNIT,
                 End

    mui_status_tb:=TextObject, TextFrame,
                    MUIA_String_Contents, 'Ready',
                    MUIA_ShortHelp, 'SCSI/IDE target condition',
                   End

    mui_probefrom_tb:=BetterStringObject, StringFrame,
                    MUIA_String_AdvanceOnCR, MUI_TRUE,
                    MUIA_String_Contents, probefrom,
                    MUIA_ShortHelp, 'Probing devices starts at this unit',
                    MUIA_String_Accept, '0123456789',
                    MUIA_String_MaxLen, 6,
                    MUIA_CycleChain, 1,
                    MUIA_ObjectID, OBID_PROBEFROM,
                 End

    mui_probeto_tb:=BetterStringObject, StringFrame,
                    MUIA_String_AdvanceOnCR, MUI_TRUE,
                    MUIA_String_Contents, probeto,
                    MUIA_ShortHelp, 'Probing devices ends at this unit',
                    MUIA_String_Accept, '0123456789',
                    MUIA_String_MaxLen, 6,
                    MUIA_CycleChain, 1,
                    MUIA_ObjectID, OBID_PROBETO,
                 End

    mui_host_tb:=BetterStringObject, StringFrame,
                    MUIA_String_AdvanceOnCR, MUI_TRUE,
                    MUIA_String_Contents, host,
                    MUIA_ShortHelp, 'Host to connect to when using tcpip-scsi.device',
                    MUIA_String_MaxLen, 80,
                    MUIA_CycleChain, 1,
                    MUIA_ObjectID, OBID_HOST,
                 End

    mui_port_tb:=BetterStringObject, StringFrame,
                    MUIA_String_AdvanceOnCR, MUI_TRUE,
                    MUIA_String_Contents, port,
                    MUIA_ShortHelp, 'Base port to connect to when using tcpip-scsi.device',
                    MUIA_String_MaxLen, 5,
                    MUIA_CycleChain, 1,
                    MUIA_ObjectID, OBID_PORT,
                 End


    app:=ApplicationObject,
        MUIA_Application_Title      , 'Q-Device!',
        MUIA_Application_Version    , '$VER: Q-Device! v0.7',
        MUIA_Application_Copyright  , 'Written By Ian Chapman (2004)',
        MUIA_Application_Author     , 'Ian Chapman',
        MUIA_Application_Description, 'IDE/SCSI device query tool',
        MUIA_Application_Base       , 'QDEVICE',
        MUIA_Application_SingleTask , FALSE,
        MUIA_Application_DiskObject , diskobj:=GetDiskObject(icon),
        MUIA_Application_Menustrip  , Mui_MakeObjectA(MUIO_MenustripNM,[menu,0]),
        MUIA_Application_HelpFile   , 'Q-Device!.guide',

        SubWindow, mui_main_win:=WindowObject,
        MUIA_Window_Title       , 'Q-Device! V0.7 by Ian Chapman',
        MUIA_Window_ID          , "QDEV",
        MUIA_Window_Activate    , MUI_TRUE,

        WindowContents, VGroup,
                        Child, HGroup,
                            Child, Label('Driver:'),
                            Child, PoplistObject,
                                    MUIA_Popstring_String, mui_device_tb,
                                    MUIA_Popstring_Button, PopButton( MUII_PopUp ),
                                    MUIA_Poplist_Array, devicelist,
                            End,
                            Child, Label('Unit:'),                            
                            Child, PoplistObject,
                                    MUIA_Popstring_String, mui_unit_tb,
                                    MUIA_Popstring_Button, PopButton( MUII_PopUp ),
                                    MUIA_Poplist_Array, ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', NIL],
                            End,
                        End, ->HGroup
                        Child, HGroup,
                            Child, Label('Target Status:'),
                            Child, mui_status_tb,
                        End, -> HGroup
                        Child, RegisterGroup(['Query', 'Control', 'Diagnostic', NIL]),
                            Child, VGroup,
                                Child, ColGroup(3), 
                                    Child, mui_probe_but,
                                    Child, mui_inquire_but,
                                    Child, mui_capacity_but,
                                    Child, mui_testready_but,
                                    Child, mui_modesense_but,
                                    Child, mui_showlogs_but,
                                    Child, mui_serial_but,
                                    Child, mui_readtoc_but,
                                    Child, mui_atip_but,                                    
                                    Child, mui_getconfig_but,
                                    Child, HSpace(0),
                                    Child, HSpace(0),
                                End, -> ColGroup
                            End, -> VGroup
                            Child, ColGroup(2),
                                Child, mui_powerup_but,
                                Child, mui_powerdown_but,
                                Child, mui_lock_but,
                                Child, mui_unlock_but,
                                Child, mui_insert_but,
                                Child, mui_eject_but,
                                Child, mui_rewind_but,
                                Child, HSpace(0),
                                Child, HSpace(0), 
                            End, -> Colgroup
                            /*
                            Child, ColGroup(2), 
                                Child, HGroup, 
                                End, -> HGroup
                                Child, mui_diagnostic_but,
                                Child, HGroup,
                                    Child, Label('_Medium Defect Type:'),
                                    Child, mui_defects_cyc,
                                    Child, Label('_Format'),
                                    Child, mui_defectsformat_cyc,
                                End, -> HGroup
                                Child, mui_showdefects_but,
                            End, -> ColGroup
                            */

                            Child, HGroup,
                                Child, VGroup,
                                    GroupFrameT('Self Tests'),
                                    Child, ColGroup(2),
                                        Child, Label('_Diagnostic Test Type:'),
                                        Child, mui_diagnostic_cyc,
                                        Child, HSpace(0),
                                        Child, mui_diagnostic_but,
                                    End, ->ColGroup
                                    Child,VSpace(0),
                                End, ->VGroup

                                Child, VGroup,
                                    GroupFrameT('Defects'),
                                    Child, ColGroup(2),
                                        Child, Label('_Medium Defect Type:'),
                                        Child, mui_defects_cyc,
                                        Child, Label('_Format'),
                                        Child, mui_defectsformat_cyc,
                                        Child, HSpace(0),
                                        Child, mui_showdefects_but,
                                    End, -> ColGroup
                                End, ->VGroup

                            End, ->Hgroup

                        End, -> Register,
                        Child, BalanceObject, End,
                        Child, mui_output_lv,
                        Child, mui_savelog_but,
                    End, ->VGroup
  
                End, -> WindowObject

        SubWindow, mui_prefs_win:=WindowObject,
        MUIA_Window_Title       , 'Preferences',
        MUIA_Window_ID          , "PREF",
        MUIA_Window_Activate    , MUI_TRUE,
        MUIA_HelpNode           , 'Preferences Window',

        WindowContents, VGroup,
                            Child, HGroup,
                                GroupFrameT('Probing'),
                                Child, Label('From Unit:'),
                                Child, mui_probefrom_tb,
                                Child, Label('To Unit:'),
                                Child, mui_probeto_tb,
                            End, -> HGroup
                            Child, HGroup,
                                GroupFrameT('tcpip-scsi.device'),
                                Child, Label('Host:'),
                                Child, mui_host_tb,
                                Child, Label('Port:'),
                                Child, mui_port_tb,
                            End, -> HGroup  
                            Child, HGroup,
                                GroupFrameT('Flags'),
                                Child, HSpace(0),
                                Child, Label('Use SCSIF-AUTOSENSE:'),
                                Child, mui_autosense_cm,
                            End,
                            Child, BalanceObject, End,
                            Child, HGroup,
                                Child, mui_prefsave_but,
                                Child, mui_prefuse_but,
                                Child, mui_prefcancel_but,
                            End, -> HGroup
                        End, -> VGroup
        End, -> Window

    End -> Application

    IF (app=NIL) THEN Raise(ERR_NOAPP)

    doMethodA(mui_inquire_but,      [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_INQUIRE])
    doMethodA(mui_serial_but,       [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_SERIAL])
    doMethodA(mui_eject_but,        [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_EJECT])
    doMethodA(mui_insert_but,       [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_INSERT])
    doMethodA(mui_lock_but,         [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_LOCK])
    doMethodA(mui_unlock_but,       [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_UNLOCK])
    doMethodA(mui_capacity_but,     [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_CAPACITY])
    doMethodA(mui_testready_but,    [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_TESTREADY])
    doMethodA(mui_readtoc_but,      [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_READTOC])
    doMethodA(mui_powerup_but,      [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_POWERUP])
    doMethodA(mui_powerdown_but,    [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_POWERDOWN])
    doMethodA(mui_probe_but,        [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_PROBE])
    doMethodA(mui_diagnostic_but,   [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_DIAGNOSTIC])
    doMethodA(mui_modesense_but,    [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_MODESENSE])
    doMethodA(mui_atip_but,         [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_ATIP])
    doMethodA(mui_getconfig_but,    [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_GETCONFIG])
    doMethodA(mui_rewind_but,       [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_REWIND])
    doMethodA(mui_showlogs_but,     [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_SHOWLOGS])
    doMethodA(mui_prefsave_but,     [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_SAVEPREF])
    doMethodA(mui_prefuse_but,      [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_USEPREF])
    doMethodA(mui_prefcancel_but,   [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_CANCELPREF])
    doMethodA(mui_showdefects_but,  [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_SHOWDEFECTS])
    doMethodA(mui_savelog_but,      [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_SAVELOG])
    doMethodA(mui_diagnostic_cyc,   [MUIM_Notify, MUIA_Cycle_Active, MUIV_EveryTime, mui_diagnostic_cyc, 3, MUIM_WriteLong, MUIV_TriggerValue, {diagflag}])
    doMethodA(mui_defects_cyc,      [MUIM_Notify, MUIA_Cycle_Active, MUIV_EveryTime, mui_defects_cyc,    3, MUIM_WriteLong, MUIV_TriggerValue, {defectsflag}])
    doMethodA(mui_defectsformat_cyc,[MUIM_Notify, MUIA_Cycle_Active, MUIV_EveryTime, mui_defectsformat_cyc,    3, MUIM_WriteLong, MUIV_TriggerValue, {defectsformatflag}])
    doMethodA(mui_device_tb,        [MUIM_Notify, MUIA_String_Contents, MUIV_EveryTime, mui_device_tb,    3, MUIM_WriteString, MUIV_TriggerValue, driver])
    doMethodA(mui_unit_tb,          [MUIM_Notify, MUIA_String_Contents, MUIV_EveryTime, mui_unit_tb,      3, MUIM_WriteString, MUIV_TriggerValue, unit])
    doMethodA(mui_probefrom_tb,     [MUIM_Notify, MUIA_String_Contents, MUIV_EveryTime, mui_probefrom_tb, 3, MUIM_WriteString, MUIV_TriggerValue, probefrom])
    doMethodA(mui_probeto_tb,       [MUIM_Notify, MUIA_String_Contents, MUIV_EveryTime, mui_probeto_tb,   3, MUIM_WriteString, MUIV_TriggerValue, probeto])
    doMethodA(mui_host_tb,          [MUIM_Notify, MUIA_String_Contents, MUIV_EveryTime, mui_host_tb,      3, MUIM_WriteString, MUIV_TriggerValue, host])
    doMethodA(mui_port_tb,          [MUIM_Notify, MUIA_String_Contents, MUIV_EveryTime, mui_port_tb,      3, MUIM_WriteString, MUIV_TriggerValue, port])
    doMethodA(mui_main_win,         [MUIM_Notify, MUIA_Window_CloseRequest, MUI_TRUE, app, 2, MUIM_Application_ReturnID, MUIV_Application_ReturnID_Quit])
    doMethodA(mui_prefs_win,        [MUIM_Notify, MUIA_Window_CloseRequest, MUI_TRUE, app, 2, MUIM_Application_ReturnID, ID_CANCELPREF])
    doMethodA(mui_output_lv,        [MUIM_Notify, MUIA_Listview_DoubleClick, MUI_TRUE, app, 2, MUIM_Application_ReturnID, ID_DOUBLECLICK])
    doMethodA(mui_autosense_cm,      [MUIM_Notify, MUIA_Selected, MUIV_EveryTime, mui_autosense_cm, 3, MUIM_WriteLong, MUIV_TriggerValue, {autosenseflag}])
    set(mui_status_tb, MUIA_Text_Contents, 'Ready')
    SetAttrsA(mui_main_win, [MUIA_Window_ActiveObject, mui_unit_tb, MUIA_Window_Open, MUI_TRUE, TAG_DONE])

    doMethodA(app, [MUIM_Application_Load, MUIV_Application_Load_ENV])

    IF (StrCmp(unit, '', ALL) = TRUE)
        StrCopy(unit, '0')
        set(mui_unit_tb, MUIA_String_Contents, '0')
    ENDIF

    IF (StrCmp(driver, '', ALL) = TRUE)
        StrCopy(driver, 'scsi.device')
        set(mui_device_tb, MUIA_String_Contents, driver)
    ENDIF

    IF (StrCmp(probefrom, '', ALL) = TRUE)
        StrCopy(probefrom, '0')
        set(mui_probefrom_tb, MUIA_String_Contents, '0')
    ENDIF

    IF (StrCmp(probeto, '', ALL) = TRUE)
        StrCopy(probeto, '12')
        set(mui_probeto_tb, MUIA_String_Contents, '15')
    ENDIF

    IF (StrCmp(host, '', ALL) = TRUE)
        StrCopy(host, 'localhost')
        set(mui_host_tb, MUIA_String_Contents, 'localhost')
    ENDIF

    IF (StrCmp(port, '', ALL) = TRUE)
        StrCopy(port, '8000')
        set(mui_port_tb, MUIA_String_Contents, '8000')
    ENDIF

    WHILE running
        result:=doMethodA(app, [MUIM_Application_Input,{signal}])
        SELECT result
            CASE MUIV_Application_ReturnID_Quit
                running:=FALSE
            CASE ID_SAVEPREF
                doMethodA(app, [MUIM_Application_Save, MUIV_Application_Save_ENV])
                doMethodA(app, [MUIM_Application_Save, MUIV_Application_Save_ENVARC])
                set(mui_prefs_win, MUIA_Window_Open, FALSE)
            CASE ID_USEPREF
                doMethodA(app, [MUIM_Application_Save, MUIV_Application_Save_ENV])
                set(mui_prefs_win, MUIA_Window_Open, FALSE)
            CASE ID_CANCELPREF
                StrCopy(probefrom, probefromtemp)
                StrCopy(probeto, probetotemp)
                StrCopy(host, hosttemp)
                StrCopy(port, porttemp)
                autosenseflag:=autosenseflagtemp
                set(mui_autosense_cm, MUIA_Selected, autosenseflag)
                set(mui_prefs_win, MUIA_Window_Open, FALSE)
                set(mui_probeto_tb, MUIA_String_Contents, probeto)
                set(mui_probefrom_tb, MUIA_String_Contents, probefrom)
                set(mui_port_tb, MUIA_String_Contents, port)
                set(mui_host_tb, MUIA_String_Contents, host)
            CASE ID_PREFS
                StrCopy(probefromtemp, probefrom)
                StrCopy(probetotemp, probeto)
                StrCopy(hosttemp, host)
                StrCopy(porttemp, port)
                autosenseflagtemp:=autosenseflag
                set(mui_prefs_win, MUIA_Window_Open, MUI_TRUE)
            CASE ID_INQUIRE
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_INQUIRY, 0, 0, 0, BUFFSIZE,0]:cdb6, SIZEOF cdb6, AFLG_INQUIRY_VERBOSE)
            CASE ID_SERIAL
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_INQUIRY, 1, $80, 0, BUFFSIZE, 0]:cdb6, SIZEOF cdb6, AFLG_INQUIRY_SERIAL)
            CASE ID_EJECT
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_CD_START_STOP_UNIT, 0, 0, 0, P_EJECT, 0]:cdb6, SIZEOF cdb6, NIL)
            CASE ID_INSERT
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_CD_START_STOP_UNIT, 0, 0, 0, P_INSERT, 0]:cdb6, SIZEOF cdb6, NIL)
            CASE ID_POWERUP
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_DA_START_STOP_UNIT, 0, 0, 0, P_START, 0]:cdb6, SIZEOF cdb6, NIL)
            CASE ID_POWERDOWN
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_DA_START_STOP_UNIT, 0, 0, 0, P_STOP, 0]:cdb6, SIZEOF cdb6, NIL)
            CASE ID_LOCK
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_CD_PREVENT_ALLOW_MEDIUM_REMOVAL, 0, 0, 0, P_LOCK, 0]:cdb6, SIZEOF cdb6, NIL)
            CASE ID_UNLOCK
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_CD_PREVENT_ALLOW_MEDIUM_REMOVAL, 0, 0, 0, P_UNLOCK, 0]:cdb6, SIZEOF cdb6, NIL)
            CASE ID_CAPACITY
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_DA_READ_CAPACITY, 0, 0, 0, 0, 0, 0, 0, 0, 0]:cdb10, SIZEOF cdb10, NIL)
            CASE ID_TESTREADY
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_TEST_UNIT_READY, 0, 0, 0, 0, 0]:cdb6, SIZEOF cdb6, NIL)
            CASE ID_READTOC
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_CD_READ_TOC, 0, 0, 0, 0, 0, 1, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
            CASE ID_ATIP
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_CD_READ_TOC, 0, %00000100, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
            CASE ID_GETCONFIG
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_GET_CONFIG, %00000001, 0, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
            CASE ID_REWIND
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_SA_REWIND, 0, 0, 0, 0, 0]:cdb6, SIZEOF cdb6, NIL)
            CASE ID_SHOWLOGS
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_LIST, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
            CASE ID_PROBE
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                IF Val(probefrom) > Val(probeto)
                    FOR i:=Val(probefrom) TO Val(probeto) STEP -1 DO query(driver, i, [SCSI_INQUIRY, 0, 0, 0, BUFFSIZE, 0]:cdb6, SIZEOF cdb6, AFLG_INQUIRY_PROBE)
                ELSE
                    FOR i:=Val(probefrom) TO Val(probeto) DO query(driver, i, [SCSI_INQUIRY, 0, 0, 0, BUFFSIZE, 0]:cdb6, SIZEOF cdb6, AFLG_INQUIRY_PROBE)
                ENDIF
            CASE ID_DIAGNOSTIC
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                SELECT diagflag
                    CASE 0
                        query(driver, Val(unit), [SCSI_SEND_DIAGNOSTIC, P_DIAG_SIMPLE1, 0, 0, 0, 0]:cdb6, SIZEOF cdb6, NIL)
                    CASE 1
                        query(driver, Val(unit), [SCSI_SEND_DIAGNOSTIC, P_DIAG_SIMPLE2, 0, 0, 0, 0]:cdb6, SIZEOF cdb6, NIL)
                    CASE 2
                        IF Mui_RequestA(app, mui_main_win, 0, 'Warning!', '_Proceed|*_Cancel', 'A deep test may require the device to take itself offline temporarily\nor make temporary changes to the medium. It is highly recommended\nyou make sure nothing else is accessing the device before performing\nthis test.', NIL)<>0
                            query(driver, Val(unit), [SCSI_SEND_DIAGNOSTIC, P_DIAG_COMPLEX1, 0, 0, 0, 0]:cdb6, SIZEOF cdb6, NIL)
                        ENDIF
                    CASE 3
                        IF Mui_RequestA(app, mui_main_win, 0, 'Warning!', '_Proceed|*_Cancel', 'A deep test may require the device to take itself offline temporarily\nor make temporary changes to the medium. It is highly recommended\nyou make sure nothing else is accessing the device before performing\nthis test.', NIL)<>0
                            query(driver, Val(unit), [SCSI_SEND_DIAGNOSTIC, P_DIAG_COMPLEX2, 0, 0, 0, 0]:cdb6, SIZEOF cdb6, NIL)
                        ENDIF
                ENDSELECT
            CASE ID_MODESENSE
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                IF query(driver, Val(unit), [SCSI_INQUIRY, 0, 0, 0, BUFFSIZE, 0]:cdb6, SIZEOF cdb6, AFLG_INQUIRY_SILENT) = 0
                   IF query(driver, Val(unit), [SCSI_MODE_SENSE_10, 0, P_ALLPAGES, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL) <> 0
                       query(driver, Val(unit), [SCSI_MODE_SENSE_6, 0, P_ALLPAGES, 0, BUFFSIZE, 0]:cdb6, SIZEOF cdb6, NIL)
                   ENDIF
                ENDIF
            CASE ID_SHOWDEFECTS
                doMethodA(mui_output_lst, [MUIM_List_Clear])
                SELECT defectsflag
                    CASE 0
                        IF defectsformatflag = 0
                            query(driver, Val(unit), [SCSI_DA_READ_DEFECT_DATA, 0, %00010101, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                        ELSEIF defectsformatflag = 1
                            query(driver, Val(unit), [SCSI_DA_READ_DEFECT_DATA, 0, %00010100, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                        ELSE
                            query(driver, Val(unit), [SCSI_DA_READ_DEFECT_DATA, 0, %00010000, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                        ENDIF
                    CASE 1
                        IF defectsformatflag = 0
                            query(driver, Val(unit), [SCSI_DA_READ_DEFECT_DATA, 0, %00001101, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                        ELSEIF defectsformatflag = 1
                            query(driver, Val(unit), [SCSI_DA_READ_DEFECT_DATA, 0, %00001100, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                        ELSE
                            query(driver, Val(unit), [SCSI_DA_READ_DEFECT_DATA, 0, %00001000, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                        ENDIF                                  
                    CASE 2
                        IF defectsformatflag = 0
                            query(driver, Val(unit), [SCSI_DA_READ_DEFECT_DATA, 0, %00011101, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                        ELSEIF defectsformatflag = 1
                            query(driver, Val(unit), [SCSI_DA_READ_DEFECT_DATA, 0, %00011100, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                        ELSE
                            query(driver, Val(unit), [SCSI_DA_READ_DEFECT_DATA, 0, %00011000, 0, 0, 0, 0, BUFFSIZE, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                        ENDIF                    
                ENDSELECT
            CASE ID_ABOUT
                Mui_RequestA(app, mui_main_win, 0, 'About Q-Device!','*_OK','\ecQ-Device! by Ian Chapman (2003-2004)\nVersion 0.7\n\nA low-level SCSI/IDE query, control and diagnostic tool\n\n\ebUse of this software is entirely at YOUR OWN risk!\en', NIL)
            CASE ID_MUIABOUT
                doMethodA(app, [MUIM_Application_AboutMUI, mui_main_win])
            CASE ID_MUISET
                doMethodA(app, [MUIM_Application_OpenConfigWindow, 0])
            CASE ID_ICONIFY
                set(app, MUIA_Application_Iconified, MUI_TRUE)
            CASE ID_DOUBLECLICK
                click_inquiry()
            CASE ID_SAVELOG
                openfreq(mui_main_win)
                savelog(mui_main_win)  
        ENDSELECT
        IF (running AND signal) THEN Wait(signal)
    ENDWHILE

    EXCEPT DO
        IF (app) THEN Mui_DisposeObject(app)
        IF (diskobj) THEN FreeDiskObject(diskobj)
        IF (iconbase) THEN CloseLibrary(iconbase)
        IF (reqtoolsbase) THEN CloseLibrary(reqtoolsbase)
        IF (muimasterbase) THEN CloseLibrary(muimasterbase)
        SELECT exception
            CASE NORMAL
                ->Normal Exit
            CASE ERR_NOMUI
                PrintF('Unable to open muimaster.library V19+\n')
            CASE ERR_NOICON
                PrintF('Unable to open icon.library V33+\n')
            CASE ERR_NOREQTOOLS
                PrintF('Unable to open reqtools.library V39+\n')
            CASE ERR_NOAPP
                PrintF('Unable to create application\n')
            DEFAULT
                PrintF('Unknown exception of type (\d)\n', exception)
        ENDSELECT
ENDPROC


/*
** Procedure which distributes a query to the appropriate query procedure
** depending on whether it's a real SCSI device or the pseudo tcpip-scsi
** device. It is then responsible for distributing the results to the
** appropriate handler procedure for processing
*/
PROC query(device:PTR TO CHAR, unit, cmd:PTR TO cdb12, size, aflg)
DEF buffer=NIL, sensebuffer=NIL, returncode=0, returnexcept=0

    buffer:=New(BUFFSIZEBIG)
    sensebuffer:=New(BUFFSIZE)

    IF StrCmp(device, 'tcpip-scsi.device')
        returncode,returnexcept:=netquery(device, unit, cmd, size, buffer)
    ELSE
        returncode,returnexcept:=scsiquery(device, unit, cmd, size, buffer, sensebuffer)
    ENDIF

    IF returnexcept = 0
        SELECT returncode
            CASE 0
                IF cmd.opcode <> SCSI_REQUEST_SENSE THEN set(mui_status_tb, MUIA_Text_Contents, 'Target Response: GOOD')
                SELECT $FF OF cmd.opcode
                    CASE SCSI_CD_READ_TOC
                        IF (Char(cmd+2) = 0) THEN process_toc(buffer) ELSE process_atip(buffer)
                    CASE SCSI_TEST_UNIT_READY
                        outlist_d('Unit Ready', device, unit)
                    CASE SCSI_SA_REWIND
                        outlist_d('Sent rewind/rezero command', device, unit)   
                    CASE SCSI_INQUIRY
                        IF aflg=AFLG_INQUIRY_SERIAL THEN process_serial(buffer) ELSE process_inquiry(device, unit, buffer, aflg)
                    CASE SCSI_DA_READ_CAPACITY
                        process_capacity(buffer)
                    CASE SCSI_CD_START_STOP_UNIT
                        IF cmd.param4=P_EJECT
                            outlist_d('Sent eject command', device, unit)
                        ELSEIF cmd.param4=P_INSERT
                            outlist_d('Sent insert command', device, unit)
                        ELSEIF cmd.param4=P_START
                            outlist_d('Sent power up command', device, unit)
                        ELSEIF cmd.param4=P_STOP
                            outlist_d('Sent power down command', device, unit)
                        ENDIF
                    CASE SCSI_CD_PREVENT_ALLOW_MEDIUM_REMOVAL
                        IF cmd.param4=P_LOCK THEN outlist_d('Sent lock command', device, unit) ELSE outlist_d('Sent unlock command', device, unit)
                    CASE SCSI_REQUEST_SENSE
                        process_sense(buffer)
                    CASE SCSI_MODE_SENSE_6
                        process_modesense(buffer, size)
                    CASE SCSI_MODE_SENSE_10
                        process_modesense(buffer, size)
                    CASE SCSI_GET_CONFIG
                        process_feature(buffer)
                    CASE SCSI_LOG_SENSE
                        SELECT $3F OF Char(buffer)
                            CASE $0
                                outlist('\ebLog Type:\en', 'List of supported log types')
                                process_log_support(buffer)
                            CASE $1
                                process_log_buffer(buffer)
                            CASE $2
                                process_log_errors(buffer)
                            CASE $3
                                process_log_errors(buffer)
                            CASE $4
                                process_log_errors(buffer)
                            CASE $5
                                process_log_errors(buffer)
                            CASE $6
                                process_log_nmerrors(buffer)
                            CASE $D
                                process_log_temperature(buffer)
                            CASE $2F
                                process_log_ie(buffer)
                            CASE $30
                                IF alternatelog = 1
                                    process_log_smartsense(buffer)
                                    alternatelog:=0
                                ELSEIF alternatelog = 2
                                    process_log_performance(buffer)
                                    alternatelog:=0
                                ENDIF    
                            CASE $32
                                process_log_physical(buffer) 
                            CASE $33
                                process_log_lba(buffer)
                            CASE $35
                                process_log_cache(buffer)
                            CASE $36
                                process_log_ibmtemp(buffer)               
                        ENDSELECT
                    CASE SCSI_SEND_DIAGNOSTIC
                        outlist_d('Self Test Passed', device, unit)
                    CASE $37
                        process_defects(buffer)
                ENDSELECT
            CASE 2
            
                IF cmd.opcode <> SCSI_REQUEST_SENSE  -> Hopefully avoids recursive loops with bad devices/drivers which don't support request sense.                
                    set(mui_status_tb, MUIA_Text_Contents, 'Target Response: CHECK_CONDITION')
                    outlist('\ebWarning:\en', 'Command generated an error response (see below)')
                    IF autosenseflag = 1 THEN process_sense(sensebuffer) ELSE query(device, unit, [SCSI_REQUEST_SENSE, 0, 0, 0, BUFFSIZE, 0]:cdb6, SIZEOF cdb6, NIL)
                ENDIF
            
            CASE 4
                set(mui_status_tb, MUIA_Text_Contents, 'Target Response: CONDITION_MET')
            CASE 8
                set(mui_status_tb, MUIA_Text_Contents, 'Target Response: BUSY')
            CASE 16
                set(mui_status_tb, MUIA_Text_Contents, 'Target Response: INTERMEDIATE')
            CASE 20
                set(mui_status_tb, MUIA_Text_Contents, 'Target Response: INTERMEDIATE_CONDITION_MET')
            CASE 24
                set(mui_status_tb, MUIA_Text_Contents, 'Target Response: RESERVATION_CONFLICT')
            CASE 34
                set(mui_status_tb, MUIA_Text_Contents, 'Target Response: COMMAND_TERMINATED')
            CASE 72
                set(mui_status_tb, MUIA_Text_Contents, 'Target Response: QUEUE_FULL')
            DEFAULT
                set(mui_status_tb, MUIA_Text_Contents, 'Target Response: UNKNOWN')
        ENDSELECT
    ENDIF
    
    Dispose(buffer)
    Dispose(sensebuffer)
    
ENDPROC


/*
** Procedure for simply sending the SCSI command to the scsi device driver and
** writing the return data into the buffer for processing by the handler
** procedures
*/
PROC scsiquery(device:PTR TO CHAR, unit, cmd:PTR TO cdb12, size, buffer, sensebuffer) HANDLE
DEF myport=NIL:PTR TO mp, ioreq=NIL:PTR TO iostd, scsiio:scsicmd, error=-1, status

    IF (myport:=CreateMsgPort())=NIL THEN Raise(ERR_MP)
    IF (ioreq:=createStdIO(myport))=NIL THEN Raise(ERR_IOR)
    IF (error:=OpenDevice(device, unit, ioreq, 0)) <> NIL THEN Raise(ERR_DEVICE)

    scsiio.data:=buffer
    scsiio.length:=BUFFSIZEBIG
    scsiio.command:=cmd
    scsiio.cmdlength:=size

    IF autosenseflag > 0
        scsiio.flags:=SCSIF_READ OR SCSIF_AUTOSENSE
    ELSE
        scsiio.flags:=SCSIF_READ
    ENDIF

    scsiio.senseactual:=0
    scsiio.sensedata:=sensebuffer
    ioreq.command:=HD_SCSICMD
    ioreq.data:=scsiio
    ioreq.length:=SIZEOF scsicmd
    DoIO(ioreq)
    status:=ioreq.error

    SELECT status
        CASE HFERR_SELFUNIT
            outlist_d('<self issuing command error>', device, unit)
        CASE HFERR_DMA
            outlist_d('<DMA Failure>', device, unit)
        CASE HFERR_PHASE
            outlist_d('<illegal scsi phase>', device, unit)
        CASE HFERR_PARITY
            outlist_d('<parity error>', device, unit)
        CASE HFERR_SELTIMEOUT
            outlist_d('<device timed out>', device, unit)
    ENDSELECT

    EXCEPT DO
        IF error=NIL
            IF  CheckIO(ioreq)<>NIL
                AbortIO(ioreq)
                WaitIO(ioreq)
            ENDIF
        ENDIF

    CloseDevice(ioreq)
    IF ioreq <> NIL THEN deleteStdIO(ioreq)
    IF myport <> NIL THEN DeleteMsgPort(myport)

    SELECT exception
        CASE ERR_MP
            outlist('\ebError:\en', 'Unable to create message port')
        CASE ERR_IOR
            outlist('\ebError:\en', 'Unable to create IORequest')
        CASE ERR_DEVICE
            outlist_d('<no device>', device, unit)
    ENDSELECT

ENDPROC (scsiio.status AND %00111110), exception


/*
** Procedure for sending the scsi command across the network to a remote
** helper daemon such as qdd, then writing the return data into the buffer for
** processing by the handler procedures
*/
PROC netquery(device:PTR TO CHAR, unit, cmd:PTR TO cdb12, size, buffer) HANDLE
DEF sock, sain:PTR TO sockaddr_in, received=0, returncode=0, hst:PTR TO hostent,
    address:in_addr, saou:sockaddr_in, tv:timeval, readfds:fd_set

    IF (socketbase:=OpenLibrary('bsdsocket.library', NIL)) = NIL THEN Raise(ERR_NOBSD)
    sain:=NewM(SIZEOF sockaddr_in, MEMF_PUBLIC OR MEMF_CLEAR)
    IF (host[0] > 47) AND (host[0] < 58)
        address.addr:=Inet_addr(host)
        IF address.addr = INADDR_NONE THEN Raise(ERR_NOCONNECT)
        IF (hst:=Gethostbyaddr(address, SIZEOF in_addr, AF_INET)) = NIL THEN Raise(ERR_NOCONNECT)
    ELSE
        IF (hst:=Gethostbyname(host)) = NIL THEN Raise(ERR_NOCONNECT)
        address:=hst.addr_list[0]
    ENDIF

    sain.family:=AF_INET
    sain.addr.addr:=address.addr
    sain.port:=Val(port)+unit
    IF (sock:=Socket(AF_INET, SOCK_DGRAM, 0)) = -1 THEN Raise(ERR_NOSOCK)
    Sendto(sock, cmd, size, 0, sain, SIZEOF sockaddr_in)

    fd_zero(readfds)
    fd_set(sock, readfds)

    -> Some commands take a long time to complete, so increase the timeout value
    IF cmd.opcode = SCSI_SEND_DIAGNOSTIC
        tv.sec:=19
        tv.usec:=5
    ELSEIF cmd.opcode = SCSI_CD_START_STOP_UNIT
        tv.sec:=10
        tv.usec:=5
    ELSEIF cmd.opcode = SCSI_DA_START_STOP_UNIT
        tv.sec:=10
        tv.usec:=5
    ELSEIF cmd.opcode = $37
        tv.sec:=10
        tv.usec:=5
    ELSE
        tv.sec:=1
        tv.usec:=5
    ENDIF

    IF WaitSelect(sock+1, readfds, NIL, NIL, tv, 0) > 0
        IF fd_isset(sock, readfds)
            IF ((received:=Recvfrom(sock, buffer, BUFFSIZEBIG, 0, saou, SIZEOF sockaddr_in)) < 255)
                returncode:=Char(buffer)
            ENDIF
        ELSE
            Raise(ERR_NOCONNECT)
        ENDIF
    ELSE
        Raise(ERR_NOCONNECT)
    ENDIF

    EXCEPT DO
        IF sock <> -1 THEN CloseSocket(sock)
        IF (socketbase) THEN CloseLibrary(socketbase)
        SELECT exception
            CASE ERR_NOBSD
                outlist('\ebError:\en', 'Unable to open bsdsocket.library')
            CASE ERR_NOSOCK
                outlist('\ebError:\en', 'Unable to create socket')
            CASE ERR_NOCONNECT
                outlist_d('<no device> (or unable to connect)', device, unit)
        ENDSELECT

ENDPROC returncode, exception

/*
** Handler processing the data returned when requesting a list of known logs
** It then calls the handler processes for each known log type
*/
PROC process_log_support(reply:PTR TO l_sense)
DEF x=0

    outlist_i('\ebLog Size:\en', reply.len, ' bytes')
    outlist(' ', ' ')

    FOR x:=0 TO (reply.len-1)
        SELECT $3F OF Char(reply+x+4)
            CASE $0
                ->No real point in listing it, we know the disk supports it or we wouldn't get a reply
                ->outlist_h('\ebFound Log:\en', Char(reply+x+4), ':  List of supported log types')
            CASE $1
                outlist('\ebFound Log:\en', 'Buffer Over- and Under-runs')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' ')
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_BUFFER, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $2
                outlist('\ebFound Log:\en', 'Write Errors')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' ')
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_WRITE, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $3
                outlist('\ebFound Log:\en', 'Read Errors')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' ')
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_READ, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $4
                outlist('\ebFound Log:\en', 'Reverse-Read Errors')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' ')
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_REVREAD, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $5
                outlist('\ebFound Log:\en', 'Verify Errors')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' ')
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_VERIFY, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $6
                outlist('\ebFound Log:\en', 'Non-medium Errors')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' ')
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_NMERRORS, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $7
                outlist('\ebFound Log:\en', 'Last # of Error Events')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Not Decodable)')
                outlist(' ', ' ')
            CASE $8
                outlist('\ebFound Log:\en', 'Format Status')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $9
                outlist('\ebFound Log:\en', 'Reserved to the MS59 Standard')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $A
                outlist('\ebFound Log:\en', 'Reserved to the MS59 Standard')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $B
                outlist('\ebFound Log:\en', 'Last # deferred errors or Async Events')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $C
                outlist('\ebFound Log:\en', 'Sequential Access')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $D
                outlist('\ebFound Log:\en', 'Temperature')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' ')
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_TEMP, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $E
                outlist('\ebFound Log:\en', 'Start Stop Cycle')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $F
                outlist('\ebFound Log:\en', 'Application Client')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $10
                outlist('\ebFound Log:\en', 'Self Test Results')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $11
                outlist('\ebFound Log:\en', 'DTD Status')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $12
                outlist('\ebFound Log:\en', 'Tape Alert Response')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $13
                outlist('\ebFound Log:\en', 'Requested Recovery')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $14
                outlist('\ebFound Log:\en', 'Device Statistics')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $17
                outlist('\ebFound Log:\en', 'Non-Volatile Cache')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $18
                outlist('\ebFound Log:\en', 'Protocol Specific Port')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $2E
                outlist('\ebFound Log:\en', 'TapeAlert')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
            CASE $2F
                outlist('\ebFound Log:\en', 'Informational Exceptions Status')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), NIL)
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_IE, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $30
                outlist('\ebFound Log:\en', 'SMART Sense Data (Alternate Decoding #1)')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), NIL)
                alternatelog:=1
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_SMARTSENSE, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
                outlist('\ebFound Log:\en', 'Performance Counters (IBM)  (Alternate Decoding #2)')
                outlist('\ebWarning:\en', 'Log format may be device specific. Info may be incorrect')
                outlist('\ebReference:\en', 'IBM DGHS09Z')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), NIL)
                alternatelog:=2
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_PERFORMANCE, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $32
                outlist('\ebFound Log:\en:', 'Physical Error Sites (IBM)')
                outlist('\ebWarning:\en', 'Log format may be device specific. Info may be incorrect')
                outlist('\ebReference:\en', 'IBM DGHS09Z')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), NIL)
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_PHYSICAL, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ') 
            CASE $33
                outlist('\ebFound Log:\en:', 'LBA Error Sites (IBM)')
                outlist('\ebWarning:\en', 'Log format may be device specific. Info may be incorrect')
                outlist('\ebReference:\en', 'IBM DGHS09Z')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), NIL)
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_LBA, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ') 
            CASE $35
                outlist('\ebFound Log:\en', 'Cache Statistics (IBM)')
                outlist('\ebWarning:\en', 'Log format may be device specific. Info may be incorrect')
                outlist('\ebReference:\en', 'IBM DGHS09Z')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), NIL)
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_CACHE, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')
            CASE $36
                outlist('\ebFound Log:\en', 'Temperature Log (IBM)')
                outlist('\ebWarning:\en', 'Log format may be device specific. Info may be incorrect')
                outlist('\ebReference:\en', 'IBM DGHS09Z')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), NIL)
                query(driver, Val(unit), [SCSI_LOG_SENSE, 0, P_LOG_IBMTEMP, 0, 0, 0, 0, 0, BUFFSIZE, 0]:cdb10, SIZEOF cdb10, NIL)
                outlist(' ', ' ')                                          
            CASE $37
                outlist('\ebFound Log:\en', 'Cache Statistics (Seagate)')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode Yet)')
                outlist(' ', ' ')
            CASE $3E
                outlist('\ebFound Log:\en', 'Factory (Seagate)')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode yet)')
                outlist(' ', ' ')
            DEFAULT
                outlist('\ebFound Log:\en', 'Unknown Vendor Log')
                outlist_h('\ebLog Code:\en', Char(reply+x+4), ' (Cannot Decode)')
                outlist(' ', ' ')
        ENDSELECT
    ENDFOR
ENDPROC


/*
** The display hook for the listview. Entries are processed from an object
** and insert into the appropriate columns
*/
PROC disp(hook:PTR TO LONG, array:PTR TO LONG, entry:PTR TO listentry)

    IF entry=NIL -> MUI means update the titles whenever entry=NIL
        array[0]:='\eb\eu\ecField\en'
        array[1]:='\eb\eu\ecValue\en'
    ELSE
        array[0]:=entry.field
        array[1]:=entry.value
    ENDIF

ENDPROC 0


/*
** The construction hook for the listview. Memory needs to be reserved
** somewhere for each entry added, because only a pointer to a string actually
** gets inserted. This copies each string into memory reserved from a pool. The
** strings HAVE to be copied, as they will otherwise be freed by other
** procedures, meaning the pointers in the listview would suddenly be invalid.
*/
PROC construct (hook:PTR TO hook, pool:PTR TO LONG, obj:PTR TO listentry)
DEF value, field, driver=NIL, new:PTR TO listentry

    IF (field:=AllocPooled(pool, StrLen(obj.field)+1)) THEN CopyMem(obj.field, field, StrLen(obj.field)+1) -> +1 ensures NULL byte is copied
    IF (value:=AllocPooled(pool, StrLen(obj.value)+1)) THEN CopyMem(obj.value, value, StrLen(obj.value)+1) -> ditto
    IF obj.driver<>NIL
        IF (driver:=AllocPooled(pool, StrLen(obj.driver)+1)) THEN CopyMem(obj.driver, driver, StrLen(obj.driver)+1) -> ditto
    ENDIF
    new:=AllocPooled(pool, SIZEOF listentry)
    new.field:=field
    new.value:=value
    new.driver:=driver
    new.unit:=obj.unit
ENDPROC new


/*
** Whenever an entry is removed from the listview, this procedure frees the
** previously reserved memory for the strings.
*/
PROC destruct (hook:PTR TO hook, pool:PTR TO LONG, obj:PTR TO listentry)
    FreePooled(pool, obj.field, StrLen(obj.field)+1)
    FreePooled(pool, obj.value, StrLen(obj.value)+1)
    IF obj.driver<>NIL THEN FreePooled(pool, obj.driver, StrLen(obj.driver)+1)
    FreePooled(pool, obj, SIZEOF listentry)
ENDPROC


/*
** Simple macro procedure for making MUI buttons. Parameter 1 is the button
** face, parameter 2 is the bubble help text. The buttons are automatically
** added to the cycle chain
*/
PROC make_button(face, bubble)
DEF button

    button:=SimpleButton(face)
    SetAttrsA(button, [MUIA_ShortHelp, bubble, MUIA_CycleChain, 1, TAG_DONE])
ENDPROC button


/*
** Simple macro procedure for making MUI checkmarks. Parameter 1 is the default
** value, parameter 2 is the bubble help text. The checkmarks are automatically
** added to the cycle chain
*/
PROC make_checkmark(value, bubble)
DEF check

    check:=CheckMark(value)
    SetAttrsA(check, [MUIA_ShortHelp, bubble, MUIA_CycleChain, 1, TAG_DONE])
ENDPROC check


/*
** This procedure is called when the user double clicks and entry in the
** listview. It queries the hidden data (as handled by outlist_d()) to
** discover which device and unit to send the inquiry command to.
*/
PROC click_inquiry()
DEF entry:PTR TO listentry, driver[99]:STRING, unit[4]:STRING

    doMethodA(mui_output_lst, [MUIM_List_GetEntry, MUIV_List_GetEntry_Active, {entry}])
    
    IF entry.driver <> NIL
        StrCopy(driver, entry.driver)
        StringF(unit, '\d', entry.unit)
        set(mui_device_tb, MUIA_String_Contents, driver)
        set(mui_unit_tb, MUIA_String_Contents, unit)
        doMethodA(mui_output_lst, [MUIM_List_Clear])
        query(driver, Val(unit), [SCSI_INQUIRY, 0, 0, 0, 36, 0]:cdb6, SIZEOF cdb6, AFLG_INQUIRY_VERBOSE)=0
    ENDIF
ENDPROC


/*
** Procedure to fill an array with device drivers from the execlist. The array
** is used in the device driver poplist so the user can select one instead of
** manually typing it.
*/
PROC grab_devices()
DEF i=0, devnode:PTR TO ln, devlist:PTR TO lh, d[99]:STRING

    -> NOTE. This might need placing inside a Forbid()/Permit() pair but
    -> I'm not entirely certain about that.
    execobject:=execbase
    devlist:=execobject.devicelist
    devnode:=devlist.head

    WHILE devnode.succ
        StrCopy(d, devnode.name)
        IF StrCmp(d, 'audio.device')=TRUE           -> We only filter out
        ELSEIF StrCmp(d, 'audio.device')=TRUE       -> standard AmigaOS
        ELSEIF StrCmp(d, 'timer.device')=TRUE       -> drivers which are not
        ELSEIF StrCmp(d, 'gameport.device')=TRUE    -> appropriate. 
        ELSEIF StrCmp(d, 'keyboard.device')=TRUE    
        ELSEIF StrCmp(d, 'console.device')=TRUE   
        ELSEIF StrCmp(d, 'clipboard.device')=TRUE   
        ELSEIF StrCmp(d, 'ramdrive.device')=TRUE   
        ELSEIF StrCmp(d, 'input.device')=TRUE
        ELSEIF StrCmp(d, 'trackdisk.device')=TRUE
        ELSEIF StrCmp(d, 'serial.device')=TRUE
        ELSEIF StrCmp(d, 'printer.device')=TRUE
        ELSEIF StrCmp(d, 'parallel.device')=TRUE
        ELSE
            devicelist[i]:=devnode.name
            i++
        ENDIF
        devnode:=devnode.succ
    ENDWHILE
    ->Temporarily Removed
    devicelist[i]:='(DISABLED) tcpip-scsi.device'
    i++
    devicelist[i]:=NIL

ENDPROC


/*
** Procedure to open a reqtools file requester
*/
PROC openfreq(window)
DEF req:PTR TO rtfilerequester,
    fname[108]:STRING,
    q,
    ret,
    wptr
    
    StrCopy(fname, 'q-device.log')
    set(app, MUIA_Application_Sleep, MUI_TRUE)
    req:=RtAllocRequestA(RT_FILEREQ, NIL)
    GetAttr(MUIA_Window_Window, window, {wptr})
    RtChangeReqAttrA(req, [RTFI_DIR, 'Ram:', TAG_END])
    ret:=RtFileRequestA(req, fname, 'Choose logfile', [RT_WINDOW, wptr, RTFI_FLAGS, FREQF_SAVE OR FREQF_PATGAD, TAG_END])
    
    IF ret <> FALSE
        StrCopy(logpath, req.dir)
        q:=EstrLen(logpath)
        IF (logpath[q-1] <> 47)
            IF (logpath[q-1] <> 58) THEN StrAdd(logpath, '/', ALL)
        ENDIF
        StrAdd(logpath, fname, ALL)
    ENDIF
    
    IF req THEN RtFreeRequest(req)
    set(app, MUIA_Application_Sleep, FALSE)

ENDPROC    


/*
** Procedure to save the entries from the output listview
*/
PROC savelog(window)
DEF entry:PTR TO listentry,
    fh,
    total,
    i,
    line[500]:STRING
    
    IF fh:=Open(logpath, MODE_READWRITE)
        Seek(fh, 0, OFFSET_END) 
        GetAttr(MUIA_List_Entries, mui_output_lst, {total})
    
        FOR i:=0 TO (total - 1)
            doMethodA(mui_output_lst, [MUIM_List_GetEntry, i, {entry}])
            MidStr(line, entry.field, 2, StrLen(entry.field) - 4)
            StrAdd(line, ' ')
            StrAdd(line, entry.value)
            StrAdd(line, '\n')
            Write(fh, line, EstrLen(line))         
        ENDFOR
        Close(fh)
    ELSE
        Mui_RequestA(app, window, 0, 'Error', '_OK', '\ecUnable to save file!\nPlease make sure the filename is valid\nand the disk/file is not write-protected\en', NIL)
    ENDIF
    
ENDPROC
