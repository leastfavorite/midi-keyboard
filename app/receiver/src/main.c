#include <zephyr/kernel.h>
#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/sys/printk.h>
#include <zephyr/sys/util.h>
#include <hw_id.h>

int main() {
	int err;
	err = bt_enable(NULL);
	if (err) {
		printk("FATAL: Bluetooth init failed (err %d)\n", err);
		return err;
	}
	char buf[HW_ID_LEN];
	err = hw_id_get(buf, HW_ID_LEN);
	bt_disable();

	if (err) {
		printk("FATAL: hw_id_get failed (err %d)\n", err);
		return err;
	}

	while (1) {
		k_msleep(1000);
		printk("hw_id: %s\n", buf);
	}
	return 0;
}
