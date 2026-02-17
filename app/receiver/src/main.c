#include <zephyr/drivers/clock_control.h>
#include <zephyr/drivers/clock_control/nrf_clock_control.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/sys/util.h>
#include <hw_id.h>

LOG_MODULE_REGISTER(recv, CONFIG_RECV_LOG_LEVEL);

int initialize_clocks(void) {
	int err;
	int res;
	struct onoff_manager *clk_mgr;
	struct onoff_client clk_cli;

	clk_mgr = z_nrf_clock_control_get_onoff(CLOCK_CONTROL_NRF_SUBSYS_HF);
	if (!clk_mgr) {
		LOG_ERR("Unable to get the Clock manager");
		return -ENXIO;
	}

	sys_notify_init_spinwait(&clk_cli.notify);

	err = onoff_request(clk_mgr, &clk_cli);
	if (err < 0) {
		LOG_ERR("Clock request failed: %d", err);
		return err;
	}

	do {
		err = sys_notify_fetch_result(&clk_cli.notify, &res);
		if (!err && res) {
			LOG_ERR("Clock could not be started: %d", res);
			return res;
		}
	} while (err);

	LOG_DBG("HF clock started");
	return 0;
}

int main() {
	int err;
	err = initialize_clocks();
	if (err) {
		return err;
	}
	char buf[HW_ID_LEN];

	err = hw_id_get(buf, HW_ID_LEN);

	if (err) {
		LOG_ERR("hw_id_get failed: %d\n", err);
		return err;
	}

	while (1) {
		k_msleep(1000);
		LOG_INF("hw_id: %s\n", buf);
	}
	return 0;
}
