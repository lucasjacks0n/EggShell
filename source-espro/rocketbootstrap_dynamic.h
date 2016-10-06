// DONT INCLUDE DIRECTLY
// Set ROCKETBOOTSTRAP_LOAD_DYNAMIC and then include rocketbootstrap.h
#include <dlfcn.h>

__attribute__((unused))
static kern_return_t rocketbootstrap_look_up(mach_port_t bp, const name_t service_name, mach_port_t *sp)
{
	static kern_return_t (*impl)(mach_port_t bp, const name_t service_name, mach_port_t *sp);
	if (!impl) {
		void *handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
		if (handle)
			impl = (kern_return_t (*)(mach_port_t, const name_t, mach_port_t *))dlsym(handle, "rocketbootstrap_look_up");
		if (!impl)
			impl = bootstrap_look_up;
	}
	return impl(bp, service_name, sp);
}

__attribute__((unused))
static kern_return_t rocketbootstrap_unlock(const name_t service_name)
{
	static kern_return_t (*impl)(const name_t service_name);
	if (!impl) {
		void *handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
		if (handle)
			impl = (kern_return_t (*)(const name_t))dlsym(handle, "rocketbootstrap_unlock");
		if (!impl)
			return -1;
	}
	return impl(service_name);
}

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
__attribute__((unused))
static kern_return_t rocketbootstrap_register(mach_port_t bp, name_t service_name, mach_port_t sp)
{
	static kern_return_t (*impl)(mach_port_t bp, name_t service_name, mach_port_t sp);
	if (!impl) {
		void *handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
		if (handle)
			impl = (kern_return_t (*)(mach_port_t, name_t, mach_port_t))dlsym(handle, "rocketbootstrap_register");
		if (!impl)
			impl = bootstrap_register;
	}
	return impl(bp, service_name, sp);
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"

#ifdef XPC_API_VERSION
kern_return_t rocketbootstrap_xpc_connection_apply(xpc_connection_t connection)
{
	static kern_return_t (*impl)(xpc_connection_t connection);
	if (!impl) {
		void *handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
		if (handle)
			impl = (kern_return_t (*)(xpc_connection_t))dlsym(handle, "rocketbootstrap_xpc_connection_apply");
		if (!impl)
			return -1;
	}
	return impl(connection);
}

kern_return_t rocketbootstrap_xpc_unlock(xpc_connection_t listener)
{
	static kern_return_t (*impl)(xpc_connection_t listener);
	if (!impl) {
		void *handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
		if (handle)
			impl = (kern_return_t (*)(xpc_connection_t))dlsym(handle, "rocketbootstrap_xpc_unlock");
		if (!impl)
			return -1;
	}
	return impl(listener);
}
#endif

#ifdef __COREFOUNDATION_CFMESSAGEPORT__
__attribute__((unused))
static CFMessagePortRef rocketbootstrap_cfmessageportcreateremote(CFAllocatorRef allocator, CFStringRef name)
{
	static CFMessagePortRef (*impl)(CFAllocatorRef allocator, CFStringRef name);
	if (!impl) {
		void *handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
		if (handle)
			impl = (CFMessagePortRef (*)(CFAllocatorRef, CFStringRef))dlsym(handle, "rocketbootstrap_cfmessageportcreateremote");
		if (!impl)
			impl = CFMessagePortCreateRemote;
	}
	return impl(allocator, name);
}
__attribute__((unused))
static kern_return_t rocketbootstrap_cfmessageportexposelocal(CFMessagePortRef messagePort)
{
	static kern_return_t (*impl)(CFMessagePortRef messagePort);
	if (!impl) {
		void *handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
		if (handle)
			impl = (kern_return_t (*)(CFMessagePortRef))dlsym(handle, "rocketbootstrap_cfmessageportexposelocal");
		if (!impl)
			return -1;
	}
	return impl(messagePort);
}
#endif

#ifdef __OBJC__
@class CPDistributedMessagingCenter;
__attribute__((unused))
static void rocketbootstrap_distributedmessagingcenter_apply(CPDistributedMessagingCenter *messaging_center)
{
	static void (*impl)(CPDistributedMessagingCenter *messagingCenter);
	if (!impl) {
		void *handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
		if (handle)
			impl = (void (*)(CPDistributedMessagingCenter *))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
		if (!impl)
			return;
	}
	impl(messaging_center);
}
#endif
