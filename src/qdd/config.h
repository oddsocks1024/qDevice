/* Compile Time Configuration for qdd */

/* Uncomment this line if compiling on Linux (remove //) */
//#define LINUX 1

/* Uncomment this line if compiling on Linux (remove //) */
//#define SOLARIS 1

/* Uncomment this line if compiling on IRIX (remove //) */
/* WARNING: IRIX Support is not stable */
//#define IRIX 1

/* The base port to listen for connections, increases by 1 for each consecutive device */
#define SERVER_PORT 8000

/* The receiving buffer size, change only if you need to */
#define RECV_BUFLEN 548

/* The buffer size for returned SCSI data, change only if you need to */
#define DATA_BUFLEN 255

/* The buffer size for sense data, change only if you need to */
#define SENS_BUFLEN 255

/* The maximum length of a device name including path, change only if you need to */
#define DEVICENAMELEN 255


#ifdef LINUX
    /*Maximum number of devices to scan for*/
    #define MAX_DEVICES 31
#endif

#ifdef SOLARIS
    /*Maximum number of devices to scan for (on FIRST controller only) */
    #define MAX_DEVICES 8
#endif

#ifdef IRIX
    /*Maximum number of devices to scan for (on FIRST controller only) */
    #define MAX_DEVICES 16
#endif




