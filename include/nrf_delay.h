#ifndef DELAY_H
#define DELAY_H

#include "nrfx_common.h"
#include "nrfx_coredep.h"

__STATIC_INLINE void nrf_delay_us(uint32_t us_time) {
    nrfx_coredep_delay_us(us_time);
}

__STATIC_INLINE void nrf_delay_ms(uint32_t ms_time) {
    for (; ms_time > 0; ms_time--) {
        nrf_delay_us(1000);
    }
}

#endif
