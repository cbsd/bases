# bases

Build FreeBSD bases for CBSD infrastructure, for CI/cron purposes.

./loop.sh -a amd64 -t amd64 -v 14.0
./loop.sh -a arm64 -t aarch64 -v 14.0
./loop.sh -a riscv -t riscv64 -v 14.0

# for upload:

For upload put valid ssh key into .ssh dir.
See config.conf ( there is no other infrastructure than @olevole resources. )

