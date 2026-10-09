#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <strings.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <dirent.h>
#include <sys/ioctl.h>
#include <linux/hidraw.h>
#include <libusb-1.0/libusb.h>

#define LENOVO_VID             0x048d
#define LENOVO_PID             0xc963
#define RGB_REPORT_ID          0xcc
#define RGB_COMMAND            0x16
#define HID_SET_REPORT         0x09
#define HID_GET_REPORT         0x01
#define USB_HID_FEATURE_REPORT 0x03
#define TRANSFER_TIMEOUT_MS    1000

#define STATE_FILE_PATH "/home/vin/.config/quickshell/scripts/rgb_state.json"

static const char *DEFAULT_DEVPATH = "/dev/input/by-id/usb-ITE_Tech._Inc._ITE_Device_8295_-hidraw";

typedef struct {
    int supported;
    int permission;
    int power;
    int mode_num;       // 1=static, 3=breath, 4=wave, 6=smooth
    char mode_str[16];  // "static", "breath", "wave", "smooth"
    int speed;          // 1-4
    char brightness[8]; // "off", "low", "high"
    uint8_t colors[4][3]; // Zone 1-4 (R,G,B)
    char error[256];
} RgbState;

static void parse_hex(const char *str, uint8_t *r, uint8_t *g, uint8_t *b) {
    if (!str) return;
    if (str[0] == '#') str++;
    unsigned int val = 0;
    if (sscanf(str, "%x", &val) == 1) {
        *r = (val >> 16) & 0xff;
        *g = (val >> 8) & 0xff;
        *b = val & 0xff;
    }
}

static void load_state_file(RgbState *s) {
    // Default fallback values
    s->supported = 1;
    s->permission = 1;
    s->power = 1;
    s->mode_num = 4;
    strncpy(s->mode_str, "wave", sizeof(s->mode_str));
    s->speed = 1;
    strncpy(s->brightness, "high", sizeof(s->brightness));
    for (int i = 0; i < 4; i++) {
        s->colors[i][0] = 0;
        s->colors[i][1] = 212;
        s->colors[i][2] = 255;
    }
    s->error[0] = '\0';

    FILE *f = fopen(STATE_FILE_PATH, "r");
    if (!f) return;

    char buf[2048];
    size_t n = fread(buf, 1, sizeof(buf) - 1, f);
    fclose(f);
    if (n == 0) return;
    buf[n] = '\0';

    char mode_buf[32] = {0};
    if (sscanf(strstr(buf, "\"mode\":") ? strstr(buf, "\"mode\":") : "", "\"mode\": \"%31[^\"]\"", mode_buf) == 1) {
        strncpy(s->mode_str, mode_buf, sizeof(s->mode_str));
        if (strcasecmp(mode_buf, "static") == 0) s->mode_num = 1;
        else if (strcasecmp(mode_buf, "breath") == 0) s->mode_num = 3;
        else if (strcasecmp(mode_buf, "wave") == 0) s->mode_num = 4;
        else if (strcasecmp(mode_buf, "smooth") == 0) s->mode_num = 6;
    }

    char br_buf[16] = {0};
    if (sscanf(strstr(buf, "\"brightness\":") ? strstr(buf, "\"brightness\":") : "", "\"brightness\": \"%15[^\"]\"", br_buf) == 1) {
        strncpy(s->brightness, br_buf, sizeof(s->brightness));
        if (strcasecmp(br_buf, "off") == 0) s->power = 0;
        else s->power = 1;
    }

    int spd = 1;
    if (sscanf(strstr(buf, "\"speed\":") ? strstr(buf, "\"speed\":") : "", "\"speed\": %d", &spd) == 1) {
        if (spd >= 1 && spd <= 4) s->speed = spd;
    }

    // Parse zones
    char *z_ptr = strstr(buf, "\"zones\":");
    if (z_ptr) {
        char hex[16];
        for (int i = 0; i < 4; i++) {
            char *q1 = strchr(z_ptr, '"');
            if (!q1) break;
            char *q2 = strchr(q1 + 1, '"');
            if (!q2) break;
            // check if inside zones
            if (i == 0 && strncmp(q1 + 1, "zones", 5) == 0) {
                z_ptr = q2 + 1;
                i--;
                continue;
            }
            int len = q2 - (q1 + 1);
            if (len > 0 && len < 15) {
                strncpy(hex, q1 + 1, len);
                hex[len] = '\0';
                parse_hex(hex, &s->colors[i][0], &s->colors[i][1], &s->colors[i][2]);
            }
            z_ptr = q2 + 1;
        }
    }
}

static void save_state_file(const RgbState *s) {
    FILE *f = fopen(STATE_FILE_PATH, "w");
    if (!f) return;

    fprintf(f, "{\n");
    fprintf(f, "  \"supported\": %s,\n", s->supported ? "true" : "false");
    fprintf(f, "  \"permission\": %s,\n", s->permission ? "true" : "false");
    fprintf(f, "  \"power\": %s,\n", s->power ? "true" : "false");
    fprintf(f, "  \"mode\": \"%s\",\n", s->mode_str);
    fprintf(f, "  \"speed\": %d,\n", s->speed);
    fprintf(f, "  \"brightness\": \"%s\",\n", s->brightness);
    fprintf(f, "  \"zones\": [\n");
    for (int i = 0; i < 4; i++) {
        fprintf(f, "    \"#%02x%02x%02x\"%s\n",
                s->colors[i][0], s->colors[i][1], s->colors[i][2],
                (i < 3) ? "," : "");
    }
    fprintf(f, "  ],\n");
    if (s->error[0] != '\0') {
        fprintf(f, "  \"error\": \"%s\"\n", s->error);
    } else {
        fprintf(f, "  \"error\": null\n");
    }
    fprintf(f, "}\n");
    fclose(f);
}

static void print_json(const RgbState *s) {
    printf("{\n");
    printf("  \"supported\": %s,\n", s->supported ? "true" : "false");
    printf("  \"permission\": %s,\n", s->permission ? "true" : "false");
    printf("  \"power\": %s,\n", s->power ? "true" : "false");
    printf("  \"mode\": \"%s\",\n", s->mode_str);
    printf("  \"speed\": %d,\n", s->speed);
    printf("  \"brightness\": \"%s\",\n", s->brightness);
    printf("  \"zones\": [\n");
    for (int i = 0; i < 4; i++) {
        printf("    \"#%02x%02x%02x\"%s\n",
               s->colors[i][0], s->colors[i][1], s->colors[i][2],
               (i < 3) ? "," : "");
    }
    printf("  ],\n");
    if (s->error[0] != '\0') {
        printf("  \"error\": \"%s\"\n", s->error);
    } else {
        printf("  \"error\": null\n");
    }
    printf("}\n");
}

static int find_hidraw_device(char *out_path, size_t max_len) {
    if (access(DEFAULT_DEVPATH, F_OK) == 0) {
        strncpy(out_path, DEFAULT_DEVPATH, max_len);
        return 0;
    }

    DIR *dir = opendir("/sys/class/hidraw");
    if (!dir) return -1;

    struct dirent *ent;
    int found = -1;
    while ((ent = readdir(dir)) != NULL) {
        if (strncmp(ent->d_name, "hidraw", 6) != 0) continue;
        char uevent_path[256];
        snprintf(uevent_path, sizeof(uevent_path), "/sys/class/hidraw/%s/device/uevent", ent->d_name);
        FILE *f = fopen(uevent_path, "r");
        if (!f) continue;
        char line[256];
        int match_vid = 0, match_pid = 0, match_if0 = 0;
        while (fgets(line, sizeof(line), f)) {
            if (strstr(line, "HID_ID=0003:0000048D:0000C963") ||
                strstr(line, "HID_ID=0003:048D:C963")) {
                match_vid = 1; match_pid = 1;
            }
            if (strstr(line, ":1.0/") || strstr(line, ".0003") || strstr(line, "HID_NAME=ITE Tech. Inc. ITE Device(8295)")) {
                match_if0 = 1;
            }
        }
        fclose(f);
        if (match_vid && match_pid && match_if0) {
            snprintf(out_path, max_len, "/dev/%s", ent->d_name);
            found = 0;
            break;
        }
    }
    closedir(dir);
    return found;
}

static int send_hardware_packet(const uint8_t *packet, size_t len, char *err_buf, size_t err_len) {
    char devpath[256];
    if (find_hidraw_device(devpath, sizeof(devpath)) == 0) {
        int fd = open(devpath, O_RDWR);
        if (fd >= 0) {
            int res = ioctl(fd, HIDIOCSFEATURE(len), packet);
            close(fd);
            if (res >= 0) {
                return 0; // Success via hidraw ioctl!
            }
            snprintf(err_buf, err_len, "HIDIOCSFEATURE ioctl failed: %s", strerror(errno));
        } else {
            if (errno == EACCES || errno == EPERM) {
                snprintf(err_buf, err_len, "Permission denied accessing %s", devpath);
            } else {
                snprintf(err_buf, err_len, "Failed opening %s: %s", devpath, strerror(errno));
            }
        }
    } else {
        snprintf(err_buf, err_len, "Lenovo RGB device not found in /dev/hidraw*");
    }

    // Secondary fallback: libusb control transfer
    if (libusb_init(NULL) == 0) {
        libusb_device_handle *dev = libusb_open_device_with_vid_pid(NULL, LENOVO_VID, LENOVO_PID);
        if (dev) {
            libusb_set_auto_detach_kernel_driver(dev, 1);
            if (libusb_claim_interface(dev, 0) == 0) {
                int r_res = libusb_control_transfer(dev,
                    LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE,
                    HID_SET_REPORT,
                    (USB_HID_FEATURE_REPORT << 8) | RGB_REPORT_ID,
                    0,
                    (unsigned char *)packet,
                    len,
                    TRANSFER_TIMEOUT_MS);
                libusb_release_interface(dev, 0);
                libusb_close(dev);
                libusb_exit(NULL);
                if (r_res == (int)len) {
                    err_buf[0] = '\0';
                    return 0; // Success via libusb!
                }
                snprintf(err_buf, err_len, "libusb_control_transfer error code %d", r_res);
                return -1;
            }
            libusb_close(dev);
        } else {
            // libusb open failed (likely permission denied)
            snprintf(err_buf, err_len, "Permission denied accessing USB 048d:c963. Install udev rule: sudo cp /home/vin/.config/quickshell/scripts/99-lenovo-rgb.rules /etc/udev/rules.d/ && sudo udevadm trigger");
        }
        libusb_exit(NULL);
    }
    return -1;
}

static int read_hardware_packet(uint8_t *packet, size_t len) {
    char devpath[256];
    if (find_hidraw_device(devpath, sizeof(devpath)) == 0) {
        int fd = open(devpath, O_RDWR);
        if (fd >= 0) {
            packet[0] = RGB_REPORT_ID;
            int res = ioctl(fd, HIDIOCGFEATURE(len), packet);
            close(fd);
            if (res >= 0 && packet[0] == RGB_REPORT_ID && packet[1] == RGB_COMMAND) {
                return 0; // Successfully read from hardware!
            }
        }
    }
    return -1;
}

int main(int argc, char **argv) {
    RgbState state;
    load_state_file(&state);

    // Check device existence
    char devpath[256];
    if (find_hidraw_device(devpath, sizeof(devpath)) != 0 && access("/dev/bus/usb", F_OK) != 0) {
        state.supported = 0;
        state.permission = 0;
        snprintf(state.error, sizeof(state.error), "No Lenovo RGB keyboard hardware found");
        print_json(&state);
        return 0;
    }

    // Try reading hardware packet directly
    uint8_t read_pkt[33] = {0};
    if (read_hardware_packet(read_pkt, sizeof(read_pkt)) == 0) {
        state.permission = 1;
        state.mode_num = read_pkt[2];
        if (state.mode_num == 1) strncpy(state.mode_str, "static", sizeof(state.mode_str));
        else if (state.mode_num == 3) strncpy(state.mode_str, "breath", sizeof(state.mode_str));
        else if (state.mode_num == 4) strncpy(state.mode_str, "wave", sizeof(state.mode_str));
        else if (state.mode_num == 6) strncpy(state.mode_str, "smooth", sizeof(state.mode_str));
        state.speed = read_pkt[3];
        if (read_pkt[4] == 0) {
            strncpy(state.brightness, "off", sizeof(state.brightness));
            state.power = 0;
        } else if (read_pkt[4] == 1) {
            strncpy(state.brightness, "low", sizeof(state.brightness));
            state.power = 1;
        } else {
            strncpy(state.brightness, "high", sizeof(state.brightness));
            state.power = 1;
        }
        for (int z = 0; z < 4; z++) {
            state.colors[z][0] = read_pkt[5 + z*3 + 0];
            state.colors[z][1] = read_pkt[5 + z*3 + 1];
            state.colors[z][2] = read_pkt[5 + z*3 + 2];
        }
    }

    if (argc < 2 || strcmp(argv[1], "status") == 0 || strcmp(argv[1], "--status") == 0) {
        // Quick permission check
        if (access(devpath, R_OK | W_OK) != 0) {
            state.permission = 0;
            snprintf(state.error, sizeof(state.error),
                     "Permission denied. Install rule: sudo cp /home/vin/.config/quickshell/scripts/99-lenovo-rgb.rules /etc/udev/rules.d/ && sudo udevadm trigger");
        } else {
            state.permission = 1;
            state.error[0] = '\0';
        }
        print_json(&state);
        return 0;
    }

    // Parse set command arguments
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--mode=", 7) == 0) {
            const char *m = argv[i] + 7;
            if (strcasecmp(m, "static") == 0) { state.mode_num = 1; strncpy(state.mode_str, "static", sizeof(state.mode_str)); }
            else if (strcasecmp(m, "breath") == 0) { state.mode_num = 3; strncpy(state.mode_str, "breath", sizeof(state.mode_str)); }
            else if (strcasecmp(m, "wave") == 0) { state.mode_num = 4; strncpy(state.mode_str, "wave", sizeof(state.mode_str)); }
            else if (strcasecmp(m, "smooth") == 0) { state.mode_num = 6; strncpy(state.mode_str, "smooth", sizeof(state.mode_str)); }
            state.power = 1;
        } else if (strncmp(argv[i], "--brightness=", 13) == 0) {
            const char *br = argv[i] + 13;
            if (strcasecmp(br, "off") == 0) { strncpy(state.brightness, "off", sizeof(state.brightness)); state.power = 0; }
            else if (strcasecmp(br, "low") == 0) { strncpy(state.brightness, "low", sizeof(state.brightness)); state.power = 1; }
            else if (strcasecmp(br, "high") == 0) { strncpy(state.brightness, "high", sizeof(state.brightness)); state.power = 1; }
        } else if (strncmp(argv[i], "--speed=", 8) == 0) {
            int spd = atoi(argv[i] + 8);
            if (spd >= 1 && spd <= 4) state.speed = spd;
        } else if (strncmp(argv[i], "--color=", 8) == 0) {
            uint8_t cr, cg, cb;
            parse_hex(argv[i] + 8, &cr, &cg, &cb);
            for (int z = 0; z < 4; z++) {
                state.colors[z][0] = cr; state.colors[z][1] = cg; state.colors[z][2] = cb;
            }
            state.mode_num = 1;
            strncpy(state.mode_str, "static", sizeof(state.mode_str));
            state.power = 1;
        } else if (strncmp(argv[i], "--zone1=", 8) == 0) {
            parse_hex(argv[i] + 8, &state.colors[0][0], &state.colors[0][1], &state.colors[0][2]);
        } else if (strncmp(argv[i], "--zone2=", 8) == 0) {
            parse_hex(argv[i] + 8, &state.colors[1][0], &state.colors[1][1], &state.colors[1][2]);
        } else if (strncmp(argv[i], "--zone3=", 8) == 0) {
            parse_hex(argv[i] + 8, &state.colors[2][0], &state.colors[2][1], &state.colors[2][2]);
        } else if (strncmp(argv[i], "--zone4=", 8) == 0) {
            parse_hex(argv[i] + 8, &state.colors[3][0], &state.colors[3][1], &state.colors[3][2]);
        }
    }

    // Build hardware packet
    uint8_t p[33] = {0};
    p[0] = RGB_REPORT_ID;
    p[1] = RGB_COMMAND;
    p[2] = state.mode_num;
    p[3] = state.speed;
    p[4] = (!state.power || strcmp(state.brightness, "off") == 0) ? 0 : (strcmp(state.brightness, "low") == 0 ? 1 : 2);

    if (state.mode_num == 4) {
        // Wave mode: set LeftWave direction (p[19] = 1)
        p[19] = 1;
    }

    for (int z = 0; z < 4; z++) {
        if (!state.power || strcmp(state.brightness, "off") == 0) {
            p[5 + z*3 + 0] = 0;
            p[5 + z*3 + 1] = 0;
            p[5 + z*3 + 2] = 0;
        } else {
            p[5 + z*3 + 0] = state.colors[z][0];
            p[5 + z*3 + 1] = state.colors[z][1];
            p[5 + z*3 + 2] = state.colors[z][2];
        }
    }

    char err_msg[256] = {0};
    int send_rc = send_hardware_packet(p, sizeof(p), err_msg, sizeof(err_msg));
    if (send_rc == 0) {
        state.permission = 1;
        state.error[0] = '\0';
        save_state_file(&state);
    } else {
        state.permission = 0;
        snprintf(state.error, sizeof(state.error), "%s", err_msg);
    }

    print_json(&state);
    return (send_rc == 0) ? 0 : 1;
}
