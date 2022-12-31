OPT MODULE
OPT EXPORT

MODULE '*/listview/outlist',
       '*/scsi/headers',
       '*/scsi/params'

DEF global_devtype

/*
** This procedure handles the data returned from a mode sense request
** (ie Device Parameters). It is quite complex because the data is in the form
** of many pages which have to be processed. In addition to that, a page type
** may have to be processed differently, or have a different meaning depending
** on the type of device queried. It's the master procedure for mode sense data
** and farms off the actual decoding to the specific page type handlers.
*/
PROC process_modesense(reply:PTR TO m_sense10, modesize)
DEF reply2:PTR TO m_sense6,
    page:PTR TO CHAR,
    pagetype,    
    datalen=0,
    descriptor:PTR TO b_descriptor,
    medium=0,
    desclen=0,
    devpar=0

    reply2:=reply
    
    IF modesize = 10 
        medium:=reply.medium
        datalen:=reply.datalen
        desclen:=reply.desclen
        devpar:=reply.devpar AND %10000000
        descriptor:=reply + SIZEOF m_sense10
        page:= reply + SIZEOF m_sense10 + desclen
        outlist('\ebMode Sense Cmdsize:\en', '10 bytes')
    ELSE
        medium:=reply2.medium
        datalen:=reply2.datalen
        desclen:=reply2.desclen
        devpar:=reply2.devpar AND %10000000
        descriptor:=reply2 + SIZEOF m_sense6
        page:= reply2 + SIZEOF m_sense6 + desclen
        outlist('\ebMode Sense Cmdsize:\en', '6 bytes')
    ENDIF
    
    outlist_i('\ebMode Data Length:\en', datalen, ' bytes')
        
    SELECT $F OF global_devtype
        CASE DEV_DIRECT
            IF medium = $0
                outlist('\ebInserted Medium Type:\en','Default')
            ELSEIF medium = $1
                outlist('\ebInserted Medium Type:\en','Flexible disk, single-sided; unspecified medium') 
            ELSEIF medium = $2
                outlist('\ebInserted Medium Type:\en','Flexible disk, double-sided; unspecified medium')
            ELSEIF medium = $5
                outlist('\ebInserted Medium Type:\en','Diameter: 8", Bit Dens.: 6, TPI: 48, Sides: 1')
            ELSEIF medium = $6
                outlist('\ebInserted Medium Type:\en','Diameter: 8", Bit Dens.: 6, TPI: 48, Sides: 2')
            ELSEIF medium = $9
                outlist('\ebInserted Medium Type:\en','Diameter: 8", Bit Dens.: 13, TPI: 48, Sides: 1')
            ELSEIF medium = $A
                outlist('\ebInserted Medium Type:\en','Diameter: 8", Bit Dens.: 13, TPI: 48, Sides: 2')
            ELSEIF medium = $D
                outlist('\ebInserted Medium Type:\en','Diameter: 5.25", Bit Dens.: 13, TPI: 48, Sides: 1')
            ELSEIF medium = $12
                outlist('\ebInserted Medium Type:\en','Diameter: 5.25", Bit Dens.: 7, TPI: 48, Sides: 2')
            ELSEIF medium = $16
                outlist('\ebInserted Medium Type:\en','Diameter: 5.25", Bit Dens.: 7, TPI: 96, Sides: 2')
            ELSEIF medium = $1A
                outlist('\ebInserted Medium Type:\en','Diameter: 5.25", Bit Dens.: 13, TPI: 96, Sides: 2')
            ELSEIF medium = $1E
                outlist('\ebInserted Medium Type:\en','Diameter: 3.5", Bit Dens.: 7, TPI: 135, Sides: 2')
            ELSEIF medium = $40
                outlist('\ebInserted Medium Type:\en','Width: 0.25", Tracks 12, FTPI: 10,000')
            ELSEIF medium = $44
                outlist('\ebInserted Medium Type:\en','Width: 0.25", Tracks 24, FTPI: 10,000')
            ELSE
                outlist('\ebInserted Medium Type:\en','Reserved or vendor specific')
            ENDIF  
        CASE DEV_WRITEONCE, DEV_OPTICAL  
            IF medium = $0
                outlist('\ebInserted Medium Type:\en','Default')
            ELSEIF medium = $1
                outlist('\ebInserted Medium Type:\en','Optical Read Only Medium') 
            ELSEIF medium = $2
                outlist('\ebInserted Medium Type:\en','Optical Write Once Medium')
            ELSEIF medium = $3
                outlist('\ebInserted Medium Type:\en','Optical Reversible/Erasable Medium')
            ELSEIF medium = $4
                outlist('\ebInserted Medium Type:\en','Combination Read Only/Write Once')
            ELSEIF medium = $5
                outlist('\ebInserted Medium Type:\en','Combination Read Only/Write Once/Reversible/Erasable')
            ELSEIF medium = $6
                outlist('\ebInserted Medium Type:\en','Combination Write Once/Reversible/Erasable')
            ELSE
                outlist('\ebInserted Medium Type:\en','Reserved or vendor specific')
            ENDIF                  
        CASE DEV_CDROM
            IF medium = $0
                outlist('\ebInserted Medium Type:\en','Default')
            ELSEIF medium = $1
                outlist('\ebInserted Medium Type:\en','120 mm CD-ROM data only') 
            ELSEIF medium = $2
                outlist('\ebInserted Medium Type:\en','120 mm CD-DA audio only')
            ELSEIF medium = $3
                outlist('\ebInserted Medium Type:\en','120 mm CD-ROM data and audio combined')
            ELSEIF medium = $5
                outlist('\ebInserted Medium Type:\en','80 mm CD-ROM data only')
            ELSEIF medium = $6
                outlist('\ebInserted Medium Type:\en','80 mm CD-DA audio only')
            ELSEIF medium = $7
                outlist('\ebInserted Medium Type:\en','80 mm CD-ROM data and audio combined')
            ELSE
                outlist('\ebInserted Medium Type:\en','Reserved or vendor specific')
            ENDIF             
        DEFAULT
            outlist('\ebInserted Medium Type:\en','Reserved or vendor specific')         
    ENDSELECT
        
    IF (devpar = 0) THEN outlist('\ebWrite Protected:\en', 'No') ELSE outlist('\ebWrite Protected:\en', 'Yes')
    outlist_i('\ebDescriptor Length:\en', desclen, ' bytes')    
    
    WHILE (descriptor < page ) 
            
        SELECT $F OF global_devtype 
            CASE DEV_SEQUENTIAL
                IF Shr((descriptor.blocks AND $FF000000), 24) = $0
                    outlist('\ebDensity Code:\en','Default')   
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $1
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 9, Density: 32, Code: NRZI, Type: Reel')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $2    
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 9, Density: 63, Code: PE, Type: Reel')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $3
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 9, Density: 246, Code: GCR, Type: Reel')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $5    
                    outlist('\ebDensity Code:\en','Width: 0.25", Tracks: 4/9, Density: 315, Code: GCR, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $6   
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 9, Density: 126, Code: PE, Type: Reel')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $7    
                    outlist('\ebDensity Code:\en','Width: 0.25", Tracks: 4, Density: 252, Code: IMFM, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $8
                    outlist('\ebDensity Code:\en','Width: 0.15", Tracks: 4, Density: 315, Code: GCR, Type: Cassette')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $9    
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 18, Density: 1491, Code: GCR, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $A
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 22, Density: 262, Code: MFM, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $B
                    outlist('\ebDensity Code:\en','Width: 0.25", Tracks: 4, Density: 63, Code: PE, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $C
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 24, Density: 500, Code: GCR, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $D
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 4, Density: 999, Code: GCR, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $F
                    outlist('\ebDensity Code:\en','Width: 0.25", Tracks: 15, Density: 394, Code: GCR, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $10
                    outlist('\ebDensity Code:\en','Width: 0.25", Tracks: 18, Density: 394, Code: GCR, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $11
                    outlist('\ebDensity Code:\en','Width: 0.25", Tracks: 26, Density: 630, Code: GCR, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $12
                    outlist('\ebDensity Code:\en','Width: 0.25", Tracks: 30, Density: 2034, Code: RLL, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $13
                    outlist('\ebDensity Code:\en','Width: 0.15", Tracks: 1, Density: 2400, Code: DDS, Type: Cassette')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $14
                    outlist('\ebDensity Code:\en','Width: 0.315", Tracks: 1, Density: 1703, Code: RLL, Type: Cassette')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $15
                    outlist('\ebDensity Code:\en','Width: 0.315", Tracks: 1, Density: 1789, Code: RLL, Type: Cassette')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $16
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 48, Density: 394, Code: MFM, Type: Cartridge')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $17
                    outlist('\ebDensity Code:\en','Width: 0.5", Tracks: 48, Density: 1673, Code: MFM, Type: Cartridge')
                ELSE
                    outlist('\ebDensity Code:\en','Reserved or vendor specific')
                ENDIF    
           CASE DEV_WRITEONCE, DEV_OPTICAL  
                IF Shr((descriptor.blocks AND $FF000000), 24) = $0
                    outlist('\ebDensity Code:\en','Default')   
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $1
                    outlist('\ebDensity Code:\en','Diameter: 3.5", Type: Read/Write, Sector: 512/1024, Tracks: 12500, Sides: 1')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $2    
                    outlist('\ebDensity Code:\en','Diameter: 3.5", Type: Read/Write, Sector: 512/1024, Tracks: 12500, Sides: 2')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $3
                    outlist('\ebDensity Code:\en','Diameter: 5.25", Type: Read/Write, Sector: 512/1024, Tracks: 18750, Sides: 2')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $4    
                    outlist('\ebDensity Code:\en','Diameter: 5.25", Type: Write Once, Sector: 512/1024, Tracks: 30000, Sides: 2')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $5   
                    outlist('\ebDensity Code:\en','Diameter: 5.25", Type: Write Once, Sector: 512/1024, Tracks: 20000, Sides: 2')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $6    
                    outlist('\ebDensity Code:\en','Diameter: 5.25", Type: Write Once, Sector: 512/1024, Tracks: 18750, Sides: 2')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $7
                    outlist('\ebDensity Code:\en','Diameter: 8"')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $8    
                    outlist('\ebDensity Code:\en','Diameter: 12", Sector: 1024, Sides: 2')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $9    
                    outlist('\ebDensity Code:\en','Diameter: 14", Sector: 1024, Tracks: 56350, Sides: 2')
                ELSE
                    outlist('\ebDensity Code:\en','Reserved or vendor specific')
                ENDIF             
            CASE DEV_CDROM
                IF Shr((descriptor.blocks AND $FF000000), 24) = $0
                   outlist('\ebDensity Code:\en','Default')   
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $1
                    outlist('\ebDensity Code:\en','User Data Only, Physical Sector: 2048')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $2    
                    outlist('\ebDensity Code:\en','User and Auxiliary Data, Physical Sector: 2336')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $3
                    outlist('\ebDensity Code:\en','4 Byte Tag, User and Auxiliary Data, Physical Sector: 2340')
                ELSEIF Shr((descriptor.blocks AND $FF000000), 24) = $4    
                    outlist('\ebDensity Code:\en','Audio Only')
                ELSE
                    outlist('\ebDensity Code:\en','Reserved or vendor specific')
                ENDIF 
            DEFAULT
                outlist('\ebDensity Code:\en','Reserved or vendor specific')
        ENDSELECT
            
        outlist_i('\ebNumber of Blocks:\en', (descriptor.blocks AND $00FFFFFF),NIL)
        outlist_i('\ebBlock Length:\en', (descriptor.blocklen AND $00FFFFFF), ' bytes')
        descriptor:=descriptor + SIZEOF b_descriptor
    ENDWHILE
            
    WHILE page < (reply + datalen)
        pagetype:=(Char(page) AND %00111111)
        outlist(' ', ' ')
        SELECT pagetype
            CASE $1
                process_modesense_1(page)
            CASE $2
                process_modesense_2(page)
            CASE $3
                process_modesense_3(page)
            CASE $4
                process_modesense_4(page)
            CASE $5
                process_modesense_5(page)
            CASE $6
                process_modesense_6(page)    
            CASE $7
                process_modesense_7(page)
            CASE $8
                process_modesense_8(page)
            CASE $9
                process_modesense_9(page)
            CASE $A
                process_modesense_A(page)
            CASE $B
                process_modesense_B(page)
            CASE $C
                process_modesense_C(page)
            CASE $D
                process_modesense_D(page)
            CASE $E
                process_modesense_E(page)
            CASE $F
                process_modesense_F(page)
            CASE $10
                process_modesense_10(page)
            CASE $11
                process_modesense_11(page)
            CASE $12
                process_modesense_12(page)
            CASE $13
                process_modesense_13(page)
            CASE $14
                process_modesense_14(page)
            CASE $18
                process_modesense_18(page)
            CASE $19
                process_modesense_19(page)
            CASE $1A
                process_modesense_1A(page)
            CASE $1C
                process_modesense_1C(page)
            CASE $1D
                process_modesense_1D(page)  
            CASE $1E
                process_modesense_1E(page)      
            CASE $1F
                process_modesense_1F(page)    
            CASE $20
                process_modesense_20(page)
            CASE $21
                process_modesense_21(page)    
            CASE $2A
                process_modesense_2A(page)
            CASE $2F
                process_modesense_2F(page)    
            CASE $39
                process_modesense_39(page)
            DEFAULT
                outlist('\ebInformation Page:\en', 'Vendor Specific')
                outlist_h('\ebPage Code:\en', pagetype , NIL)
                outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        ENDSELECT

        page:=(page + Char(page+1) +2)

    ENDWHILE
ENDPROC

/*
** Handler for a specific mode page
*/
PROC process_modesense_1(page) -> DONE

    SELECT $A OF global_devtype
        CASE DEV_DIRECT, DEV_OPTICAL, DEV_WRITEONCE
            outlist('\ebInformation Page:\en', 'Read/Write Error Recovery')
            outlist('\ebPage Code:\en', '$1')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM Supported:\en', 'No') ELSE outlist('\ebSave to NVRAM Supported:\en', 'Yes')
            outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
            IF (Char(page+2) AND %10000000) = 0 THEN outlist('\ebAutomatic Write Reallocation:\en', 'No') ELSE  outlist('\ebAutomatic Write Reallocation:\en', 'Yes')
            IF (Char(page+2) AND %01000000) = 0 THEN outlist('\ebAutomatic Read Reallocation:\en', 'No') ELSE outlist('\ebAutomatic Read Reallocation:\en', 'Yes')
            IF (Char(page+2) AND %00100000) = 0 THEN outlist('\ebTransfer Block (TB):\en', 'Don\at transfer erroneous block to initiator') ELSE outlist('\ebTransfer Block (TB):\en', 'Transfer erroneous block to initiator')
            IF (Char(page+2) AND %00010000) = 0 THEN outlist('\ebRead Continuous (RC):\en', 'Tolerate error recovery delays') ELSE outlist('\ebRead Continuous (RC):\en', 'Don\at tolerate error recovery delays')
            IF (Char(page+2) AND %00001000) = 0 THEN outlist('\ebEnable Early Recovery (EER):\en', 'Minimise risk of error mis-correction') ELSE outlist('\ebEnable Early Recovery (EER):\en', 'Always use fastest error recovery method')
            IF (Char(page+2) AND %00000100) = 0 THEN outlist('\ebPost Recoverable Error (PER):\en', 'Don\at report recovered errors') ELSE outlist('\ebPost Recoverable Error (PER):\en', 'Report recovered errors')
            IF (Char(page+2) AND %00000010) = 0 THEN outlist('\ebDisable Transfer on Error (DTE):\en', 'Don\at terminate data phase on error') ELSE outlist('\ebDisable Transfer on Error (DTE):\en', 'Terminate data phase on error')
            IF (Char(page+2) AND %00000001) = 0 THEN outlist('\ebDisable Correction (DCR):\en', 'Use error correction codes') ELSE outlist('\ebDisable Correction (DCR):\en', 'Error correction codes not used')
            outlist_i('\ebRetries on Read Error:\en', Char(page+3), NIL)
            outlist_i('\ebCorrection Span:\en', Char(page+4), ' bits')
            outlist_i('\ebHead Offset Count:\en', Char(page+5), NIL)
            outlist_i('\ebData Strobe Offset Count:\en', Char(page+6), NIL)
            IF (Char(page+1) > 6) -> possible fix for zip drives only return 6 bytes
                outlist_i('\ebRetries on Write Error:\en', Char(page+8), NIL)
                outlist_i('\ebRecovery Time Limit:\en', Int(page+10), ' ms')
            ENDIF
        CASE DEV_SEQUENTIAL 
            outlist('\ebInformation Page:\en', 'Read/Write Error Recovery')
            outlist('\ebPage Code:\en', '$1')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM Supported:\en', 'No') ELSE outlist('\ebSave to NVRAM Supported:\en', 'Yes')
            outlist_i('\ebPage Length:\en', Char(page+1), NIL)
            IF (Char(page+2) AND %00100000) = 0 THEN outlist('\ebTransfer Block (TB):\en', 'Don\at transfer erroneous block to initiator') ELSE outlist('\ebTransfer Block (TB):\en', 'Transfer erroneous block to initiator')
            IF (Char(page+2) AND %00001000) = 0 THEN outlist('\ebEnable Early Recovery (EER):\en', 'Minimise risk of error mis-correction') ELSE outlist('\ebEnable Early Recovery (EER):\en', 'Always use fastest error recovery method')
            IF (Char(page+2) AND %00000100) = 0 THEN outlist('\ebPost Recoverable Error (PER):\en', 'Don\at report recovered errors') ELSE outlist('\ebPost Recoverable Error (PER):\en', 'Report recovered errors')
            IF (Char(page+2) AND %00000010) = 0 THEN outlist('\ebDisable Transfer on Error (DTE):\en', 'Don\at terminate data phase on error') ELSE outlist('\ebDisable Transfer on Error (DTE):\en', 'Terminate data phase on error')
            IF (Char(page+2) AND %00000001) = 0 THEN outlist('\ebDisable Correction (DCR):\en', 'Use error correction codes') ELSE outlist('\ebDisable Correction (DCR):\en', 'Error correction codes not used')
            outlist_i('\ebRetries on Read Error:\en', Char(page+3), NIL)
            outlist_i('\ebRetries on Write Error:\en', Char(page+8), NIL)
        CASE DEV_CDROM            
            outlist('\ebInformation Page:\en', 'Read/Write Error Recovery')
            outlist('\ebPage Code:\en', '$1')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM Supported:\en', 'No') ELSE outlist('\ebSave to NVRAM Supported:\en', 'Yes')            
            outlist_i('\ebPage Length:\en', Char(page+1), NIL)
            IF (Char(page+2) AND %10000000) = 0 THEN outlist('\ebAutomatic Write Reallocation:\en', 'No') ELSE  outlist('\ebAutomatic Write Reallocation:\en', 'Yes')
            IF (Char(page+2) AND %01000000) = 0 THEN outlist('\ebAutomatic Read Reallocation:\en', 'No') ELSE outlist('\ebAutomatic Read Reallocation:\en', 'Yes')
            IF (Char(page+2) AND %00100000) = 0 THEN outlist('\ebTransfer Block (TB):\en', 'Don\at transfer erroneous block to initiator') ELSE outlist('\ebTransfer Block (TB):\en', 'Transfer erroneous block to initiator')
            IF (Char(page+2) AND %00010000) = 0 THEN outlist('\ebRead Continuous (RC):\en', 'Tolerate error recovery delays') ELSE outlist('\ebRead Continuous (RC):\en', 'Don\at tolerate error recovery delays')
            IF (Char(page+2) AND %00001000) = 0 THEN outlist('\ebEnable Early Recovery (EER):\en', 'Minimise risk of error mis-correction') ELSE outlist('\ebEnable Early Recovery (EER):\en', 'Always use fastest error recovery method')
            IF (Char(page+2) AND %00000100) = 0 THEN outlist('\ebPost Recoverable Error (PER):\en', 'Don\at report recovered errors') ELSE outlist('\ebPost Recoverable Error (PER):\en', 'Report recovered errors')
            IF (Char(page+2) AND %00000010) = 0 THEN outlist('\ebDisable Transfer on Error (DTE):\en', 'Don\at terminate data phase on error') ELSE outlist('\ebDisable Transfer on Error (DTE):\en', 'Terminate data phase on error')
            IF (Char(page+2) AND %00000001) = 0 THEN outlist('\ebDisable Correction (DCR):\en', 'Use error correction codes') ELSE outlist('\ebDisable Correction (DCR):\en', 'Error correction codes not used')
            outlist_i('\ebRetries on Read Error:\en', Char(page+3), NIL)
        DEFAULT
            outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
            outlist('\ebPage Code:\en', '$1')
    ENDSELECT

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_2(page) ->DONE

    outlist('\ebInformation Page:\en', 'Disconnection and Reconnection Parameters')
    outlist('\ebPage Code:\en', '$2')
    IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM Supported:\en', 'No') ELSE outlist('\ebSave to NVRAM Supported:\en', 'Yes')    
    outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
    outlist_i('\ebBuffer Full Ratio:\en', Char(page+2), NIL)
    outlist_i('\ebBuffer Empty Ratio:\en', Char(page+3), NIL)
    outlist_i('\ebBus Inactivity Limit:\en', Int(page+4), ' *100 us')
    outlist_i('\ebDisconnect Time Limit:\en', Int(page+6), ' *100 us')
    outlist_i('\ebConnect Time Limit:\en', Int(page+8), ' *100 us')
    outlist_i('\ebMaximum Burst Size:\en', Int(page+10), ' *512 bytes')
    
    IF ((Char(page+12) AND %00000011) = 0)
        outlist('\ebData Transfer Disconnect Control:\en', 'Not Used')
    ELSEIF ((Char(page+12) AND %00000011) = 1)
        outlist('\ebData Transfer Disconnect Control:\en', 'No disconnection until command and data transferred')
    ELSEIF ((Char(page+12) AND %00000011) = 2)    
        outlist('\ebData Transfer Disconnect Control:\en', 'Reserved')
    ELSE
        outlist('\ebData Transfer Disconnect Control:\en', 'No disconnection until command complete')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_3(page) -> DONE

    IF global_devtype=DEV_DIRECT 
        outlist('\ebInformation Page:\en', 'Formatting Parameters')
        outlist('\ebPage Code:\en', '$3')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebTracks Per Zone:\en', Int(page+2), NIL)
        outlist_i('\ebAlternate Sectors Per Zone:\en', Int(page+4), NIL)
        outlist_i('\ebAlternate Tracks Per Zone:\en', Int(page+6), NIL)
        outlist_i('\ebAlternate Tracks Per Logical Unit:\en', Int(page+8), NIL)
        outlist_i('\ebSectors Per Track:\en', Int(page+10), NIL)
        outlist_i('\ebBytes Per Physical Sector:\en', Int(page+12), NIL)
        outlist_i('\ebInterleave:\en', Int(page+14), NIL)
        outlist_i('\ebTrack Skew Factor:\en', Int(page+16), ' sectors')
        outlist_i('\ebCylinder Skew Factor:\en', Int(page+18), ' sectors')
        IF ((Char(page+20) AND %10000000) = 0) THEN outlist('\ebSupports Soft Sector Formatting:\en', 'No') ELSE outlist('\ebSupports Soft Sector Formatting:\en', 'Yes')
        IF ((Char(page+20) AND %01000000) = 0) THEN outlist('\ebSupports Hard Sector Formatting:\en', 'No') ELSE outlist('\ebSupports Hard Sector Formatting:\en', 'Yes')
        IF ((Char(page+20) AND %00100000) = 0) THEN outlist('\ebSupports Removable Media:\en', 'No') ELSE outlist('\ebSupports Removable Media:\en', 'Yes')
        IF ((Char(page+20) AND %00010000) = 0) THEN outlist('\ebSurface Bit:\en', 'Off') ELSE outlist('\ebSurface:\en', 'On')       
    ELSEIF global_devtype=DEV_SCANNER
        outlist('\ebInformation Page:\en', 'Measurement Units')
        outlist('\ebPage Code:\en', '$3')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')                 
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        
        IF (Char(page+2) = 0 )
            outlist('\ebBasic Measurement Unit:\en', 'Inch')
        ELSEIF (Char(page+2) = 1 )
            outlist('\ebBasic Measurement Unit:\en', 'Millimetre') 
        ELSEIF (Char(page+2) = 1 )
            outlist('\ebBasic Measurement Unit:\en', 'Point') 
        ELSE
            outlist('\ebBasic Measurement Unit:\en', 'Reserved (Vendor Specific Unit)')
        ENDIF
        
        outlist_i('\ebMeasurement Unit Divisor:\en', Int(page+4), ' units = 1 Basic Measurement Unit')
    ELSEIF global_devtype=DEV_PRINTER
        outlist('\ebInformation Page:\en', 'Parallel Printer Interface')
        outlist('\ebPage Code:\en', '$3')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        
        IF ( (Char(page+2) AND %11000000) = 192 )
            outlist('\ebParity Select:\en:', 'Reserved')
        ELSEIF ( (Char(page+2) AND %10000000) = 128 )
            outlist('\ebParity Select:\en:', 'Odd Parity')
        ELSEIF ( (Char(page+2) AND %01000000) = 64 )
            outlist('\ebParity Select:\en:', 'Even Parity')
        ELSE
            outlist('\ebParity Select:\en:', 'No Parity')
        ENDIF
        
        IF ( (Char(page+2) AND %00100000) = 32)
            outlist('\ebPaper Instruction Parity Check:\en', 'Included in parity generation')
        ELSE
            outlist('\ebPaper Instruction Parity Check:\en', 'Not included in parity generation')
        ENDIF
        
        IF ( (Char(page+2) AND %00001000) = 8)
            outlist('\ebVCBP:\en', 'On')
        ELSE
            outlist('\ebVCBP:\en', 'Off')
        ENDIF
        
        IF ( (Char(page+2) AND %00000100) = 4)
            outlist('\ebVCBS:\en', 'On')
        ELSE
            outlist('\ebVCBS:\en', 'Off')
        ENDIF
        
        IF ( (Char(page+2) AND %00000010) = 2)
            outlist('\ebVES:\en', 'On')
        ELSE
            outlist('\ebVES:\en', 'Off')
        ENDIF
        
        IF ( (Char(page+2) AND %00000001) = 1)
            outlist('\ebAutomatic Line Feed:\en', 'Assert Auto Line Feed Signal')
        ELSE
           outlist('\ebAutomatic Line Feed:\en', 'Negate Auto Line Feed Signal') 
        ENDIF
        
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$3')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_4(page) ->DONE

    IF global_devtype=DEV_DIRECT
        outlist('\ebInformation Page:\en', 'Rigid Disk Geometry Parameters')
        outlist('\ebPage Code:\en', '$4')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebCylinders:\en', And(Long(page+1), $00FFFFFF) , NIL)
        outlist_i('\ebHeads:\en', Char(page+5), NIL)
        outlist_i('\ebStart Write PreComp:\en', And(Long(page+5), $00FFFFFF), NIL)
        outlist_i('\ebStart Reduced Write:\en', And(Long(page+8), $00FFFFFF), NIL)
        IF (Int(page+12) = 0) THEN outlist('\ebStep Rate:\en', 'Device Default') ELSE outlist_i('\ebStep Rate:\en', Int(page+12), ' *100 ns')
        outlist_i('\ebLanding Cylinder:\en', And(Long(page+13), $00FFFFFF), NIL)
        outlist_i('\ebRotational Offset:\en', Char(page+18), NIL)
        outlist_i('\ebRotation Rate:\en', Int(page+20), ' rpm')
    ELSEIF global_devtype=DEV_PRINTER
        outlist('\ebInformation Page:\en', 'Serial Printer Interface')
        outlist('\ebPage Code:\en', '$4')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebStop Bit Length:\en', (Char(page+2) AND %00111111), ' (1/16 bit)')
        
        IF ( (Char(page+3) AND %11100000) = 0)
            outlist('\ebParity Selection:\en', 'None')
        ELSEIF ( (Char(page+3) AND %11100000) = 32)
            outlist('\ebParity Selection:\en', 'Mark')
        ELSEIF ( (Char(page+3) AND %11100000) = 64)    
            outlist('\ebParity Selection:\en', 'Space')
        ELSEIF ( (Char(page+3) AND %11100000) = 96)      
            outlist('\ebParity Selection:\en', 'Odd')
        ELSEIF ( (Char(page+3) AND %11100000) = 128)    
            outlist('\ebParity Selection:\en', 'Even')
        ELSE
            outlist('\ebParity Selection:\en', 'Reserved')
        ENDIF    
        
        outlist_i('\ebBits Per Character:\en', (Char(page+3) AND %00001111), ' bits')        
        IF ( (Char(page+4) AND %10000000) = 0) THEN outlist('\ebRequest To Send (RTS):\en', 'RTS on when power on') ELSE outlist('\ebRequest To Send (RTS):\en', 'Follows state of DTR signal')      
        IF ( (Char(page+4) AND %01000000) = 0) THEN outlist('\ebClear To Send (CTS):\en', 'Ignored') ELSE outlist('\ebClear To Send (CTS):\en', 'Used')
        
        IF ( (Char(page+4) AND %00001111) = 0)     
            outlist('\ebPacing Protocol:\en', 'None')
        ELSEIF  ( (Char(page+4) AND %00001111) = 1)
            outlist('\ebPacing Protocol:\en', 'XON/XOFF')
        ELSEIF  ( (Char(page+4) AND %00001111) = 2)
           outlist('\ebPacing Protocol:\en', 'ETX/ACK') 
        ELSEIF  ( (Char(page+4) AND %00001111) = 3)
           outlist('\ebPacing Protocol:\en', 'DTR') 
        ELSE
           outlist('\ebPacing Protocol:\en', 'Reserved or Vendor Specific') 
        ENDIF 
        
        outlist_i('\ebBaud Rate:\en', (Long(page+4) AND $FFFFFF) ,' bits per second')   
     
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$4')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_5(page) -> DONE

    IF global_devtype=DEV_DIRECT 
        outlist('\ebInformation Page:\en', 'Flexible Disk Geometry')
        outlist('\ebPage Code:\en', '$5')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebTransfer Rate\en', (Int(page+2)/8), ' K/sec')
        outlist_i('\ebHeads\en:', Char(page+4), NIL)
        outlist_i('\ebSectors Per Track:\en', Char(page+5), NIL)
        outlist_i('\ebBytes Per Sector:\en', Int(page+6), NIL)
        outlist_i('\ebCylinders:\en', Int(page+8), NIL)
        outlist_i('\ebStarting Cylinder Write Pre-Compensation:\en:', Int(page+10), NIL)
        outlist_i('\ebStarting Cylinder Reduced Write Current:\en:', Int(page+12), NIL)        
        IF Int(page+14) = 0 THEN outlist('\ebStep Rate\en:', 'Device Default') ELSE outlist_i('\ebStep Rate:\en', Int(page+14), ' *100 us')
        outlist_i('\ebDrive Step Pulse Width:\en:', Char(page+16), ' us')
        outlist_i('\ebHead Settle Delay:\en:', Int(page+17), ' *100us')
        outlist_i('\ebMotor On Delay:\en:', Char(page+19), ' 10ths of a second')
        outlist_i('\ebMotor Off Delay:\en:', Char(page+20), ' 10ths of a second')
        IF ((Char(page+21) AND %10000000) = 0) THEN outlist('\ebTrue Ready:\en', 'Does not use a ready signal') ELSE outlist('\ebTrue Ready:\en', 'Uses a ready signal')
        IF ((Char(page+21) AND %01000000) = 0) THEN outlist('\ebStart Sector Number:\en', 'Sectors start from 0') ELSE outlist('\ebStart Sector Number:\en', 'Sectors start from 1')
        IF ((Char(page+21) AND %00100000) = 0) THEN outlist('\ebMotor On:\en', 'Pin 16 asserted') ELSE outlist('\ebMotor On:\en', 'Pin 16 released')
        outlist_i('\ebStep Pulse Per Cylinder:\en', (Char(page+22) AND %00001111), NIL) 
        outlist_i('\ebWrite Compensation:\en:', Char(page+23), NIL)
        outlist_i('\ebHead Load Delay:\en:', Char(page+24), ' ms')
        outlist_i('\ebHead Unload Delay:\en:', Char(page+25), ' ms')
        IF ((Char(page+26) AND %10000000) = 0) THEN outlist('\ebPin 34:\en', 'Active Low') ELSE outlist('\ebPin 34:\en', 'Active High')
        
        IF ((Char(page+26) AND %01110000) = 0)
            outlist('\ebPin 34 Use:\en', 'Open')
        ELSEIF ((Char(page+26) AND %01110000) = 16)
            outlist('\ebPin 34 Use:\en', 'Ready Signal')
        ELSEIF ((Char(page+26) AND %01110000) = 32)
            outlist('\ebPin 34 Use:\en', 'Disk Change Signal')
        ELSE
            outlist('\ebPin 34 Use:\en', 'Reserved or Vendor-Specific')
        ENDIF        
        
        IF ((Char(page+26) AND %00000100) = 0) THEN outlist('\ebPin 2:\en', 'Active Low') ELSE outlist('\ebPin 2:\en', 'Active High')
        outlist('\ebPin 2 Use:\en', 'NOT DEFINED IN SCSI SPEC')
        IF ((Char(page+27) AND %10000000) = 0) THEN outlist('\ebPin 4:\en', 'Active Low') ELSE outlist('\ebPin 4:\en', 'Active High')
        
        IF ((Char(page+27) AND %01110000) = 0)
            outlist('\ebPin 4 Use:\en', 'Open')
        ELSEIF ((Char(page+27) AND %01110000) = 16)
            outlist('\ebPin 4 Use:\en', 'In Use Signal')
        ELSEIF ((Char(page+27) AND %01110000) = 32)
            outlist('\ebPin 4 Use:\en', 'Eject Signal')
        ELSEIF ((Char(page+27) AND %01110000) = 64)
            outlist('\ebPin 4 Use:\en', 'Head Load Signal')       
        ELSE
            outlist('\ebPin 4 Use:\en', 'Reserved or Vendor-Specific')
        ENDIF 
        
        IF ((Char(page+27) AND %00001000) = 0) THEN outlist('\ebPin 1:\en', 'Active Low') ELSE outlist('\ebPin 1:\en', 'Active High')
  
        IF ((Char(page+27) AND %00000111) = 0)
            outlist('\ebPin 1 Use:\en', 'Open')
        ELSEIF ((Char(page+27) AND %00000111) = 1)
            outlist('\ebPin 1 Use:\en', 'Disk Change Reset')       
        ELSE
            outlist('\ebPin 1 Use:\en', 'Reserved or Vendor-Specific')
        ENDIF        
              
        outlist_i('\ebRotation Rate:\en', Int(page+28), ' rpm')
    ELSEIF global_devtype=DEV_PRINTER 
        outlist('\ebInformation Page:\en', 'Printer Options')
        outlist('\ebPage Code:\en', '$5')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        IF ( (Char(page+2) AND %10000000) = 128) THEN outlist('\ebElectronic Vertical Forms Unit (EVFU):\en', 'Yes') ELSE outlist('\ebElectronic Vertical Forms Unit (EVFU):\en', 'No (or disabled)')
        
        IF ( (Char(page+2) AND %01111111) = 0)
            outlist('\ebFont Identification:\en', 'Default Printer Font')
        ELSEIF ( (Char(page+2) AND %01111111) = 1)
            outlist('\ebFont Identification:\en', 'Reserved')
        ELSEIF ( (Char(page+2) AND %01111111) = 2)
            outlist('\ebFont Identification:\en', 'Reserved')        
        ELSEIF ( (Char(page+2) AND %01111111) = 3)
            outlist('\ebFont Identification:\en', 'Reserved')       
        ELSE
            outlist('\ebFont Identification:\en', 'Vendor Specific Font')
        ENDIF 
        
        outlist_i('\ebSlew Mode:\en', (Char(page+2) AND %00110000), NIL)
        
        IF ( (Char(page+3) AND %00000010) = 0) THEN outlist('\ebStep Count Truncate:\en', 'Disabled') ELSE outlist('\ebStep Count Truncate:\en', 'Enabled')        
        IF ( (Char(page+3) AND %00000001) = 0) THEN outlist('\ebASCII Forms Control:\en', 'Not Supported') ELSE outlist('\ebASCII Forms Control:\en', 'Supported')        
        outlist_i('\ebMaximum Line Length:\en', Int(page+4), ' bytes')
        outlist_i('\ebEVFU Format Start Character:\en', Char(page+6), ' (ASCII Value)')
        outlist_i('\ebEVFU Format Stop Character:\en', Char(page+7), ' (ASCII Value)')
        
        IF ( (Char(page+8) AND %11110000) = 0)
            outlist('\ebLine Slew Option:\en', 'Not Implemented')
        ELSEIF ( (Char(page+8) AND %11110000) = 16)
            outlist('\ebLine Slew Option:\en', 'Carriage Return Character ($0D)')
        ELSEIF ( (Char(page+8) AND %11110000) = 32)   
            outlist('\ebLine Slew Option:\en', 'Line Feed Character ($0A)')
        ELSEIF ( (Char(page+8) AND %11110000) = 48)
            outlist('\ebLine Slew Option:\en', 'Carriage Return and Line Feed Character ($0D0A)')
        ELSE
            outlist('\ebLine Slew Option:\en', 'Reserved or Vendor Specific')
        ENDIF
        
        IF ( (Char(page+8) AND %00001111) = 0)
            outlist('\ebForm Slew Option:\en', 'Not Implemented')
        ELSEIF ( (Char(page+8) AND %00001111) = 1)
            outlist('\ebForm Slew Option:\en', 'Form Feed Character ($0C)')
        ELSEIF ( (Char(page+8) AND %00001111) = 2)
            outlist('\ebForm Slew Option:\en', 'Carriage Return and Form Feed Character ($0D0C)')
        ELSE
            outlist('\ebForm Slew Option:\en', 'Reserved or Vendor Specific')
        ENDIF
        
        IF ( (Char(page+9) AND %11110000) = 0)
            outlist('\ebData Termination:\en', 'Default Implementation')
        ELSEIF ( (Char(page+8) AND %11110000) = 16)
            outlist('\ebData Termination:\en', 'No Termination Sequence')
        ELSEIF ( (Char(page+8) AND %11110000) = 32)   
            outlist('\ebData Termination:\en', 'Carriage Return Character ($0D)')
        ELSEIF ( (Char(page+8) AND %11110000) = 48)
            outlist('\ebData Termination:\en', 'Line Feed Character ($0A)')
        ELSEIF ( (Char(page+8) AND %11110000) = 64)
            outlist('\ebData Termination:\en', 'Carriage Return and Line Feed Character ($0D0A)')        
        ELSEIF ( (Char(page+8) AND %11110000) = 80)
            outlist('\ebData Termination:\en', 'Form Feed Character ($0C)')        
        ELSEIF ( (Char(page+8) AND %11110000) = 96)
            outlist('\ebData Termination:\en', 'Carriage Return and Form Feed Character ($0D0C)')         
        ELSEIF ( (Char(page+8) AND %11110000) = 112)
            outlist('\ebData Termination:\en', 'Zero Line Slew Command')        
        ELSE
            outlist('\ebData Termination:\en', 'Reserved or Vendor Specific')
        ENDIF
   
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$5')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_6(page) -> DONE

    SELECT $A OF global_devtype
        CASE DEV_WRITEONCE, DEV_OPTICAL
            outlist('\ebInformation Page:\en', 'Optical Memory')
            outlist('\ebPage Code:\en', '$6')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
            outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
            IF (Char(page+2) > 0) THEN outlist('\ebReport Updated Block Read\en', 'Yes') ELSE outlist('\ebReport Updated Block Read\en', 'No')    
        DEFAULT
            outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
            outlist('\ebPage Code:\en', '$6')
    ENDSELECT

ENDPROC

/*
** Handler for a specific mode page
*/
PROC process_modesense_7(page) -> DONE

    SELECT $A OF global_devtype
        CASE DEV_DIRECT, DEV_OPTICAL, DEV_WRITEONCE 
            outlist('\ebInformation Page:\en', 'Verify Error Recovery')
            outlist('\ebPage Code:\en', '$7')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
            outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
            IF (Char(page+2) AND %00001000) = 0 THEN outlist('\ebEnable Early Recovery (EER):\en', 'Minimise risk of error mis-correction') ELSE outlist('\ebEnable Early Recovery (EER):\en', 'Always use fastest error recovery method')
            IF (Char(page+2) AND %00000100) = 0 THEN outlist('\ebPost Recoverable Error (PER):\en', 'Don\at report recovered errors') ELSE outlist('\ebPost Recoverable Error (PER):\en', 'Report recovered errors')
            IF (Char(page+2) AND %00000010) = 0 THEN outlist('\ebDisable Transfer on Error (DTE):\en', 'Don\at terminate data phase on error') ELSE outlist('\ebDisable Transfer on Error (DTE):\en', 'Terminate data phase on error')
            IF (Char(page+2) AND %00000001) = 0 THEN outlist('\ebDisable Correction (DCR):\en', 'Use error correction codes') ELSE outlist('\ebDisable Correction (DCR):\en', 'Error correction codes not used')      
            outlist_i('\ebVerify Retries:\en', Char(page+3), NIL)
            outlist_i('\ebVerify Correction Span:\en', Char(page+4), ' bits')
            outlist_i('\ebVerify Recovery Time Limit:\en', Int(page+10), ' ms')
        CASE DEV_SEQUENTIAL 
            outlist('\ebInformation Page:\en', 'Verify Error Recovery')
            outlist('\ebPage Code:\en', '$7')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM Supported:\en', 'No') ELSE outlist('\ebSave to NVRAM Supported:\en', 'Yes')
            outlist_i('\ebPage Length:\en', Char(page+1), NIL)
            IF (Char(page+2) AND %00100000) = 0 THEN outlist('\ebTransfer Block (TB):\en', 'Don\at transfer erroneous block to initiator') ELSE outlist('\ebTransfer Block (TB):\en', 'Transfer erroneous block to initiator')
            IF (Char(page+2) AND %00001000) = 0 THEN outlist('\ebEnable Early Recovery (EER):\en', 'Minimise risk of error mis-correction') ELSE outlist('\ebEnable Early Recovery (EER):\en', 'Always use fastest error recovery method')
            IF (Char(page+2) AND %00000100) = 0 THEN outlist('\ebPost Recoverable Error (PER):\en', 'Don\at report recovered errors') ELSE outlist('\ebPost Recoverable Error (PER):\en', 'Report recovered errors')
            IF (Char(page+2) AND %00000010) = 0 THEN outlist('\ebDisable Transfer on Error (DTE):\en', 'Don\at terminate data phase on error') ELSE outlist('\ebDisable Transfer on Error (DTE):\en', 'Terminate data phase on error')
            IF (Char(page+2) AND %00000001) = 0 THEN outlist('\ebDisable Correction (DCR):\en', 'Use error correction codes') ELSE outlist('\ebDisable Correction (DCR):\en', 'Error correction codes not used')
            outlist_i('\ebRetries on Read Error:\en', Char(page+3), NIL)
            outlist_i('\ebRetries on Write Error:\en', Char(page+8), NIL)
        CASE DEV_CDROM
            outlist('\ebInformation Page:\en', 'Verify Error Recovery Parameters')
            outlist('\ebPage Code:\en', '$7')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
            outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
            outlist_h('\ebError Recovery Parameter:\en', Char(page+2), NIL)
            outlist_i('\ebVerify Retries:\en', Char(page+3), NIL)
        DEFAULT
            outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
            outlist('\ebPage Code:\en', '$7')
    ENDSELECT

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_8(page) -> DONE

    SELECT $A OF global_devtype
        CASE DEV_DIRECT, DEV_CDROM, DEV_WRITEONCE, DEV_OPTICAL
            outlist('\ebInformation Page:\en', 'Cache')
            outlist('\ebPage Code:\en', '$8')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
            outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
            IF (Char(page+2) AND %00000001) = 0 THEN outlist('\ebRead Cache:\en', 'Enabled') ELSE outlist('\ebRead Cache:\en', 'Disabled or Unavailable')
            IF (Char(page+2) AND %00000010) = 0 THEN outlist('\ebMultiplication Factor:\en', 'Min/Max pre-fetch in terms of logical blocks') ELSE outlist('\ebMultiplication Factor:\en', 'Min/Max pre-fetch as scalar')
            IF (Char(page+2) AND %00000100) = 4 THEN outlist('\ebWrite Cache:\en', 'Enabled') ELSE outlist('\ebWrite Cache:\en', 'Disabled or Unavailable')
            outlist_i('\ebDemand Read Retention Priority:\en', Shr((Char(page+3) AND %11110000), 4), NIL)
            outlist_i('\ebWrite Retention Priority:\en', (Char(page+3) AND %00001111), NIL)
            outlist_i('\ebDisable Pre-Fetch Transfer Length:\en', Int(page+4), ' blocks')
            outlist_i('\ebMin Pre-Fetch:\en', Int(page+6), ' bytes/scalar')
            outlist_i('\ebMax Pre-Fetch:\en', Int(page+8), ' bytes/scalar')
            outlist_i('\ebMax Pre-Fetch Ceiling:\en', Int(page+10), ' blocks')
        DEFAULT
            outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
            outlist('\ebPage Code:\en', '$8')
    ENDSELECT

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_9(page) ->DONE

    outlist('\ebInformation Page:\en', 'Interface Mode')
    outlist('\ebPage Code:\en', '$9')
    IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
    outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
    
    IF (Int(page+2)) = 0
        outlist('\ebInterface ID:\en', 'Small Computer Systems Interface (SCSI)')
    ELSEIF (Int(page+2))=1
        outlist('\ebInterface ID:\en', 'Storage Module Interface (SMI)')
    ELSEIF (Int(page+2))=2
        outlist('\ebInterface ID:\en', 'Enhanced Small Device Interface (ESDI)')
    ELSEIF (Int(page+2))=3
        outlist('\ebInterface ID:\en', 'Intelligent Peripheral Interface 2 (IPI-2)')
    ELSEIF (Int(page+2))=4
        outlist('\ebInterface ID:\en', 'Intelligent Peripheral Interface 3 (IPI-3)')
    ELSE
        outlist('\ebInterface ID:\en', 'Reserved or Vendor Specific')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_A(page) ->DONE

    outlist('\ebInformation Page:\en', 'Control Mode')
    outlist('\ebPage Code:\en', '$A')
    IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
    outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
    IF (Char(page+2) AND %00000001)=0 THEN outlist('\ebReport Log Exceptions:\en', 'No') ELSE outlist('\ebReport Log Exceptions:\en', 'Yes')
    
    IF (Char(page+3) AND %11110000)=16
        outlist('\ebQueuing Algorithm:\en', 'Unrestricted reordering allowed')
    ELSEIF (Char(page+3) AND %11110000)=0
        outlist('\ebQueuing Algorithm:\en', 'Restricted reordering')
    ELSE
        outlist('\ebQueuing Algorithm:\en', 'Vendor Specific')
    ENDIF
    
    IF (Char(page+3) AND %00000010)=0 THEN outlist('\ebQueue Error Management:\en', 'Resume after contingent allegiance') ELSE outlist('\ebQueue Error Management:\en', 'Abort after contingent allegiance')  
    IF (Char(page+3) AND %00000001)=0 THEN outlist('\ebQueuing:\en', 'Enabled') ELSE outlist('\ebQueuing:\en', 'Disabled')
    IF (Char(page+4) AND %10000000) = 0 THEN outlist('\ebExtended Contingent Allegiance:\en', 'Disabled') ELSE outlist('\ebExtended Contingent Allegiance:\en', 'Enabled')
    IF (Char(page+4) AND %00000100) = 0 THEN outlist('\ebReady AEN Permission:\en', 'No AEN on init sequence completion') ELSE outlist('\ebReady AEN Permission:\en', 'AEN on init sequence completion')
    IF (Char(page+4) AND %00000010) = 0 THEN outlist('\ebUnit Attention AEN Permission:\en', 'Will not issue AEN instead of UAC') ELSE outlist('\ebUnit Attention AEN Permission:\en', 'May issue AEN instead of UAC')
    IF (Char(page+4) AND %00000001) = 0 THEN outlist('\ebError AEN Permission:\en', 'Will not issue AEN on DEC detection') ELSE outlist('\ebError AEN Permission:\en', 'May issue AEN on DEC detection')
    outlist_i('\ebAEN Holdoff Period:\en', Int(page+6), ' ms')

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_B(page) -> DONE

    SELECT $A OF global_devtype
        CASE DEV_DIRECT, DEV_OPTICAL, DEV_WRITEONCE
            outlist('\ebInformation Page:\en', 'Supported Media')
            outlist('\ebPage Code:\en', '$B')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
            outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
            outlist_i('\ebSupported Medium Type 1:\en', Char(page+4), NIL)
            outlist_i('\ebSupported Medium Type 2:\en', Char(page+5), NIL)
            outlist_i('\ebSupported Medium Type 3:\en', Char(page+6), NIL)
            outlist_i('\ebSupported Medium Type 4:\en', Char(page+7), NIL)
        CASE DEV_CDROM
            outlist('\ebInformation Page:\en', 'Supported Media')
            outlist('\ebPage Code:\en', '$B')
            IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
            outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')

            IF Char(page+4) = NIL
                outlist('\ebMedium Type 1:\en', 'Only the Default medium')
            ELSEIF Char(page+4) = 1
                outlist('\ebMedium Type 1:\en', '120mm Data CD-ROM')
            ELSEIF Char(page+4) = 2
                outlist('\ebMedium Type 1:\en', '120mm Audio CD-ROM')
            ELSEIF Char(page+4) = 3
                outlist('\ebMedium Type 1:\en', '120mm Mixed Data & Audio')
            ELSEIF Char(page+4) = 5
                outlist('\ebMedium Type 1:\en', '80mm Data CD-ROM')
            ELSEIF Char(page+4) = 6
                outlist('\ebMedium Type 1:\en', '80mm Audio CD-ROM')
            ELSEIF Char(page+4) = 7
                outlist('\ebMedium Type 1:\en', '80mm Mixed Data & Audio')
            ELSE
                outlist('\ebMedium Type 1:\en', 'Vendor Specific')
            ENDIF

            IF Char(page+5) = NIL
                outlist('\ebMedium Type 2:\en', 'Only the Default medium')
            ELSEIF Char(page+5) = 1
                outlist('\ebMedium Type 2:\en', '120mm Data CD-ROM')
            ELSEIF Char(page+5) = 2
                outlist('\ebMedium Type 2:\en', '120mm Audio CD-ROM')
            ELSEIF Char(page+5) = 3
                outlist('\ebMedium Type 2:\en', '120mm Mixed Data & Audio')
            ELSEIF Char(page+5) = 5
                outlist('\ebMedium Type 2:\en', '80mm Data CD-ROM')
            ELSEIF Char(page+5) = 6
                outlist('\ebMedium Type 2:\en', '80mm Audio CD-ROM')
            ELSEIF Char(page+5) = 7
                outlist('\ebMedium Type 2:\en', '80mm Mixed Data & Audio')
            ELSE
                outlist('\ebMedium Type 2:\en', 'Vendor Specific')
            ENDIF

            IF Char(page+6) = NIL
                outlist('\ebMedium Type 3:\en', 'Only the Default medium')
            ELSEIF Char(page+6) = 1
                outlist('\ebMedium Type 3:\en', '120mm Data CD-ROM')
            ELSEIF Char(page+6) = 2
                outlist('\ebMedium Type 3:\en', '120mm Audio CD-ROM')
            ELSEIF Char(page+6) = 3
                outlist('\ebMedium Type 3:\en', '120mm Mixed Data & Audio')
            ELSEIF Char(page+6) = 5
                outlist('\ebMedium Type 3:\en', '80mm Data CD-ROM')
            ELSEIF Char(page+6) = 6
                outlist('\ebMedium Type 3:\en', '80mm Audio CD-ROM')
            ELSEIF Char(page+6) = 7
                outlist('\ebMedium Type 3:\en', '80mm Mixed Data & Audio')
            ELSE
                outlist('\ebMedium Type 3:\en', 'Vendor Specific')
            ENDIF

            IF Char(page+7) = NIL
                outlist('\ebMedium Type 4:\en', 'Only the Default medium')
            ELSEIF Char(page+7) = 1
                outlist('\ebMedium Type 4:\en', '120mm Data CD-ROM')
            ELSEIF Char(page+7) = 2
                outlist('\ebMedium Type 4:\en', '120mm Audio CD-ROM')
            ELSEIF Char(page+7) = 3
                outlist('\ebMedium Type 4:\en', '120mm Mixed Data & Audio')
            ELSEIF Char(page+7) = 5
                outlist('\ebMedium Type 4:\en', '80mm Data CD-ROM')
            ELSEIF Char(page+7) = 6
                outlist('\ebMedium Type 4:\en', '80mm Audio CD-ROM')
            ELSEIF Char(page+7) = 7
                outlist('\ebMedium Type 4:\en', '80mm Mixed Data & Audio')
            ELSE
                outlist('\ebMedium Type 4:\en', 'Vendor Specific')
            ENDIF
        DEFAULT
            outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
            outlist('\ebPage Code:\en', '$B')
    ENDSELECT

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_C(page) -> DONE
DEF str[40]:STRING

    IF global_devtype=DEV_DIRECT
        outlist('\ebInformation Page:\en', 'Notch Parameters')
        outlist('\ebPage Code:\en', '$C')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        IF (Char(page+2) AND %10000000)=0 THEN outlist('\ebNotched Drive:\en', 'No') ELSE outlist('\ebNotched Drive:\en', 'Yes')
        outlist_i('\ebMaximum Notches:\en', Int(page+4), NIL)
        outlist_i('\ebActive Notch:\en', Int(page+6), NIL)
        
        IF (Char(page+2) AND %01000000)=0
            outlist('\ebNotch Boundary Type (LPN):\en', 'Physical')
            StringF(str, 'Cylinder: \d, Head: \d', Shr((Long(page+8) AND $FFFFFF00), 8), Char(page+11))
            outlist('\ebActive Notch Starting Boundary:\en', str)
            StringF(str, 'Cylinder: \d, Head: \d', Shr((Long(page+12) AND $FFFFFF00), 8), Char(page+15))
            outlist('\ebActive Notch Ending Boundary:\en', str)
        ELSE    
            outlist('\ebNotch Boundary Type:\en', 'Logical')
            outlist_i('\ebActive Notch Starting Boundary:\en', Long(page+8), ' LBA')
            outlist_i('\ebActive Notch Ending Boundary:\en', Long(page+12), ' LBA')
        ENDIF
        
        StringF(str, '$\h\h', Long(page+16), Long(page+20))
        outlist('\ebPages Notched Bitmap (8 bytes):\en', str)

    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$C')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_D(page) -> DONE

    IF global_devtype=DEV_CDROM
        outlist('\ebInformation Page:\en', 'CD-ROM Parameters')
        outlist('\ebPage Code:\en', '$D')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        
        IF (Char(page+3) AND %00001111) = 0
            outlist('\ebInactivity Multiplier:\en', 'Vendor specific')
        ELSEIF (Char(page+3) AND %00001111) = $1    
            outlist('\ebInactivity Multiplier:\en', '125 ms')   
        ELSEIF (Char(page+3) AND %00001111) = $2    
            outlist('\ebInactivity Multiplier:\en', '250 ms')
        ELSEIF (Char(page+3) AND %00001111) = $3    
            outlist('\ebInactivity Multiplier:\en', '500 ms')        
        ELSEIF (Char(page+3) AND %00001111) = $4    
            outlist('\ebInactivity Multiplier:\en', '1 second')        
        ELSEIF (Char(page+3) AND %00001111) = $5    
            outlist('\ebInactivity Multiplier:\en', '2 seconds')        
        ELSEIF (Char(page+3) AND %00001111) = $6    
            outlist('\ebInactivity Multiplier:\en', '4 seconds')        
        ELSEIF (Char(page+3) AND %00001111) = $7    
            outlist('\ebInactivity Multiplier:\en', '8 seconds')        
        ELSEIF (Char(page+3) AND %00001111) = $8    
            outlist('\ebInactivity Multiplier:\en', '16 seconds')        
        ELSEIF (Char(page+3) AND %00001111) = $9    
            outlist('\ebInactivity Multiplier:\en', '32 seconds')        
        ELSEIF (Char(page+3) AND %00001111) = $A    
            outlist('\ebInactivity Multiplier:\en', '1 minute')        
        ELSEIF (Char(page+3) AND %00001111) = $B    
            outlist('\ebInactivity Multiplier:\en', '2 minutes')        
        ELSEIF (Char(page+3) AND %00001111) = $C    
            outlist('\ebInactivity Multiplier:\en', '4 minutes')            
        ELSEIF (Char(page+3) AND %00001111) = $D    
            outlist('\ebInactivity Multiplier:\en', '8 minutes')            
        ELSEIF (Char(page+3) AND %00001111) = $E    
            outlist('\ebInactivity Multiplier:\en', '16 minutes')            
        ELSE 
            outlist('\ebInactivity Multiplier:\en', '32 minutes')            
        ENDIF    

        outlist_i('\ebS Units per MSF:\en', Int(page+4), NIL)
        outlist_i('\ebF Units per MSF:\en', Int(page+6), NIL)
    ELSEIF global_devtype=DEV_DIRECT
        outlist('\ebInformation Page:\en', 'Power Condition (Quantum)')
        outlist('\ebWarning:\en', 'Page format may be device specific. Info may be incorrect')
        outlist('\ebReference:\en', 'Quantum Fireball ST 2.1/3.2/4.3/6.4 GB S')
        outlist('\ebPage Code:\en', '$D')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        IF (Char(page+3) AND %00000001) = 0 THEN outlist('\ebStandby Support Enabled:\en', 'No') ELSE outlist('\ebStandby Support Enabled:\en', 'Yes')
        outlist_i('\ebIdle Time to Enter Standby:\en', Long(page+8), ' *100 ms')
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$D')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_E(page) -> DONE

    IF global_devtype=DEV_CDROM
        outlist('\ebInformation Page:\en', 'CD-ROM Audio Control')
        outlist('\ebPage Code:\en', '$E')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        IF (Char(page+2) AND %00000100) = 4 THEN outlist('\ebAudio Completion Status:\en', 'On Audio Termination') ELSE outlist('\ebAudio Completion Status:\en', 'On Audio Playback')
        IF (Char(page+2) AND %00000010) = 2 THEN outlist('\ebStop on Track Crossing:\en', 'When next track encountered') ELSE outlist('\ebStop on Track Crossing:\en', 'When transfer length satisfied')
        IF (Char(page+5) AND %10000000) = 0 THEN outlist('\ebAudio Playback Rate Valid:\en', 'No') ELSE outlist('\ebAudio Playback Rate Valid:\en', 'Yes')
        
        IF (Char(page+5) AND %00001111) = 0 
            outlist('\ebFormat of LBA/sec:\en', '1 (multiplier for LBA/sec)')
        ELSEIF (Char(page+5) AND %00001111) = 8
            outlist('\ebFormat of LBA/sec:\en', '8 (multiplier for LBA/sec)')
        ELSE
            outlist('\ebFormat of LBA/sec:\en', 'Reserved or vendor specific')
        ENDIF
            
        outlist_i('\ebLBA/sec per audio:\en', Int(page+6), ' blocks')
        
        IF (Char(page+8) AND %00001111) = 0
            outlist('\ebPort 0 Channel Selection:\en', 'Port Muted')
        ELSEIF (Char(page+8) AND %00001111) = 1 
            outlist('\ebPort 0 Channel Selection:\en', 'Connect audio channel 0 to this port')  
        ELSEIF (Char(page+8) AND %00001111) = 2 
            outlist('\ebPort 0 Channel Selection:\en', 'Connect audio channel 1 to this port')
        ELSEIF (Char(page+8) AND %00001111) = 4 
            outlist('\ebPort 0 Channel Selection:\en', 'Connect audio channel 2 to this port')             
        ELSEIF (Char(page+8) AND %00001111) = 8 
            outlist('\ebPort 0 Channel Selection:\en', 'Connect audio channel 3 to this port')
        ELSE
            outlist('\ebPort 0 Channel Selection:\en', 'Reserved or vendor specific')
        ENDIF                        
                 
        outlist_i('\ebPort 0 Volume Level:\en', Char(page+9), ' (255 = Full Voume)')
        
        IF (Char(page+10) AND %00001111) = 0
            outlist('\ebPort 1 Channel Selection:\en', 'Port Muted')
        ELSEIF (Char(page+10) AND %00001111) = 1 
            outlist('\ebPort 1 Channel Selection:\en', 'Connect audio channel 0 to this port')  
        ELSEIF (Char(page+10) AND %00001111) = 2 
            outlist('\ebPort 1 Channel Selection:\en', 'Connect audio channel 1 to this port')
        ELSEIF (Char(page+10) AND %00001111) = 4 
            outlist('\ebPort 1 Channel Selection:\en', 'Connect audio channel 2 to this port')             
        ELSEIF (Char(page+10) AND %00001111) = 8 
            outlist('\ebPort 1 Channel Selection:\en', 'Connect audio channel 3 to this port')
        ELSE
            outlist('\ebPort 1 Channel Selection:\en', 'Reserved or vendor specific')
        ENDIF         
        
        outlist_i('\ebPort 1 Volume Level:\en', Char(page+11), ' (255 = Full Voume)')
        
        IF (Char(page+12) AND %00001111) = 0
            outlist('\ebPort 2 Channel Selection:\en', 'Port Muted')
        ELSEIF (Char(page+12) AND %00001111) = 1 
            outlist('\ebPort 2 Channel Selection:\en', 'Connect audio channel 0 to this port')  
        ELSEIF (Char(page+12) AND %00001111) = 2 
            outlist('\ebPort 2 Channel Selection:\en', 'Connect audio channel 1 to this port')
        ELSEIF (Char(page+12) AND %00001111) = 4 
            outlist('\ebPort 2 Channel Selection:\en', 'Connect audio channel 2 to this port')             
        ELSEIF (Char(page+12) AND %00001111) = 8 
            outlist('\ebPort 2 Channel Selection:\en', 'Connect audio channel 3 to this port')
        ELSE
            outlist('\ebPort 2 Channel Selection:\en', 'Reserved or vendor specific')
        ENDIF         
         
        outlist_i('\ebPort 2 Volume Level:\en', Char(page+13), ' (255 = Full Voume)')
        
        IF (Char(page+14) AND %00001111) = 0
            outlist('\ebPort 3 Channel Selection:\en', 'Port Muted')
        ELSEIF (Char(page+14) AND %00001111) = 1 
            outlist('\ebPort 3 Channel Selection:\en', 'Connect audio channel 0 to this port')  
        ELSEIF (Char(page+14) AND %00001111) = 2 
            outlist('\ebPort 3 Channel Selection:\en', 'Connect audio channel 1 to this port')
        ELSEIF (Char(page+14) AND %00001111) = 4 
            outlist('\ebPort 3 Channel Selection:\en', 'Connect audio channel 2 to this port')             
        ELSEIF (Char(page+14) AND %00001111) = 8 
            outlist('\ebPort 3 Channel Selection:\en', 'Connect audio channel 3 to this port')
        ELSE
            outlist('\ebPort 3 Channel Selection:\en', 'Reserved or vendor specific')
        ENDIF        
        
        outlist_i('\ebPort 3 Volume Level:\en', Char(page+15),  ' (255 = Full Voume)')
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$E')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_F(page)

    IF global_devtype=DEV_SEQUENTIAL
        outlist('\ebInformation Page:\en', 'Data Compression Characteristics')
        outlist('\ebWarning:\en', 'Page format may be device specific. Info may be incorrect')
        outlist('\ebReference:\en', 'HP C1533A')
        outlist('\ebPage Code:\en', '$F')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        IF (Char(page+2) AND %10000000)=128 THEN outlist('\ebData Compression Enabled:\en', 'Yes') ELSE outlist('\ebData Compression Enabled:\en', 'No')
        IF (Char(page+2) AND %01000000)=64 THEN outlist('\ebData Compression Supported:\en', 'Yes') ELSE outlist('\ebData Compression Supported:\en', 'No')
        IF (Char(page+3) AND %10000000)=128 THEN outlist('\ebAttempt Decompression:\en', 'Yes') ELSE outlist('\ebAttempt Decompression:\en', 'No')
        outlist_i('\ebCompression Algorithm:\en', Long(page+4), NIL)
        outlist_i('\ebDecompression Algorithm:\en', Long(page+8), NIL)
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$F')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_10(page) ->DONE

    IF global_devtype=DEV_SEQUENTIAL
        outlist('\ebInformation Page:\en', 'Sequential Device Configuration')
        outlist('\ebPage Code:\en', '$10')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        IF (Char(page+2) AND %01000000) = 0 THEN outlist('\ebChange Active Partition:\en', 'No partition change specified') ELSE outlist('\ebChange Active Partition:\en', 'Change to active partition')
        IF (Char(page+2) AND %00100000) = 0 THEN outlist('\ebChange Active Format:\en', 'No format change specified') ELSE outlist('\ebChange Active Format:\en', 'Change to active format')
        outlist_i('\ebActive Recording Format:\en', (Char(page+2) AND %00011111), ' (All values vendor specific)')
        outlist_i('\ebActive Logical Partition:\en', Char(page+3), NIL)
        outlist_i('\ebWrite Buffer Full Ratio:\en', Char(page+4), NIL)
        outlist_i('\ebRead Buffer Empty Ratio:\en', Char(page+5), NIL)
        outlist_i('\ebWrite Delay:\en', Int(page+6), ' *100 ms')
        IF (Char(page+8) AND %10000000) = 0 THEN outlist('\ebData Buffer Recovery:\en', 'Not supported') ELSE outlist('\ebData Buffer Recovery:\en', 'Supported')
        IF (Char(page+8) AND %01000000) = 0 THEN outlist('\ebBlock Identifiers Supported:\en', 'Not supported on medium') ELSE outlist('\ebBlock Identifiers Supported:\en', 'Medium has recorded block IDs relative to partition') 
        IF (Char(page+8) AND %00100000) = 0 THEN outlist('\ebSetMarks:\en', 'Don\at report setmarks') ELSE outlist('\ebSetMarks:\en', 'Recognise and report setmarks')
        IF (Char(page+8) AND %00010000) = 0 THEN outlist('\ebAutomatic Velocity Control:\en', 'Use default speed') ELSE outlist('\ebAutomatic Velocity Control:\en', 'Use speed best for streaming')
        
        IF (Char(page+8) AND %00001100) = 0
            outlist('\ebStop on Consecutive Filemarks:\en', 'Buffer with no regard to filemarks')
        ELSEIF (Char(page+8) AND %00001100) = 4
            outlist('\ebStop on Consecutive Filemarks:\en', 'Stop pre-read if 1 filemark detected')
        ELSEIF (Char(page+8) AND %00001100) = 8
            outlist('\ebStop on Consecutive Filemarks:\en', 'Stop pre-read if 2 filemarks detected')
        ELSE
            outlist('\ebStop on Consecutive Filemarks:\en', 'Stop pre-read if 3 filemarks detected')
        ENDIF
        
        IF (Char(page+8) AND %00000010) = 0 THEN outlist('\ebRecovery Buffer Order:\en', 'FIFO') ELSE outlist('\ebRecovery Buffer Order:\en', 'LIFO Order')
        IF (Char(page+8) AND %00000001) = 0 THEN outlist('\ebReport Early Warning:\en', 'No for read operations') ELSE outlist('\ebReport Early Warning:\en', 'Yes')
        
        IF Char(page+9) = 0 THEN outlist('\ebGap Size:\en', 'Device Default') ELSE outlist_i('\ebGap Size:\en', Char(page+9), NIL)
        
        IF (Char(page+10) AND %11100000) = 0
            outlist('\ebEnd of Data:\en', 'Logical unit default')
        ELSEIF (Char(page+10) AND %11100000) = 32
            outlist('\ebEnd of Data:\en', 'Format defined erased area of medium')
        ELSEIF (Char(page+10) AND %11100000) = 64
            outlist('\ebEnd of Data:\en', 'As specified in SOCF field')
        ELSEIF (Char(page+10) AND %11100000) = 96
            outlist('\ebEnd of Data:\en', 'Not supported')
        ELSE
            outlist('\ebEnd of Data:\en', 'Reserved or vendor specific')
        ENDIF
        
        IF (Char(page+10) AND %00010000) = 0 THEN outlist('\ebEnable EOD Generation:\en', 'Disabled') ELSE outlist('\ebEnable EOD Generation:\en', 'Enabled')
        IF (Char(page+10) AND %00001000) = 0 THEN outlist('\ebSynchronise at Early Warning:\en', 'Disabled') ELSE outlist('\ebSynchronise at Early Warning:\en', 'Enabled') 
        outlist_i('\ebBuffer Size at Early Warning:\en', (Long(page+10) AND $00FFFFFF), ' bytes')        
        IF Char(page+14) = 0 THEN outlist('\ebCompression:\en', 'Disabled or not supported') ELSE outlist('\ebCompression:\en', 'Enabled')

    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$10')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_11(page) ->DONE
DEF ptr:PTR TO CHAR

    IF global_devtype=DEV_SEQUENTIAL
        ptr:=(page+8)
        outlist('\ebInformation Page:\en', 'Medium Partition Page (1)')
        outlist('\ebPage Code:\en', '$11')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebMax Additional Partitions:\en', Char(page+2), NIL)
        outlist_i('\ebAdditional Partitions Defined:\en', Char(page+3), NIL)
        IF (Char(page+4) AND %10000000) = 0 THEN outlist('\ebFixed Data Partitions:\en', 'No') ELSE outlist('\ebFixed Data Partitions:\en', 'Yes')
        IF (Char(page+4) AND %01000000) = 0 THEN outlist('\ebSelect Data Partitions:\en', 'No') ELSE outlist('\ebSelect Data Partitions:\en', 'Yes')
        IF (Char(page+4) AND %00100000) = 0 THEN outlist('\ebInitiator Defined Partitions:\en', 'No') ELSE outlist('\ebInitiator Defined Partitions:\en', 'Yes')
        
        IF (Char(page+4) AND %00011000) = 0
            outlist('\ebPartition Unit of Measure:\en', 'Bytes')
        ELSEIF (Char(page+4) AND %00011000) = 1
            outlist('\ebPartition Unit of Measure:\en', 'KiloBytes')
        ELSEIF (Char(page+4) AND %00011000) = 2
            outlist('\ebPartition Unit of Measure:\en', 'MegaBytes')
        ELSE
            outlist('\ebPartition Unit of Measure:\en', 'Custom')
        ENDIF
        
        IF Char(page+5)=0
            outlist('\ebMedium Format Recognition:\en', 'Incapable of Format or Partition Recognition')
        ELSEIF Char(page+5)=1
            outlist('\ebMedium Format Recognition:\en', 'Format Recognition Only')
        ELSEIF Char(page+5)=2
            outlist('\ebMedium Format Recognition:\en', 'Partition Recognition Only')
        ELSEIF Char(page+5)=3
            outlist('\ebMedium Format Recognition:\en', 'Format and Partition Recognition')
        ELSE
            outlist('\ebMedium Format Recognition:\en', 'Reserved or vendor specific')
        ENDIF
        
        WHILE (ptr < (page + Char(page+1) ) )
            outlist_i('\ebFound Partition Size:\en', Int(ptr), NIL)
            ptr:=ptr+2    
        ENDWHILE
        
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$11')
    ENDIF


ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_12(page) -> DONE
DEF ptr:PTR TO CHAR

    IF global_devtype=DEV_SEQUENTIAL
        ptr:=(page+2) 
        outlist('\ebInformation Page:\en', 'Medium Partition Page (2)')
        outlist('\ebPage Code:\en', '$12')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        
        WHILE (ptr < (page + Char(page+1) ) )
            outlist_i('\ebFound Partition Size:\en', Int(ptr), NIL)
            ptr:=ptr+2    
        ENDWHILE
        
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$12')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_13(page) ->DONE
DEF ptr:PTR TO CHAR

    IF global_devtype=DEV_SEQUENTIAL
        ptr:=(page+2)  
        outlist('\ebInformation Page:\en', 'Medium Partition Page (3)')
        outlist('\ebPage Code:\en', '$13')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        
        WHILE (ptr < (page + Char(page+1) ) )
            outlist_i('\ebFound Partition Size:\en', Int(ptr), NIL)
            ptr:=ptr+2    
        ENDWHILE
        
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$13')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_14(page) ->DONE
DEF ptr:PTR TO CHAR

    IF global_devtype=DEV_SEQUENTIAL
        ptr:=(page+2)   
        outlist('\ebInformation Page:\en', 'Medium Partition Page (4)')
        outlist('\ebPage Code:\en', '$14')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        
        WHILE (ptr < (page + Char(page+1) ) )
            outlist_i('\ebFound Partition Size:\en', Int(ptr), NIL)
            ptr:=ptr+2    
        ENDWHILE
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$14')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_18(page)
    outlist('\ebInformation Page:\en', 'Protocol Specific LUN')
    outlist('\ebPage Code:\en', '$18')
    IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
    outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
    IF (Char(page+2) AND %00001111) = 0
        outlist('\ebProtocol Identifier:\en', 'Fibre Channel')
    ELSEIF (Char(page+2) AND %00001111) = 1
        outlist('\ebProtocol Identifier:\en', 'Parallel SCSI')
    ELSEIF (Char(page+2) AND %00001111) = 2
        outlist('\ebProtocol Identifier:\en', 'SSA (S2P or S3P)')
    ELSEIF (Char(page+2) AND %00001111) = 1
        outlist('\ebProtocol Identifier:\en', 'IEEE 1394 (SBP-2/Firewire)')
    ELSE
        outlist('\ebProtocol Identifier:\en', 'Reserved')
    ENDIF
ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_19(page)
    outlist('\ebInformation Page:\en', 'Protocol Specifics')
    outlist('\ebPage Code:\en', '$19')
    IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
    outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
    IF (Char(page+2) AND %00001111) = 0
        outlist('\ebProtocol Identifier:\en', 'Fibre Channel')
    ELSEIF (Char(page+2) AND %00001111) = 1
        outlist('\ebProtocol Identifier:\en', 'Parallel SCSI')
    ELSEIF (Char(page+2) AND %00001111) = 2
        outlist('\ebProtocol Identifier:\en', 'SSA (S2P or S3P)')
    ELSEIF (Char(page+2) AND %00001111) = 1
        outlist('\ebProtocol Identifier:\en', 'IEEE 1394 (SBP-2/Firewire)')
    ELSE
        outlist('\ebProtocol Identifier:\en', 'Reserved')
    ENDIF
ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_1A(page)

    outlist('\ebInformation Page:\en', 'Power Condition')
    outlist('\ebPage Code:\en', '$1A')
    IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
    outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
    IF (Char(page+3) AND %00000001) = 1 THEN outlist('\ebStandby Support Enabled:\en', 'Yes') ELSE outlist('\ebStandby Support Enabled:\en', 'No')
    outlist_i('\ebIdle Time to enter Standby:\en', Long(page+8), ' *100 Ms')

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_1C(page) -> DONE

    outlist('\ebInformation Page:\en', 'SCSI SMART Control')
    outlist('\ebPage Code:\en', '$1C')
    IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
    outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
    IF (Char(page+2) AND %00000001) = 0 THEN outlist('\ebLocation of Exception Logs:\en', 'Vendor specific location') ELSE outlist('\ebLocation of Exception Logs:\en', 'Firmware logs')
    IF (Char(page+2) AND %00001000) = 0 THEN outlist('\ebException Control:\en', 'Information exceptions enabled') ELSE outlist('\ebException Control:\en', 'Information exceptions disabled')
    IF (Char(page+2) AND %10000000) = 0 THEN outlist('\ebPerformance:\en', 'Delays due to IE acceptable') ELSE outlist('\ebPerformance:\en', 'Delays due to IE not allowed')
    IF (Char(page+2) AND %00000100) = 0 THEN outlist('\ebTest:\en', 'False drive notifications disallowed') ELSE outlist('\ebTest:\en', 'False drive notifications allowed')
    
    IF (Char(page+3) AND %00001111) = $0
        outlist('\ebReporting Type:\en', 'Information conditions not reported')
    ELSEIF (Char(page+3) AND %00001111) = $1
        outlist('\ebReporting Type:\en', 'Information conditions reported via AEN')
    ELSEIF (Char(page+3) AND %00001111) = $2
        outlist('\ebReporting Type:\en', 'Information conditions reported via Unit Attention')
    ELSEIF (Char(page+3) AND %00001111) = $3
        outlist('\ebReporting Type:\en', 'Conditionally generate recovered error')
    ELSEIF (Char(page+3) AND %00001111) = $4
        outlist('\ebReporting Type:\en', 'Unconditionally generate recovered error')
    ELSEIF (Char(page+3) AND %00001111) = $5
        outlist('\ebReporting Type:\en', 'Use "No Sense" and additional sense code')
    ELSEIF (Char(page+3) AND %00001111) = $6
        outlist('\ebReporting Type:\en', 'Preserve information conditions. Report on request.')
    ELSE
        outlist('\ebReporting Type:\en', 'Reserved or vendor specific')
    ENDIF
    
    outlist_i('\ebInterval Timer:\en', Long(page+4), NIL)
    outlist_i('\ebReport Count:\en', Long(page+8), NIL)

ENDPROC

/*
** Handler for a specific mode page
*/
PROC process_modesense_1D(page) ->DONE

    IF global_devtype=DEV_CHANGER    
        outlist('\ebInformation Page:\en', 'Element Address Assignment')
        outlist('\ebPage Code:\en', '$1D')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebMedium Transport Element Address:\en', Int(page+2), NIL)
        outlist_i('\ebNumber of Medium Transport Elements:\en', Int(page+4), NIL)
        outlist_i('\ebFirst Storage Element Address:\en', Int(page+6), NIL)
        outlist_i('\ebNumber of Storage Elements:\en', Int(page+8), NIL)
        outlist_i('\ebFirst Import/Export Element Address:\en', Int(page+10), NIL)
        outlist_i('\ebNumber of Import/Export Elements:\en', Int(page+12), NIL)
        outlist_i('\ebFirst Data Transfer Element Address:\en', Int(page+14), NIL)
        outlist_i('\ebNumber of Data Transfer Elements:\en', Int(page+16), NIL)
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$1D')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_1E(page) -> DONE
DEF ptr:PTR TO CHAR

    IF global_devtype=DEV_CHANGER   
        ptr:=(page+2) 
        outlist('\ebInformation Page:\en', 'Transport Geometry')
        outlist('\ebPage Code:\en', '$1E')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        
        WHILE (ptr < (page + Char(page+1) ) )
            IF (Char(ptr) AND %00000001) = 0 THEN outlist('\ebMedia Rotation:\en', 'Doesn\at support media rotation') ELSE outlist('\ebMedia Rotation:\en', 'Support double sided media rotation')
            outlist_i('\ebMember Number in Transport Element:\en', Char(ptr+1), NIL)
            ptr:=ptr+2    
        ENDWHILE
        
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$1E')
    ENDIF

ENDPROC



/*
** Handler for a specific mode page
*/
PROC process_modesense_1F(page) -> DONE

    IF global_devtype=DEV_CHANGER    
        outlist('\ebInformation Page:\en', 'Medium Changer Device Capabilities')
        outlist('\ebPage Code:\en', '$1F')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebStorDT Bit:\en', (Char(page+2) AND %00001000), ' (0=off, >0 = On)')
        outlist_i('\ebStorIE Bit:\en', (Char(page+2) AND %00000100), ' (0=off, >0 = On)')
        outlist_i('\ebStorST Bit:\en', (Char(page+2) AND %00000010), ' (0=off, >0 = On)')
        outlist_i('\ebStorMT Bit:\en', (Char(page+2) AND %00000001), ' (0=off, >0 = On)')
        outlist_i('\ebMT->DT Bit:\en', (Char(page+4) AND %00001000), ' (0=off, >0 = On)')
        outlist_i('\ebMT->IE Bit:\en', (Char(page+4) AND %00000100), ' (0=off, >0 = On)')
        outlist_i('\ebMT->ST Bit:\en', (Char(page+4) AND %00000010), ' (0=off, >0 = On)')
        outlist_i('\ebMT->MT Bit:\en', (Char(page+4) AND %00000001), ' (0=off, >0 = On)')        
        outlist_i('\ebST->DT Bit:\en', (Char(page+5) AND %00001000), ' (0=off, >0 = On)')
        outlist_i('\ebST->IE Bit:\en', (Char(page+5) AND %00000100), ' (0=off, >0 = On)')
        outlist_i('\ebST->ST Bit:\en', (Char(page+5) AND %00000010), ' (0=off, >0 = On)')
        outlist_i('\ebST->MT Bit:\en', (Char(page+5) AND %00000001), ' (0=off, >0 = On)')        
        outlist_i('\ebIE->DT Bit:\en', (Char(page+6) AND %00001000), ' (0=off, >0 = On)')
        outlist_i('\ebIE->IE Bit:\en', (Char(page+6) AND %00000100), ' (0=off, >0 = On)')
        outlist_i('\ebIE->ST Bit:\en', (Char(page+6) AND %00000010), ' (0=off, >0 = On)')
        outlist_i('\ebIE->MT Bit:\en', (Char(page+6) AND %00000001), ' (0=off, >0 = On)')        
        outlist_i('\ebDT->DT Bit:\en', (Char(page+7) AND %00001000), ' (0=off, >0 = On)')
        outlist_i('\ebDT->IE Bit:\en', (Char(page+7) AND %00000100), ' (0=off, >0 = On)')
        outlist_i('\ebDT->ST Bit:\en', (Char(page+7) AND %00000010), ' (0=off, >0 = On)')
        outlist_i('\ebDT->MT Bit:\en', (Char(page+7) AND %00000001), ' (0=off, >0 = On)')        
        outlist_i('\ebMT<>DT Bit:\en', (Char(page+12) AND %00001000), ' (0=off, >0 = On)')
        outlist_i('\ebMT<>IE Bit:\en', (Char(page+12) AND %00000100), ' (0=off, >0 = On)')
        outlist_i('\ebMT<>ST Bit:\en', (Char(page+12) AND %00000010), ' (0=off, >0 = On)')
        outlist_i('\ebMT<>MT Bit:\en', (Char(page+12) AND %00000001), ' (0=off, >0 = On)')        
        outlist_i('\ebST<>DT Bit:\en', (Char(page+13) AND %00001000), ' (0=off, >0 = On)')
        outlist_i('\ebST<>IE Bit:\en', (Char(page+13) AND %00000100), ' (0=off, >0 = On)')
        outlist_i('\ebST<>ST Bit:\en', (Char(page+13) AND %00000010), ' (0=off, >0 = On)')
        outlist_i('\ebST<>MT Bit:\en', (Char(page+13) AND %00000001), ' (0=off, >0 = On)')           
        outlist_i('\ebIE<>DT Bit:\en', (Char(page+14) AND %00001000), ' (0=off, >0 = On)')
        outlist_i('\ebIE<>IE Bit:\en', (Char(page+14) AND %00000100), ' (0=off, >0 = On)')
        outlist_i('\ebIE<>ST Bit:\en', (Char(page+14) AND %00000010), ' (0=off, >0 = On)')
        outlist_i('\ebIE<>MT Bit:\en', (Char(page+14) AND %00000001), ' (0=off, >0 = On)')        
        outlist_i('\ebDT<>DT Bit:\en', (Char(page+15) AND %00001000), ' (0=off, >0 = On)')
        outlist_i('\ebDT<>IE Bit:\en', (Char(page+15) AND %00000100), ' (0=off, >0 = On)')
        outlist_i('\ebDT<>ST Bit:\en', (Char(page+15) AND %00000010), ' (0=off, >0 = On)')
        outlist_i('\ebDT<>MT Bit:\en', (Char(page+15) AND %00000001), ' (0=off, >0 = On)')         
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$1F')
    ENDIF

ENDPROC



PROC process_modesense_20(page)
   
   IF global_devtype=DEV_OPTICAL
        outlist('\ebInformation Page:\en', 'Format Parameters (IBM)')
        outlist('\ebWarning:\en', 'Page format may be device specific. Info may be incorrect')
        outlist('\ebReference:\en', 'IBM 0632')
        outlist('\ebPage Code:\en', '$20')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebNumber of Groups:\en', Int(page+2), NIL)
        outlist_i('\ebData Blocks/Group (MSB):\en', Shr((Long(page+4) AND $FFFFFF00), 8), NIL)
        outlist_i('\ebNumber of Spare Blocks/Group:\en', Shr((Long(page+7) AND $FFFFFF00), 8), NIL)
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$20')
    ENDIF

ENDPROC

/*
** Handler for a specific mode page
*/
PROC process_modesense_21(page)

    IF global_devtype=DEV_DIRECT
        outlist('\ebInformation Page:\en', 'Extended Error Recovery')
        outlist('\ebWarning:\en', 'Page format may be device specific. Info may be incorrect')
        outlist('\ebReference:\en', 'FUJITSU MAB 3091SC, MAE 3182LC, MAG 3091L')
        outlist('\ebPage Code:\en', '$21')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebRetry Count on Seek Error:\en', Char(page+2), NIL)
    ELSEIF global_devtype=DEV_OPTICAL
        outlist('\ebInformation Page:\en', 'Control Parameters (IBM)')
        outlist('\ebWarning:\en', 'Page format may be device specific. Info may be incorrect')
        outlist('\ebReference:\en', 'IBM 0632')
        outlist('\ebPage Code:\en', '$20')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebLaser On Interval:\en', Char(page+2), ' minutes')        
        IF (Char(page+3) AND %10000000) = 128 THEN outlist('Write Reordering:', 'Disabled') ELSE outlist('Write Reordering:', 'Enabled if Write Cache Enabled')
        IF (Char(page+3) AND %01000000) = 64 THEN outlist('Application:', 'Switch A5 on') ELSE outlist('Application:', 'Switch A5 off')
        IF (Char(page+3) AND %01000000) = 16 THEN outlist('Quick Disconnect:', 'Enabled') ELSE outlist('Quick Disconnect:', 'Disabled')
        IF (Char(page+3) AND %01000000) = 1 THEN outlist('Direct Access Inquiry:', 'Device set as Direct Access') ELSE outlist('Device set as Optical:', 'Disabled')    
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$21')
    ENDIF

ENDPROC





/*
** Handler for a specific mode page
*/
PROC process_modesense_2A(page)

    IF global_devtype=DEV_CDROM
        outlist('\ebInformation Page:\en', 'CDROM Capabilities and Mechanical Status')
        outlist('\ebPage Code:\en', '$2A')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_i('\ebMaximum Supported Speed:\en', Int(page+8),' kbyte/sec')
        outlist_i('\ebMinimum Supported Speed:\en', Int(page+10), ' kbyte/sec')
        outlist_i('\ebBuffer Size:\en', Int(page+12), ' K')
        outlist_i('\ebCurrent Selected Speed:\en', Int(page+14), ' kbyte/sec')
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$2A')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_2F(page)

    IF global_devtype=DEV_DIRECT
        outlist('\ebInformation Page:\en', 'Spindown Timing')
        outlist('\ebWarning:\en', 'Page format may be device specific. Info may be incorrect')
        outlist('\ebReference:\en', 'Iomega ZIP Drive')
        outlist('\ebPage Code:\en', '$2F')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        outlist_h('\ebFlags:\en', Char(page+2), NIL)
        outlist_i('\ebSpindown Delay:\en', Char(page+3), ' minutes')
        outlist_i('\ebTimer 2:\en', Char(page+4),  ' minutes')
        outlist_i('\ebTimer 3:\en', Char(page+5),  ' minutes')
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$2F')
    ENDIF

ENDPROC


/*
** Handler for a specific mode page
*/
PROC process_modesense_39(page) -> DONE

    IF global_devtype=DEV_DIRECT
        outlist('\ebInformation Page:\en', 'Quantum Unique Drive Control (Quantum)')
        outlist('\ebWarning:\en', 'Page format may be device specific. Info may be incorrect')
        outlist('\ebReference:\en', 'Quantum Fireball ST 2.1/3.2/4.3/6.4 GB S')
        outlist('\ebPage Code:\en', '$39')
        IF ((Char(page) AND %10000000) = 0) THEN outlist('\ebSave to NVRAM supported:\en', 'No') ELSE outlist('\ebSave to NVRAM supported:\en', 'Yes')
        outlist_i('\ebPage Length:\en', Char(page+1), ' bytes')
        IF (Char(page+2) AND %10000000) = 0 THEN outlist('\ebIdentify Out:\en', 'Identify required to disconnect') ELSE outlist('\ebDisable Identify Out:\en', 'Identify not required to disconnect/reconnect')
        IF (Char(page+2) AND %01000000) = 0 THEN outlist('\ebIdentify In:\en', 'Identify sent after reconnection') ELSE outlist('\ebDisable Identify In:\en', 'Identify not sent after reconnection')
        IF (Char(page+2) AND %00100000) = 0 THEN outlist('\ebPreserve Synchronous Mode:\en', 'Reset will clear synchronous parameters') ELSE outlist('\ebPreserve Synchronous Mode:\en', 'Reset won\at clear synchronous parameters')
        IF (Char(page+2) AND %00010000) = 0 THEN outlist('\ebReallocate Hard Errors:\en', 'No') ELSE outlist('\ebReallocate Hard Errors:\en', 'Yes')
        IF (Char(page+2) AND %00001000) = 0 THEN outlist('\ebFill Data Pattern:\en', 'Disabled') ELSE outlist('\ebFill Data Pattern:\en', 'Enabled')
        IF (Char(page+2) AND %00000100) = 0 THEN outlist('\ebSend Synchronous Message:\en', 'No') ELSE outlist('\ebSend Synchronous Message:\en', 'Yes')
        IF (Char(page+2) AND %00000010) = 0 THEN outlist('\ebDisable Unit Attention:\en', 'No') ELSE outlist('\ebDisable Unit Attention:\en', 'Yes')
        IF (Char(page+2) AND %00000001) = 0 THEN outlist('\ebDisable Reselection Timeout:\en', 'No') ELSE outlist('\ebDisable Reselection Timeout:\en', 'Yes')
        IF (Char(page+3) AND %10000000) = 0 THEN outlist('\ebDisable Disconnection:\en', 'No') ELSE outlist('\ebDisable Disconnection:\en', 'Yes')
        IF (Char(page+3) AND %00001000) = 0 THEN outlist('\ebSoftware Selectable SCSI ID:\en', 'ID assigned by jumpers') ELSE outlist('\ebSoftware Selectable SCSI ID:\en', 'ID assigned by software (jumpers ignored)')
        outlist_i('\ebSoftware SCSI ID:\en', (Char(page+3) AND %00000111), NIL)
        IF (Char(page+4) AND %00010000) = 0 THEN outlist('\ebPlug n Play SCSI:\en', 'Enabled')  ELSE outlist('\ebPlug n Play SCSI:\en', 'Disabled')
        IF (Char(page+4) AND %00001000) = 0 THEN outlist('\ebUse Motor Delay Time:\en', 'No') ELSE outlist('\ebUse Motor Delay Time:\en', 'Yes')
        IF (Char(page+4) AND %00000010) = 0 THEN outlist('\ebParity Control:\en', 'Disabled') ELSE outlist('\ebDisable Parity Control:\en', 'Enabled')
        IF (Char(page+4) AND %00000001) = 0 THEN outlist('\ebPerform Wait/Spin:\en', 'No') ELSE outlist('\ebPerform Wait/Spin:\en', 'Yes')
        outlist_i('\ebMotor Delay Time:\en', Char(page+5), ' *10 ms')
    ELSE
        outlist('\ebInformation Page:\en', 'Unsupported or Reserved for this device class')
        outlist('\ebPage Code:\en', '$39')
    ENDIF

ENDPROC
