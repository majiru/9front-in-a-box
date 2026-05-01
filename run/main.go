package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	expect "github.com/google/goexpect"
)

var (
	ramFlag      = flag.String("m", "4G", "memory for qemu virtual machine")
	cpuFlag      = flag.String("cpu", "4", "number of cored for virtual machines")
	debugFlag    = flag.Bool("debug", false, "enable debug output")
	archFlag     = flag.String("arch", "amd64", "architechture of vm")
	diskFlag     = flag.String("disk", "", "qcow2 vm disk")
	ubootFlag    = flag.String("uboot", "u-boot.bin", "uboot binary for arm64")
	qpathFlag    = flag.String("qpath", "", "location of qemu binaries")
	drawtermFlag = flag.String("dt", "drawterm", "drawterm binary")
	noguiFlag    = flag.Bool("nogui", false, "disable the GUI")
)

func qemuCmd(qcow string) []string {
	m := map[string][]string{
		"amd64": {
			filepath.Join(*qpathFlag, "qemu-system-x86_64"),
			"-nic",
			"user,hostfwd=tcp::17019-:17019",
			"-enable-kvm",
			"-m",
			*ramFlag,
			"-smp",
			*cpuFlag,
			"-nographic",
			"-drive",
			"media=disk,if=virtio,index=0",
		},
		"arm64": {
			filepath.Join(*qpathFlag, "qemu-system-aarch64"),
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
			"-device",
			"virtio-blk-pci-non-transitional,drive=disk",
			"-nic",
			"user,hostfwd=tcp::17019-:17019,model=virtio-net-pci-non-transitional",
			"-nographic",
			"-drive",
			"if=none,id=disk",
		},
		"386": {
			filepath.Join(*qpathFlag, "qemu-system-x86_64"),
			"-nic",
			"user,hostfwd=tcp::17019-:17019",
			"-enable-kvm",
			"-m",
			*ramFlag,
			"-smp",
			*cpuFlag,
			"-nographic",
			"-drive",
			"media=disk,if=virtio,index=0",
		},
	}
	r, ok := m[*archFlag]
	if !ok {
		log.Fatal("unsupported arch")
	}
	r[len(r)-1] = r[len(r)-1] + ",file=" + qcow
	return r
}

func main() {
	flag.Parse()

	var qcow string
	if *diskFlag == "" {
		qcow = "9front." + *archFlag + ".qcow2"
	} else {
		qcow = *diskFlag
	}
	if _, err := os.Stat(qcow); err != nil {
		fmt.Fprintf(os.Stderr, "could not find %s\n", qcow)
		os.Exit(1)
	}

	cm := strings.Join(qemuCmd(qcow), " ")
	if *debugFlag {
		fmt.Println(cm)
	}
	exp, _, err := expect.Spawn(cm, -1)
	if err != nil {
		log.Fatal(err)
	}
	defer exp.Close()

	if *debugFlag {
		exp.Options(expect.Tee(os.Stdout))
	}
	exp.Expect(regexp.MustCompile("bootargs is"), -1)
	exp.Send("\n")
	exp.Expect(regexp.MustCompile("user"), -1)
	exp.Send("\n")
	exp.Expect(regexp.MustCompile("%"), -1)
	exp.Send(`echo 'key proto=dp9ik dom=9front user=glenda !password=password' >/mnt/factotum/ctl` + "\n")
	exp.Expect(regexp.MustCompile("%"), -1)
	exp.Send("ip/ipconfig -6 ether /net/ether0\n")
	exp.Expect(regexp.MustCompile("%"), -1)
	exp.Send("ip/ipconfig ether /net/ether0\n")
	exp.Expect(regexp.MustCompile("%"), -1)
	exp.Send("ip/ipconfig ether /net/ether0 ra6 recvra 1\n")
	exp.Expect(regexp.MustCompile("%"), -1)
	exp.Send("aux/listen1 -t 'tcp!*!17019' /rc/bin/service/tcp17019 &\n")
	exp.Expect(regexp.MustCompile("listen started"), -1)

	exitch := make(chan struct{})
	go func() {
		c := make(chan os.Signal, 1)
		signal.Notify(c, os.Interrupt)
		<-c
		exitch <- struct{}{}
	}()
	go func() {
		time.Sleep(2 * time.Second)
		if *noguiFlag {
			cmd := exec.Command(*drawtermFlag, "-G", "-r", ".", "-u", "glenda", "-h", "127.0.0.1", "-a", "127.0.0.1", "-c", "service=cpu rc -lI")
			cmd.Env = append(cmd.Environ(), "PASS=password")
			cmd.Stdin = os.Stdin
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			err := cmd.Run()
			if err != nil {
				log.Println(err)
			}
		} else {
			exec.Command(*drawtermFlag, "-u", "glenda", "-h", "127.0.0.1", "-a", "127.0.0.1", "-c", "rc", "-c", "console=() service=terminal rc -l").Run()
		}
		exitch <- struct{}{}
	}()
	<-exitch
	exp.Send("fshalt\n")
	exp.Expect(regexp.MustCompile("done halting"), -1)
	exp.Close()
}
