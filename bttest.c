//user/bttest.c
 #include "kernel/types.h"
 #include "user/user.h"
 int
 main(int argc,char *argv[])
 {
 //Callsleep(1)sosys_sleep()runsinkernelandtriggers
 //backtrace()
 sleep(1);
 printf("bttest: returned from sleep\n");
 exit(0);
 }