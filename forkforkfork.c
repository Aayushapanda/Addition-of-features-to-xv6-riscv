// user/forkforkfork.c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  // A simple chain of forks: each child keeps forking; the parent exits after waiting
  // for just its immediate child. This creates a long sequence of PIDs and many
  // failed forks near resource exhaustion, producing lots of "fork -> -1" lines
  // when tracing is enabled.
  printf("test forkforkfork: ");

  for (;;) {
    int pid = fork();
    if (pid < 0) {
      // fork failed in this process (likely resource limit) — just exit.
      // The kernel trace will show "fork -> -1" for this PID.
      exit(0);
    }
    if (pid == 0) {
      // Child: keep looping to try for another fork.
      // (This makes a chain rather than an exponential explosion.)
      // Optionally add a tiny sleep to stagger output:
      // sleep(1);
      continue;
    } else {
      // Parent: wait for this one child, then say OK and exit.
      // This ensures only the deepest branch keeps forking.
      wait(0);
      printf("OK\n");
      exit(0);
    }
  }
}
