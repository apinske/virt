#include <fcntl.h>
#include <linux/kvm.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

uint64_t read_register(int vcpu, uint64_t id);
void write_register(int vcpu, uint64_t id, uint64_t value);

void dump_registers(int vcpu);

#define CHECK(x) \
    do { \
        int rc = x; \
        if (rc < 0) { \
            perror(#x); \
	    exit(1); \
        } \
    } \
    while (0)


#define MEM_SIZE 2 * 1024 * 1024
#define MEM_LOC  0x0000

int main() {
    int kvm = open("/dev/kvm", O_RDWR | O_CLOEXEC);
    CHECK(kvm);
    int vm = ioctl(kvm, KVM_CREATE_VM, 0);
    CHECK(vm);

    char* mem = valloc(MEM_SIZE);
    struct kvm_userspace_memory_region region;
    region.flags = 0;
    region.slot = 0;
    region.guest_phys_addr = MEM_LOC;
    region.memory_size = MEM_SIZE;
    region.userspace_addr = (uint64_t) mem;
    CHECK(ioctl(vm, KVM_SET_USER_MEMORY_REGION, &region));

    struct kvm_vcpu_init init;
    CHECK(ioctl(vm, KVM_ARM_PREFERRED_TARGET, &init));

    int vcpu = ioctl(vm, KVM_CREATE_VCPU, 0);
    CHECK(vcpu);
    CHECK(ioctl(vcpu, KVM_ARM_VCPU_INIT, &init));
    //CHECK(ioctl(vcpu, KVM_ARM_VCPU_FINALIZE, KVM_ARM_VCPU_SVE));

    struct kvm_run *run = mmap(NULL, sizeof(struct kvm_run), PROT_READ | PROT_WRITE, MAP_SHARED, vcpu, 0);

    write_register(vcpu, 0x6030000000100040, 0xAA);
    dump_registers(vcpu);

    //mem[0] = 1;

    int stop = 0;
    for (;;) {
	//run->immediate_exit = 1;
	//run->request_interrupt_window = 1;
	//struct kvm_vcpu_event events;
	//ioctl(vcpu, KVM_GET_VCPU_EVENTS, &events);

	CHECK(ioctl(vcpu, KVM_RUN, NULL));
	switch (run->exit_reason) {
	case KVM_EXIT_HLT:
	    printf("HLT\n");
	    stop = 1;
	case KVM_EXIT_UNKNOWN:
	default:
	    printf("exit %d (%d)\n", run->exit_reason, run->hw.hardware_exit_reason);
	    stop = 1;
	}
	if (stop) {
	    break;
	}
    }

    dump_registers(vcpu);

    printf("%x", mem[100]);

    close(vcpu);
    close(vm);
    close(kvm);
    free(mem);
    return 0;
}

uint64_t read_register(int vcpu, uint64_t id) {
    uint64_t value;
    struct kvm_one_reg reg;
    reg.id = id;
    reg.addr = (uint64_t) &value;
    CHECK(ioctl(vcpu, KVM_GET_ONE_REG, &reg));
    return value;
}

void write_register(int vcpu, uint64_t id, uint64_t v) {
    uint64_t value = v;
    struct kvm_one_reg reg;
    reg.id = id;
    reg.addr = (uint64_t) &value;
    CHECK(ioctl(vcpu, KVM_SET_ONE_REG, &reg));
}

void dump_registers(int vcpu) {
    printf("x00: %16llx x01: %16llx x02: %16llx x03: %16llx\n",
        read_register(vcpu, 0x6030000000100000),
        read_register(vcpu, 0x6030000000100002),
        read_register(vcpu, 0x6030000000100004),
        read_register(vcpu, 0x6030000000100006)
    );
    printf("x04: %16llx x05: %16llx x06: %16llx x07: %16llx\n",
        read_register(vcpu, 0x6030000000100008),
        read_register(vcpu, 0x603000000010000a),
        read_register(vcpu, 0x603000000010000c),
        read_register(vcpu, 0x603000000010000e)
    );
    printf("x08: %16llx x09: %16llx x10: %16llx x11: %16llx\n",
        read_register(vcpu, 0x6030000000100010),
        read_register(vcpu, 0x6030000000100012),
        read_register(vcpu, 0x6030000000100014),
        read_register(vcpu, 0x6030000000100016)
    );
    printf("x12: %16llx x13: %16llx x14: %16llx x15: %16llx\n",
        read_register(vcpu, 0x6030000000100018),
        read_register(vcpu, 0x603000000010001a),
        read_register(vcpu, 0x603000000010001c),
        read_register(vcpu, 0x603000000010001e)
    );
    printf("x16: %16llx x17: %16llx x18: %16llx x19: %16llx\n",
        read_register(vcpu, 0x6030000000100020),
        read_register(vcpu, 0x6030000000100022),
        read_register(vcpu, 0x6030000000100024),
        read_register(vcpu, 0x6030000000100026)
    );
    printf("x20: %16llx x21: %16llx x22: %16llx x23: %16llx\n",
        read_register(vcpu, 0x6030000000100028),
        read_register(vcpu, 0x603000000010002a),
        read_register(vcpu, 0x603000000010002c),
        read_register(vcpu, 0x603000000010002e)
    );
    printf("x24: %16llx x25: %16llx x26: %16llx x27: %16llx\n",
        read_register(vcpu, 0x6030000000100030),
        read_register(vcpu, 0x6030000000100032),
        read_register(vcpu, 0x6030000000100034),
        read_register(vcpu, 0x6030000000100036)
    );
    printf("x28: %16llx x29: %16llx x30: %16llx\n",
        read_register(vcpu, 0x6030000000100038),
        read_register(vcpu, 0x603000000010003a),
        read_register(vcpu, 0x603000000010003c)
    );
    printf(" sp: %16llx  pc: %16llx\n",
        read_register(vcpu, 0x603000000010003e),
        read_register(vcpu, 0x6030000000100040)
    );
}
