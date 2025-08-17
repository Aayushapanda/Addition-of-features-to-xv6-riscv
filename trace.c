#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if(argc < 3){
    fprintf(2, "usage: trace mask command [args...]\n");
    exit(1);
  }

  // parse mask
  int mask = atoi(argv[1]);
  if(mask < 0) {
    mask = 2147483647; // -1 means trace all syscalls
  }

  if(trace(mask) < 0){
    fprintf(2, "trace: trace syscall failed\n");
    exit(1);
  }

  // shift arguments so exec sees the command correctly
  exec(argv[2], &argv[2]);
  
  // only reaches here if exec failed
  fprintf(2, "trace: exec %s failed\n", argv[2]);
  exit(1);
}
