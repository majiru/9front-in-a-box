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
	cpuFlag      = flag.String("cpu", "4", "number of cores for virtual machine")
	createFlag   = flag.String("create", "", "create a new 9front.qcow2 in the cwd")
	debugFlag    = flag.Bool("debug", false, "enable debug output")
	archFlag     = flag.String("arch", "amd64", "architechture of vm [amd64 arm64 386]")
	passwordFlag = flag.String("password", "password", "password of the glenda user")
	ubootFlag    = flag.String("uboot", "u-boot.bin", "uboot binary for arm64")
	qcowFlag     = flag.String("qcow", "", "location of .qcow2 file")
	qpathFlag    = flag.String("qpath", "", "location of qemu binaries")
	drawtermFlag = flag.String("dt", "drawterm", "drawterm binary")
)

// panics with error message
func validateFlags() {
	// NOTE other flags could be validated in future versions too
	if len(*passwordFlag) < 8 {
		fmt.Fprintln(os.Stderr, "password must be of lenght greater then seven characters.")
		os.Exit(1)
	}

	if *qcowFlag == "" {
		*qcowFlag = "./9front." + *archFlag + ".qcow2"
	}
}

func qemuCmd() []string {
	m := map[string][]string{
		"amd64": {
			filepath.Join(*qpathFlag, "qemu-system-x86_64"),
			// "-net",
			// "nic,model=virtio,macaddr=52:54:00:00:00:01",
			// "-net",
			// "bridge,br=br1",
			"-nic",
			"user,hostfwd=tcp::17019-:17019",
			"-enable-kvm",
			"-m",
			*ramFlag,
			"-smp",
			*cpuFlag,
			"-drive",
			"file=" + *qcowFlag + ",media=disk,if=virtio,index=0",
			"-nographic",
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
			"-drive",
			"file=" + *qcowFlag + ",if=none,id=disk",
			"-device",
			"virtio-blk-pci-non-transitional,drive=disk",
			"-nic",      
			"user,hostfwd=tcp::17019-:17019,model=virtio-net-pci-non-transitional",
			// "-net",
			// "nic,model=virtio-net-pci-non-transitional,macaddr=52:54:00:00:00:02",
			// "-net",
			// "bridge,br=br1",
			"-nographic",
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
			"-drive",
			"file=" + *qcowFlag + ",media=disk,if=virtio,index=0",
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
	validateFlags()

	if *createFlag != "" {
		err := exec.Command(filepath.Join(*qpathFlag, "qemu-img"), "create", "-f", "qcow2", "-F", "qcow2", "-o", "backing_file="+*createFlag, *qcowFlag).Run()
		if err != nil {
			log.Fatal(err)
		}
		os.Exit(0)
	}

	if _, err := os.Stat(*qcowFlag); err != nil {
		fmt.Fprintf(os.Stderr, "could not find %s\n", *qcowFlag)
		os.Exit(1)
	}

	cm := strings.Join(qemuCmd(), " ")
	if *debugFlag {
		fmt.Println(cm)
	}
	exp, _, err := expect.Spawn(cm, -1)
	if err != nil {
		log.Fatal(err)
	}
	defer exp.Close()

	exp.Options(expect.Tee(os.Stderr))
	if *debugFlag {
		exp.Options(expect.Tee(os.Stdout))
	}
	exp.Expect(regexp.MustCompile("bootargs is"), -1)
	exp.Send("\n")
	exp.Expect(regexp.MustCompile("user"), -1)
	exp.Send("\n")
	exp.Expect(regexp.MustCompile("%"), -1)
	exp.Send(`echo 'key proto=dp9ik dom=9front user=glenda !password=` + *passwordFlag + `' >/mnt/factotum/ctl` + "\n")
	exp.Expect(regexp.MustCompile("%"), -1)
	exp.Send("ip/ipconfig ether /net/ether0\n")
	exp.Expect(regexp.MustCompile("%"), -1)
	if *debugFlag {
		exp.Send("cat /net/ndb\n")
	}
	exp.Expect(regexp.MustCompile("%"), -1)
	exp.Send("aux/listen1 -t 'tcp!*!17019' /rc/bin/service/tcp17019 &\n")

	exitch := make(chan struct{})
	go func() {
		c := make(chan os.Signal, 1)
		signal.Notify(c, os.Interrupt)
		<-c
		exitch <- struct{}{}
	}()
	go func() {
		time.Sleep(2 * time.Second)
		exec.Command(*drawtermFlag, "-u", "glenda", "-h", "localhost", "-a", "localhost", "-c", "rc", "-c", "console=() service=terminal rc -l").Run()
		exitch <- struct{}{}
	}()
	<-exitch
	exp.Send("fshalt\n")
	exp.Expect(regexp.MustCompile("done halting"), -1)
	exp.Close()
}
