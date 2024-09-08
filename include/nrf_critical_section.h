#ifndef NRF_CRITICAL_SECTION_H__
#define NRF_CRITICAL_SECTION_H__

#include <nrf.h>
#include <nrfx.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void nrf_critical_section_enter (uint8_t *p_nested);
void nrf_critical_section_exit (uint8_t nested);
bool nrf_is_privileged();

#ifdef __cplusplus
}
#endif

#endif // NRF_CRITICAL_SECTION_H__
