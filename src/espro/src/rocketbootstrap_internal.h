#import <CoreFoundation/CoreFoundation.h>

#import "rocketbootstrap.h"

#include "bootstrap_priv.h"

static inline bool rocketbootstrap_is_passthrough(void)
{
	return kCFCoreFoundationVersionNumber < 800.0;
}

kern_return_t rocketbootstrap_look_up3(mach_port_t bp, const name_t service_name, mach_port_t *sp, pid_t target_pid, const uuid_t instance_id, uint64_t flags);
