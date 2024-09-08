#include "nrf_critical_section.h"

static uint32_t m_in_critical_section = 0;

void nrf_disable_irq(void)
{
    __disable_irq();
    m_in_critical_section++;
}

void nrf_enable_irq(void)
{
    m_in_critical_section--;
    if (m_in_critical_section == 0)
    {
        __enable_irq();
    }
}

void nrf_critical_section_enter(uint8_t *p_nested)
{
#if __CORTEX_M == (0x04U)
    NRFX_ASSERT(nrf_is_privileged())
#endif

#if defined(SOFTDEVICE_PRESENT)
    /* return value can be safely ignored */
    (void) sd_nvic_critical_section_enter(p_nested);
#else
    nrf_disable_irq();
#endif
}

void nrf_critical_section_exit(uint8_t nested)
{
#if __CORTEX_M == (0x04U)
    NRFX_ASSERT(nrf_is_privileged())
#endif

#if defined(SOFTDEVICE_PRESENT)
    /* return value can be safely ignored */
    (void) sd_nvic_critical_section_exit(nested);
#else
    nrf_enable_irq();
#endif
}

bool nrf_is_privileged(void)
{
#if __CORTEX_M == (0x00U) || defined(_WIN32) || defined(__unix) || defined(__APPLE__)
    /* the Cortex-M0 has no concept of privilege */
    return true;
#elif __CORTEX_M >= (0x04U)
    uint32_t isr_vector_num = __get_IPSR() & IPSR_ISR_Msk ;
    if (0 == isr_vector_num)
    {
        /* Thread Mode, check nPRIV */
        int32_t control = __get_CONTROL();
        return !(control & CONTROL_nPRIV_Msk);
    }
    else
    {
        /* Handler Mode, always privileged */
        return true;
    }
#endif
}
