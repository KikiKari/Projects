#include "tlc_peak_limiter.h"
#include <stdio.h>

/* Binary stdin/stdout runner used by the JS/native equivalence test. */
int main(int argc, char **argv) {
    if (argc != 5) return 2;
    unsigned rate = (unsigned)atoi(argv[1]), channels = (unsigned)atoi(argv[2]);
    int enabled = atoi(argv[3]); double strength = atof(argv[4]);
    tlc_peak_limiter *p = tlc_peak_create(rate, channels);
    if (!p) return 3;
    float input[128 * 8], output[128 * 8];
    size_t count;
    while ((count = fread(input, sizeof(float), 128 * channels, stdin)) > 0) {
        if (count % channels) return 4;
        tlc_peak_process(p, input, output, (unsigned)(count / channels), enabled, strength);
        if (fwrite(output, sizeof(float), count, stdout) != count) return 5;
    }
    tlc_peak_destroy(p);
    return ferror(stdin) ? 6 : 0;
}
