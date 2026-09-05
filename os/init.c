/*
 * AahaOS PID 1 — custom userspace init (not a distro installer).
 *
 * Boots the embedded guest: mounts a minimal VFS, sets identity, prints
 * the AahaOS banner, then keeps a console shell alive. No password
 * login, no sshd, no remote services.
 *
 * License: MIT (this file). The Linux kernel you boot alongside is GPL-2.0.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/sysmacros.h>
#include <sys/mount.h>
#include <sys/reboot.h>
#include <sys/stat.h>
#include <sys/utsname.h>
#include <sys/wait.h>
#include <unistd.h>

#define HOSTNAME "aaha"
#define VERSION_PATH "/etc/aaha/version"

static void ignore_signal(int sig)
{
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = SIG_IGN;
    sigaction(sig, &sa, NULL);
}

static void reap_children(int sig)
{
    (void)sig;
    while (waitpid(-1, NULL, WNOHANG) > 0) {
    }
}

static void ensure_dir(const char *path, mode_t mode)
{
    if (mkdir(path, mode) < 0 && errno != EEXIST) {
        /* continue; some dirs exist in the image */
    }
}

static void try_mount(const char *src, const char *tgt, const char *fstype,
                      unsigned long flags, const void *data)
{
    ensure_dir(tgt, 0755);
    if (mount(src, tgt, fstype, flags, data) < 0) {
        fprintf(stderr, "aaha-init: mount %s (%s): %s\n", tgt, fstype,
                strerror(errno));
    }
}

static void print_file(const char *path)
{
    FILE *fp = fopen(path, "r");
    char buf[256];
    if (!fp) {
        return;
    }
    while (fgets(buf, sizeof(buf), fp)) {
        fputs(buf, stdout);
    }
    fclose(fp);
}

static void print_banner(void)
{
    struct utsname uts;
    char version[64] = "0.1.0";
    FILE *vf;

    vf = fopen(VERSION_PATH, "r");
    if (vf) {
        if (fgets(version, sizeof(version), vf)) {
            version[strcspn(version, "\r\n")] = '\0';
        }
        fclose(vf);
    }

    fputs("\n", stdout);
    print_file("/etc/aaha/banner");
    fputs("\n", stdout);
    printf("  AahaOS %s  —  custom embedded Linux guest\n", version);
    printf("  hostname : %s\n", HOSTNAME);
    if (uname(&uts) == 0) {
        printf("  kernel   : %s %s\n", uts.sysname, uts.release);
        printf("  machine  : %s\n", uts.machine);
    }
    fputs("  root     : initramfs (ephemeral, treat as read-only story)\n",
          stdout);
    fputs("  login    : none — console only, no password, no sshd\n", stdout);
    fputs("\n", stdout);
    print_file("/etc/motd");
    fputs("\n  Type  aaha help  —  or just use the shell.\n\n", stdout);
    fflush(stdout);
}

static void setup_identity(void)
{
    if (sethostname(HOSTNAME, strlen(HOSTNAME)) < 0) {
        perror("aaha-init: sethostname");
    }
    setenv("PATH", "/sbin:/usr/sbin:/bin:/usr/bin", 1);
    setenv("HOME", "/root", 1);
    setenv("USER", "aaha", 1);
    setenv("LOGNAME", "aaha", 1);
    setenv("TERM", "linux", 1);
    setenv("PS1", "aaha@aaha:\\w# ", 1);
    setenv("AAHAOS", "1", 1);
    if (chdir("/root") != 0) {
        if (chdir("/") != 0) {
            perror("aaha-init: chdir");
        }
    }
}

static void setup_vfs(void)
{
    ensure_dir("/proc", 0555);
    ensure_dir("/sys", 0555);
    ensure_dir("/dev", 0755);
    ensure_dir("/tmp", 01777);
    ensure_dir("/run", 0755);
    ensure_dir("/root", 0755);

    try_mount("proc", "/proc", "proc", MS_NOSUID | MS_NOEXEC | MS_NODEV, NULL);
    try_mount("sysfs", "/sys", "sysfs", MS_NOSUID | MS_NOEXEC | MS_NODEV, NULL);
    try_mount("devtmpfs", "/dev", "devtmpfs", MS_NOSUID, "mode=0755");
    try_mount("tmpfs", "/tmp", "tmpfs", MS_NOSUID | MS_NODEV, "mode=1777");
    try_mount("tmpfs", "/run", "tmpfs", MS_NOSUID | MS_NODEV, "mode=0755");

    ensure_dir("/dev/pts", 0755);
    try_mount("devpts", "/dev/pts", "devpts", MS_NOSUID | MS_NOEXEC,
              "mode=0620,ptmxmode=0666");

    if (access("/dev/null", F_OK) != 0) {
        mknod("/dev/null", S_IFCHR | 0666, makedev(1, 3));
    }
    if (access("/dev/console", F_OK) != 0) {
        mknod("/dev/console", S_IFCHR | 0600, makedev(5, 1));
    }
}

static void open_console(void)
{
    int fd = open("/dev/console", O_RDWR);
    if (fd < 0) {
        fd = open("/dev/ttyS0", O_RDWR);
    }
    if (fd < 0) {
        fd = open("/dev/ttyAMA0", O_RDWR);
    }
    if (fd >= 0) {
        dup2(fd, STDIN_FILENO);
        dup2(fd, STDOUT_FILENO);
        dup2(fd, STDERR_FILENO);
        if (fd > STDERR_FILENO) {
            close(fd);
        }
    }
}

static void run_shell(void)
{
    const char *shell = "/bin/sh";
    pid_t pid;
    int status;

    pid = fork();
    if (pid < 0) {
        perror("aaha-init: fork");
        sleep(2);
        return;
    }
    if (pid == 0) {
        setsid();
        ioctl(STDIN_FILENO, TIOCSCTTY, 0);
        signal(SIGINT, SIG_DFL);
        signal(SIGQUIT, SIG_DFL);
        signal(SIGTSTP, SIG_DFL);
        execl(shell, "sh", "-l", (char *)NULL);
        execl("/bin/busybox", "ash", "-l", (char *)NULL);
        _exit(127);
    }
    while (waitpid(pid, &status, 0) < 0 && errno == EINTR) {
    }
}

int main(int argc, char **argv)
{
    struct sigaction sa;

    (void)argc;
    (void)argv;

    if (getpid() == 1) {
        ignore_signal(SIGPIPE);
        ignore_signal(SIGINT);
        ignore_signal(SIGTSTP);
        memset(&sa, 0, sizeof(sa));
        sa.sa_handler = reap_children;
        sa.sa_flags = SA_NOCLDSTOP;
        sigaction(SIGCHLD, &sa, NULL);
    }

    setup_vfs();
    open_console();
    setup_identity();
    print_banner();
    if (access("/usr/bin/aaha", X_OK) == 0) {
        pid_t helper = fork();
        if (helper == 0) {
            execl("/usr/bin/aaha", "aaha", "status", (char *)NULL);
            _exit(127);
        }
        if (helper > 0) {
            int st = 0;
            while (waitpid(helper, &st, 0) < 0 && errno == EINTR) {
            }
            fputc('\n', stdout);
            fflush(stdout);
        }
    }

    /* PID 1 must not exit. */
    for (;;) {
        run_shell();
        fputs("\naaha-init: shell exited — restarting console.\n", stdout);
        fflush(stdout);
        sleep(1);
    }
}
