# wireless midi keyboard

## usage
after cloning this repo, run `init.sh` to initialize west in a virtual environment.

building and installing is dependent on your target hardware--for my use case, i'm
programming the [raytac mdbt50q-db-40](https://www.raytac.com/product/ins.php?index_id=81)
thru a [flirc jeff probe](https://flirc.tv/products/flirc-jeffprobe?variant=43085036585192).

you'll need to generate a private key to sign built images:
```sh
mkdir secrets
openssl ecparam -name prime256v1 -genkey -noout -out secrets/priv.pem
```

then, enable the black magic runner for this chip:
```sh
echo 'include(${ZEPHYR_BASE}/boards/common/blackmagicprobe.board.cmake)' >> deps/zephyr/boards/raytac/mdbt50q_db_40/board.cmake
```

additionally, the zephyr sdk's arm-zephyr-gdb is bugged, so we install via homebrew:
```sh
export ZEPHYR_TOOLCHAIN_VARIANT="cross-compile"
export CROSS_COMPILE="/opt/homebrew/arm-none-eabi"
```

then we can build:
```sh
west build -p always -b raytaq_mdbt50q_db_40 app
west flash --runner blackmagicprobe
```
