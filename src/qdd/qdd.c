/*
Program: Q-Device Daemon
Version: 0.5
Author: Ian Chpman

Please read the documentation before attempting to compile or use qdd.
*/

#include "version.h"
#include "config.h"
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <netinet/in.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/types.h>

#ifdef SOLARIS
#include <sys/scsi/impl/uscsi.h>
#include <sys/scsi/generic/commands.h>
#endif

#ifdef LINUX
#include <scsi/sg.h>
#endif

#ifdef IRIX
#include <sys/dsreq.h>
#endif


#define EXIT_OK      0
#define EXIT_SOCKET  1
#define EXIT_RECV    2
#define EXIT_SEND    3
#define EXIT_SCSI    4

int sock[MAX_DEVICES];
int sg_fd[MAX_DEVICES];
int found = -1;
struct sockaddr_in saou[MAX_DEVICES];

void close_all(int signum)
{
    int loop;

    for (loop = 0; loop < MAX_DEVICES; loop++)
    {
        if (sock[loop] > 0)
        {
            close(sock[loop]);
            fprintf(stderr, "Closing Socket: %d\n", loop);
        }

        if (sg_fd[loop] > 0)
        {
            close(sg_fd[loop]);
            fprintf(stderr, "Closing Device: %d\n", loop);
        }
    }

    exit(EXIT_OK);
}

void new_server(int servnum)
{
    struct sockaddr_in sain;

    fprintf(stderr, "Setting up new server on port %d\n", SERVER_PORT + servnum);

    if ((sock[servnum] = socket(PF_INET, SOCK_DGRAM, 0)) == -1 )
    {
        perror("Unable to open socket");
        exit(EXIT_SOCKET);
    }
    else
    {
        sain.sin_family = AF_INET;
        sain.sin_port = htons(SERVER_PORT + servnum);
        sain.sin_addr.s_addr = htonl(INADDR_ANY);
        memset(&(sain.sin_zero), '\0', 8); // zero the rest of the struct

        if ((bind(sock[servnum], (struct sockaddr *)&sain, sizeof(struct sockaddr))) == -1)
        {
            perror("Unable to bind socket");
            exit(EXIT_SOCKET);
        }
    }
}

void put_to(unsigned char *buffer, int socknum, int size)
{
    int numbytes;

    fprintf(stderr, "Sending SCSI reply to remote host\n");

    if ((numbytes=sendto(sock[socknum], buffer, size, 0, (struct sockaddr *)&saou[socknum], sizeof(struct sockaddr))) == -1)
    {
        perror("sendto");
        exit(EXIT_SEND);
    }
}

void dump(unsigned char *buffer, int cmd_size)
{
    int loop;

    printf("DATA SIZE: %i bytes\n", cmd_size);
    printf("DATA HEX DUMP: ");
    for (loop=0; loop < cmd_size; loop++)
    {
        printf("%X ", buffer[loop]);
    }
    printf("\n");

    printf("DATA DEC DUMP: ");
    for (loop=0; loop < cmd_size; loop++)
    {
        printf("%i ", buffer[loop]);
    }
    printf("\n");
}


int main(int argc, char * argv[])
{
    int loop;
    int numbytes;
    char devicename[DEVICENAMELEN];
    unsigned char sense_buffer[SENS_BUFLEN];
    unsigned char recv_buffer[RECV_BUFLEN];
    unsigned char data_buffer[DATA_BUFLEN];
    unsigned char scsi_status;

    #ifdef LINUX
    printf("Q-Device! Daemon %d.%d for Linux\n", MAJORVERSION, MINORVERSION);
    printf("Send SIGINT (CTRL-C) to Exit\n");
    #endif

    #ifdef SOLARIS
    printf("Q-Device! Daemon %d.%d for Solaris\n", MAJORVERSION, MINORVERSION);
    printf("Send SIGINT (CTRL-C) to Exit\n");
    printf("NOTE: On Solaris Q-Device! daemon is only capable of finding hard disks\n");
    printf("and possibly tape drives on the first SCSI controller ONLY\n");
    #endif

    #ifdef IRIX
    printf("Q-Device! Daemon %d.%d for IRIX\n", MAJORVERSION, MINORVERSION);
    printf("Send SIGINT (CTRL-C) to Exit\n");
    #endif

    signal (SIGINT, close_all);
    signal (SIGTERM, close_all);

    for (loop = 0; loop < MAX_DEVICES ; loop++)
    {

        #ifdef LINUX
        sprintf(devicename, "/dev/sg%i", loop);
        #endif

        #ifdef SOLARIS
        sprintf(devicename, "/dev/rdsk/c0t%dd0s0", loop);
        #endif

        #ifdef IRIX
        sprintf(devicename, "/dev/scsi/sc0d%dl0", loop);
        #endif

        if ((sg_fd[loop] = open_dev(devicename)) < 0)
        {
            fprintf(stderr, "%s: No Device Found\n", devicename);
        }
        else
        {
            found = 1;
            fprintf(stderr, "%s: Found Device\n", devicename);
            new_server(loop);
        }
    }

    if (found < 0)
    {
        fprintf(stderr, "%s: No devices at all were found. Exiting.");
        exit(EXIT_OK);
    }


    while ((loop = listen_func()) > -1)
    {
        bzero(&data_buffer, DATA_BUFLEN);
        numbytes = get_from(&recv_buffer, loop);
        fprintf(stderr, "Dumping scsi command\n");
        dump(&recv_buffer, numbytes);

        if (recv_buffer[0] == 0x3)
        {
            fprintf(stderr, "Dumping scsi sense data buffer\n");
            dump(&sense_buffer, SENS_BUFLEN);
            put_to(&sense_buffer, loop, SENS_BUFLEN);
        }
        else
        {
            if ((scsi_status = send_scsi(&data_buffer, &recv_buffer, &sense_buffer, numbytes, loop)) != 0)
            {
                fprintf(stderr, "Dumping scsi error status buffer\n");
                dump(&scsi_status, sizeof(unsigned char));
                put_to(&scsi_status, loop, sizeof(unsigned char));
            }
            else
            {
                fprintf(stderr, "Dumping scsi data buffer\n");
                dump(&data_buffer, DATA_BUFLEN);
                put_to(&data_buffer, loop, DATA_BUFLEN);
            }
        }
    }

    exit(EXIT_OK);

}


int listen_func(void)
{
    int loop;
    int highest = 0;

    struct timeval tv;
    fd_set readfds;

    tv.tv_sec = 1;
    tv.tv_usec = 5;

    fprintf(stderr, "Listening for SCSI commands\n");

    FD_ZERO(&readfds);

    for (loop = 0; loop < MAX_DEVICES; loop ++)
    {
        if (sock[loop] > highest)
            highest = loop;

        if (sock[loop] > 0)
            FD_SET(sock[loop], &readfds);
    }

    select(sock[highest]+1, &readfds, NULL, NULL, NULL);

    for (loop = 0; loop < MAX_DEVICES; loop++)
    {
        if (FD_ISSET(sock[loop], &readfds))
        {
            return loop;
        }
    }

    return -1;
}


int open_dev(char devicename[])
{

    //We need to open the device in RW mode, even though data is not being
    //written as some commands (mainly control) require this.
    fprintf(stderr, "Opening %s\n", devicename);

    return open(devicename, O_RDWR);
}


int get_from(unsigned char *buffer, int socknum)
{
    int addr_len;
    int numbytes;

    fprintf(stderr, "Received SCSI command from remote host\n");

    addr_len = sizeof(struct sockaddr);
    numbytes=recvfrom(sock[socknum], buffer, RECV_BUFLEN-1, 0, (struct sockaddr *)&saou[socknum], &addr_len);

    // Check to see if command received is a valid SCSI command size or exit
    if (numbytes == -1 && numbytes !=6 && numbytes !=10 && numbytes !=12)
    {
        perror("recvfrom");
        exit(EXIT_RECV);
    }

    return numbytes;
}


#ifdef LINUX
int send_scsi(unsigned char *databuffer, unsigned char *cmdbuffer, unsigned char *sensebuffer, int cmd_size, int sg_fdnum)
{
    sg_io_hdr_t io_hdr;

    fprintf(stderr, "Executing SCSI command on device: /dev/sg%d\n", sg_fdnum);

    memset(&io_hdr, 0, sizeof(sg_io_hdr_t));
    io_hdr.interface_id = 'S';
    io_hdr.cmd_len = cmd_size; //sizeof(scsicmd);
    io_hdr.mx_sb_len = SENS_BUFLEN;
    io_hdr.dxfer_direction = SG_DXFER_FROM_DEV;
    io_hdr.dxfer_len = DATA_BUFLEN;
    io_hdr.dxferp = databuffer;
    io_hdr.cmdp = cmdbuffer;
    io_hdr.sbp = sensebuffer;
    io_hdr.timeout = 20000; //milliseconds

    if (ioctl(sg_fd[sg_fdnum], SG_IO, &io_hdr) < 0)
    {
        perror("sg_simple0: ioctl error");
        exit(EXIT_SCSI);
    }

    return io_hdr.status;
}
#endif

#ifdef SOLARIS
int send_scsi(unsigned char *databuffer, unsigned char *cmdbuffer, unsigned char *sensebuffer, int cmd_size, int sg_fdnum)
{
    struct uscsi_cmd io_hdr;

    fprintf(stderr, "Executing SCSI command on device: /dev/c0t%dd0s0\n", sg_fdnum);

    io_hdr.uscsi_cdblen = cmd_size;
    io_hdr.uscsi_rqlen = SENS_BUFLEN;
    io_hdr.uscsi_flags = (USCSI_WRITE|USCSI_READ|USCSI_RQENABLE);
    io_hdr.uscsi_buflen = DATA_BUFLEN;
    io_hdr.uscsi_bufaddr = databuffer;
    io_hdr.uscsi_cdb = cmdbuffer;
    io_hdr.uscsi_rqbuf = sensebuffer;
    io_hdr.uscsi_timeout = 20; //seconds

    //Commented out because on Solaris an unsupported command seems to generate an ioctl error
    //where linux instead just treats this as normal but still fills the sense data
    if (ioctl(sg_fd[sg_fdnum], USCSICMD, &io_hdr) < 0)
    {
        perror("uscsi: ioctl error");
        exit(EXIT_SCSI);
    }

    return io_hdr.uscsi_status;
}
#endif

#ifdef IRIX
int send_scsi(unsigned char *databuffer, unsigned char *cmdbuffer, unsigned char *sensebuffer, int cmd_size, int sg_fdnum)
{
    struct dsreq io_hdr;

    fprintf(stderr, "Executing SCSI command on device: /dev/scsi/sc0d%dl0\n", sg_fdnum);

    io_hdr.ds_flags = (DSRQ_SENSE);
    io_hdr.ds_time  = 20000; //milliseconds
    io_hdr.ds_cmdbuf = cmdbuffer;
    io_hdr.ds_cmdlen = cmd_size;
    io_hdr.ds_databuf = databuffer;
    io_hdr.ds_datalen = DATA_BUFLEN;
    io_hdr.ds_sensebuf = sensebuffer;
    io_hdr.ds_senselen = SENS_BUFLEN;

    if (ioctl(sg_fd[sg_fdnum], DS_ENTER, &io_hdr) < 0)
    {
        perror("ds: ioctl error");
        exit(EXIT_SCSI);
    }

    return io_hdr.ds_status;

}
#endif

