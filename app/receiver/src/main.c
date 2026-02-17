#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>
#include <zephyr/sys/util.h>
#include <hw_id.h>

int main() {
	int err;
	char buf[HW_ID_LEN];

	err = hw_id_get(buf, HW_ID_LEN);

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
