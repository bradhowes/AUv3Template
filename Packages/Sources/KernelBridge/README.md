# KernelBridge

Contains extensions to the Obj-C++ [KernelBridge](../Kernel/include/KernelBridge.h) found in the Kernel package. This
would be unnecessary if Obj-C++ headers in packages could `@import` a dependency package file like the Obj-C++ source
files can.

The naming and file locations are a bit confusing due to the bridging and how Swift handles Obj-C++. In short, the
`KernelBridge` component is only loaded in Swift code, and it contains the requisite mappings to the Obj-C++ code found
in `Kernel`. The `KernelBridge` files in the `Kernel` component must live there in order to have access to the `Kernel`
code. There may be a better way to organize this, or possibly eliminate it all with the introduction of Swift-C++
interoperability.
