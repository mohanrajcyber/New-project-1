/*
 * aaha — tiny operator CLI for AahaOS.
 *
 * Commands: status, net, lock, help
 * "lock" is a documented stub (read-only-root reminder), not a security
 * control and not a backdoor.
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <sys/utsname.h>
#include <unistd.h>

static void usage(void)
{
    fputs("aaha — AahaOS operator CLI\n"
          "\n"
          "Usage: aaha <command>\n"
          "\n"
          "  status   OS identity, kernel, hostname\n"
          "  net      local interfaces (no scanner, no exploit tools)\n"
          "  lock     read-only-root reminder (v1 stub)\n"
          "  help     this text\n",
          stdout);
}

static void cmd_status(void)
{
    struct utsname uts;
    char host[64] = "?";
    FILE *fp;

    gethostname(host, sizeof(host));
    fputs("AahaOS status\n", stdout);
    fputs("-------------\n", stdout);
    fputs("os        : AahaOS (custom embedded Linux)\n", stdout);
    fputs("not       : VMware, Windows, Alpine installer, from-scratch kernel\n",
          stdout);

    fp = fopen("/etc/os-release", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            if (strncmp(line, "PRETTY_NAME=", 12) == 0 ||
                strncmp(line, "VERSION_ID=", 11) == 0 ||
                strncmp(line, "ID=", 3) == 0) {
                fputs(line, stdout);
            }
        }
        fclose(fp);
    }

    printf("hostname  : %s\n", host);
    if (uname(&uts) == 0) {
        printf("kernel    : %s %s (%s)\n", uts.sysname, uts.release,
               uts.machine);
    }
    fputs("rootfs    : initramfs (ephemeral). Persist is a later host job.\n",
          stdout);
    fputs("auth      : no password login; console only.\n", stdout);
}

static void cmd_net(void)
{
    fputs("AahaOS net (local view)\n", stdout);
    fputs("-----------------------\n", stdout);
    if (access("/proc/net/dev", R_OK) == 0) {
        FILE *fp = fopen("/proc/net/dev", "r");
        char line[256];
        if (fp) {
            while (fgets(line, sizeof(line), fp)) {
                fputs(line, stdout);
            }
            fclose(fp);
        }
    } else {
        fputs("no /proc/net/dev — proc not mounted?\n", stdout);
    }
    fputs("\nThis command only lists what the kernel already exposes.\n",
          stdout);
}

static void cmd_lock(void)
{
    fputs("aaha lock (v1 stub)\n", stdout);
    fputs("-------------------\n", stdout);
    fputs("AahaOS v1 boots an ephemeral initramfs. Treat the guest as\n",
          stdout);
    fputs("read-only: reboot loses /tmp. There is no disk unlock secret,\n",
          stdout);
    fputs("no default password, and no remote lock service.\n", stdout);
    fputs("\nNot armed. Not a backdoor. PocketHost will own persist later.\n",
          stdout);
}

int main(int argc, char **argv)
{
    const char *cmd;

    if (argc < 2) {
        usage();
        return 1;
    }
    cmd = argv[1];
    if (strcmp(cmd, "status") == 0) {
        cmd_status();
        return 0;
    }
    if (strcmp(cmd, "net") == 0) {
        cmd_net();
        return 0;
    }
    if (strcmp(cmd, "lock") == 0) {
        cmd_lock();
        return 0;
    }
    if (strcmp(cmd, "help") == 0 || strcmp(cmd, "-h") == 0 ||
        strcmp(cmd, "--help") == 0) {
        usage();
        return 0;
    }
    fprintf(stderr, "aaha: unknown command '%s'\n", cmd);
    usage();
    return 1;
}
