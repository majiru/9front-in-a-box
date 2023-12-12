package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"time"

	expect "github.com/google/goexpect"
)

var (
	ramFlag    = flag.String("m", "4G", "memory for qemu virtual machine")
	cpuFlag    = flag.String("cpu", "4", "number of cored for virtual machines")
	createFlag = flag.String("create", "", "create a new 9front.qcow2 in the cwd ")
	debugFlag  = flag.Bool("debug", false, "enable debug output")
	archFlag   = flag.String("arch", "amd64", "architechture of vm")
	ubootFlag  = flag.String("uboot", "u-boot.bin", "uboot binary for arm64")
)

func qemuCmd() []string {
	m := map[string][]string{
		"amd64": {
			"qemu-system-x86_64",
			"-nic",
			"user,hostfwd=tcp::17019-:17019",
			"-enable-kvm",
			"-m",
			*ramFlag,
			"-smp",
			*cpuFlag,
			"-drive",
			"file=9front.amd64.qcow2,media=disk,if=virtio,index=0",
			"-nographic",
		},
		"arm64": {
			"qemu-system-aarch64",
			"-M",
			"virt-2.12,gic-version=3",
			"-cpu",
			"cortex-a72",
			"-m",
			*ramFlag,
			"-smp",
			*cpuFlag,
			"-bios",
			*ubootFlag,
			"-drive",
			"file=9front.arm64.qcow2,if=none,id=disk",
			"-device",
			"virtio-blk-pci-non-transitional,drive=disk",
			"-nic",
			"user,hostfwd=tcp::17019-:17019,model=virtio-net-pci-non-transitional",
			"-nographic",
		},
	}
	r, ok := m[*archFlag]
	if !ok {
		log.Fatal("unsupported arch")
	}
	return r
}

func main() {
	flag.Parse()

	qcow := "9front." + *archFlag + ".qcow2"
	if *createFlag != "" {
		err := exec.Command("qemu-img", "create", "-f", "qcow2", "-F", "qcow2", "-o", "backing_file="+*createFlag, qcow).Run()
		if err != nil {
			log.Fatal(err)
		}
		os.Exit(0)
	}
	if _, err := os.Stat(qcow); err != nil {
		fmt.Fprintf(os.Stderr, "could not find %s\n", qcow)
		os.Exit(1)
	}

	cm := strings.Join(qemuCmd(), " ")
	if *debugFlag {
		fmt.Println(cm)
	}
	e, _, err := expect.Spawn(cm, -1)
	if err != nil {
		log.Fatal(err)
	}
	defer e.Close()

	if *debugFlag {
		e.Options(expect.Tee(os.Stdout))
	}
	e.Expect(regexp.MustCompile("bootargs is"), -1)
	e.Send("\n")
	e.Expect(regexp.MustCompile("user"), -1)
	e.Send("\n")
	e.Expect(regexp.MustCompile("%"), -1)
	e.Send(`echo 'key proto=dp9ik dom=9front user=glenda !password=password' >/mnt/factotum/ctl` + "\n")
	e.Expect(regexp.MustCompile("%"), -1)
	e.Send("ip/ipconfig ether /net/ether0\n")
	e.Expect(regexp.MustCompile("%"), -1)
	e.Send("aux/listen1 -t 'tcp!*!17019' /rc/bin/service/tcp17019 &\n")
	time.Sleep(2 * time.Second)
	exec.Command("drawterm", "-u", "glenda", "-h", "localhost", "-a", "localhost", "-c", "rio").Run()
	e.Send("fshalt\n")
	e.Expect(regexp.MustCompile("done halting"), -1)
}
