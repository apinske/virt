#define _GNU_SOURCE
#include <fcntl.h>
#include <grp.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

void write_file(char* filename, char* content);

int container(void *args) {
    printf("pid of container: %d\n", getpid());
    clearenv();
    chroot("./slash");
    chdir("/");
    mount("proc", "/proc", "proc", 0, "");
    write_file("/proc/self/uid_map", "0 1000 1\n");
    write_file("/proc/self/setgroups", "deny");
    write_file("/proc/self/gid_map", "0 1000 1\n");
    printf("container starting\n");
    execl("/bin/ash", "/bin/ash", NULL);
    perror("exec");
    return 1;
}

int main(void) {
    printf("pid of parent: %d\n", getpid());
    pid_t container_pid = clone(container, malloc(4096) + 4096, SIGCHLD | CLONE_NEWUSER | CLONE_NEWUTS | CLONE_NEWPID | CLONE_NEWIPC | CLONE_NEWNS | CLONE_NEWNET, NULL);
    if (container_pid < 0) {
        perror("clone");
        return 1;
    }
    printf("pid of container in parent: %d\n", container_pid);
    waitpid(container_pid, NULL, 0);
    printf("container exited\n");
    umount("./slash/proc");
    return 0;
}

void write_file(char* filename, char* content) {
    int fd = open(filename, O_RDWR);
    if (fd < 0) {
        perror("open");
        exit(1);
    }
    if (write(fd, content, strlen(content)) < 0) {
        perror("write");
        exit(1);
    }
    if (close(fd) < 0) {
        perror("close");
        exit(1);
    }
}
