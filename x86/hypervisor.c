#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <Hypervisor/hv.h>
#include <Hypervisor/hv_vmx.h>

uint64_t read_register(hv_vcpuid_t, hv_x86_reg_t);
void write_register(hv_vcpuid_t, hv_x86_reg_t, uint64_t);

uint64_t read_cs(hv_vcpuid_t, uint32_t);
void write_cs(hv_vcpuid_t, uint32_t, uint64_t);

void dump_registers(hv_vcpuid_t);
void dump_vga(char*);

char* hv_return_string(hv_return_t rc) {
    switch (rc) {
    case HV_ERROR: return "error";
    case HV_BUSY: return "busy";
    case HV_BAD_ARGUMENT: return "bad arg";
    case HV_NO_RESOURCES: return "no resource";
    case HV_NO_DEVICE: return "no device";
    case HV_UNSUPPORTED: return "unsupported";
    default: return "?";
    }
}

#define CHECK(x) \
    do { \
        hv_return_t rc = x; \
        if (rc != HV_SUCCESS) { \
            printf("%s when %s\n", hv_return_string(rc), #x); \
            abort(); \
        } \
    } \
    while (0)

#define MEM_SIZE 2 * 1024 * 1024
#define MEM_LOC  0x0000

int main(void) {
    CHECK(hv_vm_create(HV_VM_DEFAULT));

    char* mem = valloc(MEM_SIZE);
    CHECK(hv_vm_map(mem, MEM_LOC, MEM_SIZE, HV_MEMORY_READ | HV_MEMORY_WRITE | HV_MEMORY_EXEC));

    hv_vcpuid_t vcpu;
    CHECK(hv_vcpu_create(&vcpu, HV_VCPU_DEFAULT));
    printf("created cpu %d\n", vcpu);

    uint64_t vmx_cap_pinbased, vmx_cap_procbased, vmx_cap_procbased2, vmx_cap_entry;
    CHECK(hv_vmx_read_capability(HV_VMX_CAP_PINBASED, &vmx_cap_pinbased));
    CHECK(hv_vmx_read_capability(HV_VMX_CAP_PROCBASED, &vmx_cap_procbased));
    CHECK(hv_vmx_read_capability(HV_VMX_CAP_PROCBASED2, &vmx_cap_procbased2));
    CHECK(hv_vmx_read_capability(HV_VMX_CAP_ENTRY, &vmx_cap_entry));

#define VMCS_CTRL(r, v) \
    write_cs(vcpu, VMCS_CTRL_##r, v);
    VMCS_CTRL(PIN_BASED, vmx_cap_pinbased);
    VMCS_CTRL(CPU_BASED, vmx_cap_procbased | CPU_BASED_HLT | CPU_BASED_CR8_LOAD | CPU_BASED_CR8_STORE);
    VMCS_CTRL(EXC_BITMAP, 0xffffffff);
    VMCS_CTRL(CR0_MASK, 0x60000000);
    VMCS_CTRL(CR0_SHADOW, 0);
    VMCS_CTRL(CR4_MASK, 0);
    VMCS_CTRL(CR4_SHADOW, 0);
#undef VMCS_CTRL

#define VMCS_GUEST(r, v, b, l, ar) \
    write_cs(vcpu, VMCS_GUEST_##r, v); \
    write_cs(vcpu, VMCS_GUEST_##r##_LIMIT, l); \
    write_cs(vcpu, VMCS_GUEST_##r##_AR, ar); \
    write_cs(vcpu, VMCS_GUEST_##r##_BASE, b);
    VMCS_GUEST(CS, 0, 0, 0xffff, 0x9b);
    VMCS_GUEST(DS, 0, 0, 0xffff, 0x93);
    VMCS_GUEST(ES, 0, 0, 0xffff, 0x93);
    VMCS_GUEST(FS, 0, 0, 0xffff, 0x93);
    VMCS_GUEST(GS, 0, 0, 0xffff, 0x93);
    VMCS_GUEST(SS, 0, 0, 0xffff, 0x93);
    VMCS_GUEST(TR, 0, 0,      0, 0x83);
    VMCS_GUEST(LDTR, 0, 0, 0, 0x10000);
#undef VMCS_GUEST

#define VMCS_GUEST(r, b, l) \
    write_cs(vcpu, VMCS_GUEST_##r##_LIMIT, l); \
    write_cs(vcpu, VMCS_GUEST_##r##_BASE, b);
    VMCS_GUEST(GDTR, 0, 0);
    VMCS_GUEST(IDTR, 0, 0);
#undef VMCS_GUEST

#define VMCS_GUEST(r, v) \
    write_cs(vcpu, VMCS_GUEST_##r, v);
    VMCS_GUEST(CR0, 0x20);
    VMCS_GUEST(CR3, 0x00);
    VMCS_GUEST(CR4, 0x2000);
    //VMCS_GUEST(ACTIVITY_STATE, 0x00);
    //VMCS_GUEST(DEBUG_EXC, 0x00);
    //VMCS_GUEST(DR7, 0x00);
    //VMCS_GUEST(IA32_BNDCFGS, 0x00);
    //VMCS_GUEST(IA32_DEBUGCTL, 0x00);
    //VMCS_GUEST(IA32_EFER, 0x00);
    //VMCS_GUEST(IA32_PAT, 0x00);
    //VMCS_GUEST(IA32_PERF_GLOBAL_CTRL, 0x00);
    //VMCS_GUEST(IA32_SYSENTER_CS, 0x00);
    //VMCS_GUEST(IGNORE_IRQ, 0x00);
    //VMCS_GUEST(INT_STATUS, 0x00);
    //VMCS_GUEST(LINK_POINTER, 0x00);
    //VMCS_GUEST(PDPTE0, 0x00);
    //VMCS_GUEST(PDPTE1, 0x00);
    //VMCS_GUEST(PDPTE2, 0x00);
    //VMCS_GUEST(PDPTE3, 0x00);
    //VMCS_GUEST(PHYSICAL_ADDRESS, 0x00);
    //VMCS_GUEST(RFLAGS, 0x00);
    //VMCS_GUEST(RIP, 0x00);
    //VMCS_GUEST(RSP, 0x00);
    //VMCS_GUEST(SMBASE, 0x00);
    //VMCS_GUEST(SYSENTER_EIP, 0x00);
    //VMCS_GUEST(SYSENTER_ESP, 0x00);
    //VMCS_GUEST(VMX_TIMER_VALUE, 0x00);
#undef VMCS_GUEST

    FILE *f = fopen("boot.img", "r");
    fread((char *)mem + 0x7c00, 1, 16 * 1024, f);
    fclose(f);

    write_register(vcpu, HV_X86_RIP, 0x7c00);
    write_register(vcpu, HV_X86_RFLAGS, 0x2);
    write_register(vcpu, HV_X86_RSP, 0x0);

    bool stop = false;
    for (;;) {
        //dump_registers(vcpu);
        CHECK(hv_vcpu_run(vcpu));

        uint64_t exit_reason = read_cs(vcpu, VMCS_RO_EXIT_REASON);
        switch (exit_reason) {
        case VMX_REASON_EXC_NMI: {
            uint8_t interrupt_number = read_cs(vcpu, VMCS_RO_IDT_VECTOR_INFO) & 0xFF;
            switch (interrupt_number) {
            case 0x10: {
                uint8_t c = read_register(vcpu, HV_X86_RAX) & 0xFF;
                printf("                                                                                        ");
                printf("%c |\n", c);
                break;
            }
            case 0x13: {
                printf("disk load\n");
                memcpy(mem + 0x12000, mem + 0x7c00 + 512, 5 * 1024);
                break;
            }
            default: {
                printf("INT %x\n", interrupt_number);
                dump_registers(vcpu);
            }
            }
            write_register(vcpu, HV_X86_RIP, read_register(vcpu, HV_X86_RIP) + 2);
            break;
        }
        case VMX_REASON_IRQ:
            printf("IRQ\n");
            break;
        case VMX_REASON_EPT_VIOLATION:
            printf("EPT_VIOLATION\n");
            break;
        case VMX_REASON_HLT:
            printf("HLT\n");
            stop = true;
            break;
        case VMX_REASON_IO:
            dump_registers(vcpu);
            printf("IO\n");
            write_register(vcpu, HV_X86_RIP, read_register(vcpu, HV_X86_RIP) + 2);
            break;
        default:
            printf("exit reason: %lld\n", exit_reason);
            stop = true;
            break;
        }

        // uint64_t exec_time;
        // CHECK(hv_vcpu_get_exec_time(vcpu, &exec_time));
        // printf("ran for %llu ns\n", exec_time);

        if (stop) {
            dump_registers(vcpu);
            dump_vga(mem + 0xb8000);
            break;
        }
    }

    CHECK(hv_vcpu_destroy(vcpu));
    CHECK(hv_vm_unmap(MEM_LOC, MEM_SIZE));
    free(mem);
    CHECK(hv_vm_destroy());
}

void dump_vga(char* vga) {
    for (int i = 0; i < 80 * 40 * 2; i += 2) {
        if (vga[i]) {
            printf("%c", vga[i]);
        }
    }
    printf("\n");
}

void dump_registers(hv_vcpuid_t vcpu_id) {
    printf("/-----------------------------------------------------------------------------------------\\\n");
    printf("| rip: %16llx rfl: %16llx                                             |\n",
        read_register(vcpu_id, HV_X86_RIP),
        read_register(vcpu_id, HV_X86_RFLAGS)
    );
    printf("| rsi: %16llx rdi: %16llx rsp: %16llx rbp: %16llx |\n",
        read_register(vcpu_id, HV_X86_RSI),
        read_register(vcpu_id, HV_X86_RDI),
        read_register(vcpu_id, HV_X86_RSP),
        read_register(vcpu_id, HV_X86_RBP)
    );
    printf("| rax: %16llx rbx: %16llx rcx: %16llx rdx: %16llx |\n",
        read_register(vcpu_id, HV_X86_RAX),
        read_register(vcpu_id, HV_X86_RBX),
        read_register(vcpu_id, HV_X86_RCX),
        read_register(vcpu_id, HV_X86_RDX)
    );
    printf("|  r8: %16llx  r9: %16llx r10: %16llx r11: %16llx |\n",
        read_register(vcpu_id, HV_X86_R8),
        read_register(vcpu_id, HV_X86_R9),
        read_register(vcpu_id, HV_X86_R10),
        read_register(vcpu_id, HV_X86_R11)
    );
    printf("| r12: %16llx r13: %16llx r14: %16llx r15: %16llx |\n",
        read_register(vcpu_id, HV_X86_R12),
        read_register(vcpu_id, HV_X86_R13),
        read_register(vcpu_id, HV_X86_R14),
        read_register(vcpu_id, HV_X86_R15)
    );
    printf("|  cs: %16llx  ds: %16llx  es: %16llx  fs: %16llx |\n",
        read_register(vcpu_id, HV_X86_CS),
        read_register(vcpu_id, HV_X86_DS),
        read_register(vcpu_id, HV_X86_ES),
        read_register(vcpu_id, HV_X86_FS)
    );
    printf("|  gs: %16llx  ss: %16llx                                             |\n",
        read_register(vcpu_id, HV_X86_GS),
        read_register(vcpu_id, HV_X86_SS)
    );
    printf("| cr0: %16llx cr1: %16llx cr2: %16llx cr3: %16llx |\n",
        read_register(vcpu_id, HV_X86_CR0),
        read_register(vcpu_id, HV_X86_CR1),
        read_register(vcpu_id, HV_X86_CR2),
        read_register(vcpu_id, HV_X86_CR3)
    );
    printf("| dr0: %16llx dr1: %16llx dr2: %16llx dr3: %16llx |\n",
        read_register(vcpu_id, HV_X86_DR0),
        read_register(vcpu_id, HV_X86_DR1),
        read_register(vcpu_id, HV_X86_DR2),
        read_register(vcpu_id, HV_X86_DR3)
    );
    printf("| dr4: %16llx dr5: %16llx dr6: %16llx dr7: %16llx |\n",
        read_register(vcpu_id, HV_X86_DR4),
        read_register(vcpu_id, HV_X86_DR5),
        read_register(vcpu_id, HV_X86_DR6),
        read_register(vcpu_id, HV_X86_DR7)
    );
    printf("| idt: %16llx idt: %16llx gdt: %16llx gdt: %16llx |\n",
        read_register(vcpu_id, HV_X86_IDT_BASE),
        read_register(vcpu_id, HV_X86_IDT_LIMIT),
        read_register(vcpu_id, HV_X86_GDT_BASE),
        read_register(vcpu_id, HV_X86_GDT_LIMIT)
    );
    /*
    HV_X86_LDTR HV_X86_LDT_BASE HV_X86_LDT_LIMIT HV_X86_LDT_AR
    HV_X86_TR HV_X86_TSS_BASE HV_X86_TSS_LIMIT HV_X86_TSS_AR
    HV_X86_CR4 HV_X86_TPR HV_X86_XCR0
    */
    printf("\\-----------------------------------------------------------------------------------------/\n");
}

uint64_t read_register(hv_vcpuid_t vcpu_id, hv_x86_reg_t reg) {
    uint64_t value;
    CHECK(hv_vcpu_read_register(vcpu_id, reg, &value));
    return value;
}

void write_register(hv_vcpuid_t vcpu_id, hv_x86_reg_t reg, uint64_t value) {
    CHECK(hv_vcpu_write_register(vcpu_id, reg, value));
}

uint64_t read_cs(hv_vcpuid_t vcpu_id, uint32_t cs) {
    uint64_t value;
    CHECK(hv_vmx_vcpu_read_vmcs(vcpu_id, cs, &value));
    return value;
}

void write_cs(hv_vcpuid_t vcpu_id, uint32_t cs, uint64_t value) {
    CHECK(hv_vmx_vcpu_write_vmcs(vcpu_id, cs, value));
}
