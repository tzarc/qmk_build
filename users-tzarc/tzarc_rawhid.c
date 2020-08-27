#include <quantum.h>
#include <raw_hid.h>
#include "tzarc.h"

#if defined(RAW_ENABLE) && !defined(VIA_ENABLE)

void raw_hid_receive(uint8_t *data, uint8_t length) {
    // Loopback for now.
    raw_hid_send((uint8_t *)&tzarc_eeprom_cfg, TZARC_EEPROM_ALLOCATION);
}

#endif