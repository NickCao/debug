import sys
from pathlib import Path

from opendal import Operator

from jumpstarter_testing.pytest import JumpstarterTest


class TestQemu(JumpstarterTest):
    def test_driver_qemu(tmp_path, ovmf, client):
        arch = "x86_64"

        qemu = client

        cached_image = (
            Path(__file__).parent.parent
            / "images"
            / f"Fedora-Cloud-Base-Generic-41-1.4.{arch}.qcow2"
        )

        if cached_image.exists():
            qemu.flasher.flash(cached_image.resolve())
        else:
            qemu.flasher.flash(
                f"pub/fedora/linux/releases/41/Cloud/{arch}/images/Fedora-Cloud-Base-Generic-41-1.4.{arch}.qcow2",
                operator=Operator(
                    "http", endpoint="https://download.fedoraproject.org"
                ),
            )

        qemu.power.on()

        with qemu.novnc() as _:
            pass

        with qemu.console.pexpect() as p:
            p.logfile = sys.stdout.buffer
            p.expect_exact("login:", timeout=600)
            p.sendline("jumpstarter")
            p.expect_exact("Password:")
            p.sendline("password")
            p.expect_exact(" ~]$")
            p.sendline("sudo setenforce 0")
            p.expect_exact(" ~]$")

        with qemu.shell() as s:
            assert s.run("uname -r").stdout.strip() == f"6.11.4-301.fc41.{arch}"

        qemu.power.off()
