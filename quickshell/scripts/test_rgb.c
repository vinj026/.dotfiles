#include <libusb-1.0/libusb.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LENOVO_VENDOR_ID       0x048d
#define RGB_REPORT_ID          0xcc
#define RGB_COMMAND            0x16
#define HID_SET_REPORT         0x09
#define USB_HID_FEATURE_REPORT 0x03
#define TRANSFER_TIMEOUT_MS    1000

static const uint16_t LENOVO_PRODUCT_IDS[] = {
    0xc963, 0xc973, 0xc983, 0xc993, 0xc955, 0xc965, 0xc975, 0xc984, 0xc985, 0xc994, 0xc995
};

int main(int argc, char **argv) {
    // Mode: 1=static, 3=breath, 4=wave, 6=smooth
    // Speed: 1-4
    // Brightness: 0=off, 1=low, 2=high
    // Colors: 4 zones (R,G,B)
    uint8_t mode = 1;
    uint8_t speed = 1;
    uint8_t brightness = 2; // high
    uint8_t r = 0, g = 200, b = 255; // Cyan

    uint8_t p[33] = {0};
    p[0] = RGB_REPORT_ID;
    p[1] = RGB_COMMAND;
    p[2] = mode;
    p[3] = speed;
    p[4] = brightness;
    for (int z = 0; z < 4; z++) {
        p[5 + z*3 + 0] = r;
        p[5 + z*3 + 1] = g;
        p[5 + z*3 + 2] = b;
    }

    if (libusb_init(NULL) != 0) {
        fprintf(stderr, "libusb_init failed\n");
        return 1;
    }

    libusb_device_handle *dev = NULL;
    for (size_t i = 0; i < sizeof(LENOVO_PRODUCT_IDS)/sizeof(LENOVO_PRODUCT_IDS[0]); i++) {
        dev = libusb_open_device_with_vid_pid(NULL, LENOVO_VENDOR_ID, LENOVO_PRODUCT_IDS[i]);
        if (dev) {
            printf("Found device 0x%04x\n", LENOVO_PRODUCT_IDS[i]);
            break;
        }
    }

    if (!dev) {
        fprintf(stderr, "No Lenovo RGB device opened (try running with pkexec / root or check permissions)\n");
        libusb_exit(NULL);
        return 2;
    }

    libusb_set_auto_detach_kernel_driver(dev, 1);
    if (libusb_claim_interface(dev, 0) != 0) {
        fprintf(stderr, "Failed to claim interface 0\n");
        libusb_close(dev);
        libusb_exit(NULL);
        return 3;
    }

    int r_res = libusb_control_transfer(dev,
        LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE,
        HID_SET_REPORT,
        (USB_HID_FEATURE_REPORT << 8) | RGB_REPORT_ID,
        0,
        p,
        sizeof(p),
        TRANSFER_TIMEOUT_MS);

    printf("Control transfer result: %d (expected %lu)\n", r_res, sizeof(p));
    libusb_release_interface(dev, 0);
    libusb_close(dev);
    libusb_exit(NULL);
    return (r_res == sizeof(p)) ? 0 : 4;
}
