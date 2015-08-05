## Clang configuration for QCOM devices

# Set paths for QCOM LLVM and Clang
QCOM_LLVM_PREBUILTS_PATH := prebuilts/clang/$(BUILD_OS)-x86/host/3.6-qcom/bin
QCOM_LLVM_PREBUILTS_HEADER_PATH := prebuilts/clang/$(BUILD_OS)-x86/host/3.6-qcom/lib/clang/3.6.0/include/
QCOM_CLANG := $(QCOM_LLVM_PREBUILTS_PATH)/clang$(BUILD_EXECUTABLE_SUFFIX)
QCOM_CLANG_CXX := $(QCOM_LLVM_PREBUILTS_PATH)/clang++$(BUILD_EXECUTABLE_SUFFIX)
QCOM_LLVM_AS := $(QCOM_LLVM_PREBUILTS_PATH)/llvm-as$(BUILD_EXECUTABLE_SUFFIX)
QCOM_LLVM_LINK := $(QCOM_LLVM_PREBUILTS_PATH)/llvm-link$(BUILD_EXECUTABLE_SUFFIX)

# Only use QCOM LLVM Clang on TARGET modules that aren't disabled.
DISABLE_QCOM_CLANG := \
						libcompiler_rt \
						libscrypt_static \
						libcrypto \
						libjni_latinime_common_static \
						libdl \
						libz \
						libpdfium \
						libc% \
						libexpat \
						libRSSupport \
						libjni_latinime \
						libpng \
						libclcore.bc \
						libclcore_debug.bc \
						libclcore_neon.bc \
						libnetd_client 

ifeq ($(TARGET_QCOM_CLANG),true)
  ifeq ($(LOCAL_CLANG),true)
    ifeq ($(BUILD_OS),linux)
  	  ifneq ($(strip $(LOCAL_IS_HOST_MODULE)),true)
		ifneq ($(LOCAL_MODULE),$(filter $(LOCAL_MODULE),$(DISABLE_QCOM_CLANG)))
          LLVM_PREBUILTS_PATH := $(QCOM_LLVM_PREBUILTS_PATH)
          LLVM_PREBUILTS_HEADER_PATH := $(QCOM_LLVM_PREBUILTS_HEADER_PATH)
          CLANG := $(QCOM_CLANG)
          CLANG_CXX := $(QCOM_CLANG_CXX)
          LLVM_AS := $(QCOM_LLVM_AS)
          LLVM_LINK := $(QCOM_LLVM_LINK)
					export LOCAL_CLANG_IS_QCOM := true
				else
				  export LOCAL_CLANG_IS_QCOM :=
			  	ifeq (1,$(words $(filter $(USE_AOSP_CLANG),$(LOCAL_MODULE))))
		        LLVM_PREBUILTS_PATH := $(AOSP_LLVM_PREBUILTS_PATH)
		        LLVM_PREBUILTS_HEADER_PATH := $(AOSP_LLVM_PREBUILTS_HEADER_PATH)
		        CLANG := $(AOSP_CLANG)
		        CLANG_CXX := $(AOSP_CLANG_CXX)
		        LLVM_AS := $(AOSP_LLVM_AS)
		        LLVM_LINK := $(AOSP_LLVM_LINK)
		      else
		        LLVM_PREBUILTS_PATH := $(CUSTOM_LLVM_PREBUILTS_PATH)
		        LLVM_PREBUILTS_HEADER_PATH := $(CUSTOM_LLVM_PREBUILTS_HEADER_PATH)
		        CLANG := $(CUSTOM_CLANG)
		        CLANG_CXX := $(CUSTOM_CLANG_CXX)
		        LLVM_AS := $(CUSTOM_LLVM_AS)
		        LLVM_LINK := $(CUSTOM_LLVM_LINK)
		      endif
        endif
  	  endif
  	endif
  endif
endif

# Add flags to use for QCOM Clang
libpath := $(QCOM_LLVM_PREBUILTS_PATH)/../lib/clang/3.6.0/lib

CLANG_QCOM_EXTRA_OPT_LIBGCC := \
  -L $(libpath)/linux/ \
  -l clang_rt.builtins-arm-android

CLANG_QCOM_EXTRA_OPT_LIBGCC_LINK := \
  $(libpath)/linux/libclang_rt.builtins-arm-android.a

CLANG_QCOM_EXTRA_OPT_LIBRARIES_LINK := \
  $(libpath)/linux-propri_rt/libclang_rt.optlibc-krait.a \
  $(libpath)/linux-propri_rt/libclang_rt.translib32.a

$(LOCAL_2ND_ARCH_VAR_PREFIX)TARGET_LIBGCC += $(CLANG_QCOM_EXTRA_OPT_LIBRARIES_LINK)

CLANG_QCOM_CONFIG_arm_TARGET_TRIPLE := armv7a-linux-androideabi


CLANG_QCOM_CONFIG_arm_TARGET_TOOLCHAIN_PREFIX := \
  $(TARGET_TOOLCHAIN_ROOT)/arm-linux-androideabi/bin

CLANG_QCOM_CONFIG_LLVM_DEFAULT_FLAGS := \
  -ffunction-sections \
  -no-canonical-prefixes \
  -fstack-protector \
  -funwind-tables

CLANG_QCOM_CONFIG_EXTRA_FLAGS := \
  -Wno-tautological-constant-out-of-range-compare \
  -fuse-ld=gold \
  -Wno-missing-field-initializers \
  -Wno-unused-local-typedef \
  -Wno-inconsistent-missing-override \
  -Wno-null-dereference \
  -Wno-enum-compare \
	-w

ifeq ($(TARGET_CPU_VARIANT),krait)
  clang_qcom_mcpu := -mcpu=krait -muse-optlibc
  clang_qcom_muse-optlibc := -muse-optlibc
  clang_qcom_mcpu_as := -mcpu=cortex-a15 -mfpu=neon-vfpv4 -mfloat-abi=softfp
else ifeq ($(TARGET_CPU_VARIANT),scorpion)
  clang_qcom_mcpu := -mcpu=scorpion
  clang_qcom_mcpu_as := -mcpu=cortex-a8 -mfpu=neon-vfpv3 -mfloat-abi=softfp
  clang_qcom_muse-optlibc :=
else
  $(info  )
  $(info QCOM_CLANG: warning no supported cpu detected.)
  $(exit)
endif

CLANG_QCOM_CONFIG_KRAIT_ALIGN_FLAGS := \
  -falign-functions -falign-labels -falign-loops

CLANG_QCOM_CONFIG_KRAIT_MEM_FLAGS := \
  -L $(libpath)/linux/ \
  -l clang_rt.optlibc-krait \
  -mllvm -arm-expand-memcpy-runtime=16 \
  -mllvm -arm-opt-memcpy=1 \
  $(clang_qcom_muse-optlibc)


#CLANG_QCOM_CONFIG_KRAIT_PARALLEL_FLAGS := \
#  -L $(libpath)/linux-propri_rt/ \
#  -l clang_rt.translib32 \
#  -fparallel

CLANG_QCOM_CONFIG_arm_UNKNOWN_CFLAGS := \
  -fipa-pta \
  -fsection-anchors \
  -ftree-loop-im \
  -ftree-loop-ivcanon \
  -fno-canonical-system-headers \
  -frerun-cse-after-loop \
  -fgcse-las \
  -fgcse-sm \
  -fivopts \
  -frename-registers \
  -ftracer \
  -funsafe-loop-optimizations \
  -funswitch-loops \
  -fweb \
  -fgcse-after-reload \
  -frename-registers \
  -finline-functions \
	-fkeep-inline-functions \
  -fno-strict-volatile-bitfields \
  -fno-unswitch-loops \
  -fno-if-conversion \
	-mthumb-interwork \
	-Wno-psabi

define subst-clang-qcom-incompatible-arm-flags
  $(subst -march=armv5te,-mcpu=krait,\
  $(subst -march=armv5e,-mcpu=krait,\
  $(subst -march=armv7,-march=armv7a,\
  $(subst -mcpu=cortex-a15,-mcpu=krait,\
  $(subst -mtune=cortex-a15,-mcpu=krait,\
  $(subst -mcpu=cortex-a8,-mcpu=scorpion,\
  $(1)))))))
endef

define convert-to-clang-qcom-flags
  $(strip \
  $(call subst-clang-qcom-incompatible-arm-flags,\
  $(filter-out $(CLANG_QCOM_CONFIG_arm_UNKNOWN_CFLAGS),\
  $(1))))
endef

define convert-to-clang-qcom-ldflags
  $(strip \
  $(filter-out $(CLANG_QCOM_CONFIG_arm_UNKNOWN_CFLAGS),\
  $(1)))
endef

CLANG_QCOM_CONFIG_arm_TARGET_EXTRA_CFLAGS := \
  -nostdlibinc -DANDROID_SMP \
  -B$(CLANG_QCOM_CONFIG_arm_TARGET_TOOLCHAIN_PREFIX) \
  -target $(CLANG_QCOM_CONFIG_arm_TARGET_TRIPLE)

CLANG_QCOM_CONFIG_arm_TARGET_EXTRA_CPPFLAGS := \
  -nostdlibinc -DANDROID_SMP\
  -target $(CLANG_QCOM_CONFIG_arm_TARGET_TRIPLE)

CLANG_QCOM_CONFIG_arm_TARGET_EXTRA_LDFLAGS := \
  $(CLANG_QCOM_CONFIG_LLVM_DEFAULT_FLAGS) \
  $(CLANG_QCOM_CONFIG_KRAIT_MEM_FLAGS) \
  $(CLANG_QCOM_CONFIG_KRAIT_PARALLEL_FLAGS) \
  -target $(CLANG_QCOM_CONFIG_arm_TARGET_TRIPLE)

CLANG_QCOM_TARGET_GLOBAL_CFLAGS := \
  $(call convert-to-clang-qcom-flags,$(TARGET_GLOBAL_CFLAGS)) \
  $(CLANG_QCOM_CONFIG_arm_TARGET_EXTRA_CFLAGS)

CLANG_QCOM_TARGET_GLOBAL_CPPFLAGS := \
  $(call convert-to-clang-qcom-flags,$(TARGET_GLOBAL_CPPFLAGS)) \
  $(CLANG_QCOM_CONFIG_arm_TARGET_EXTRA_CPPFLAGS)

CLANG_QCOM_TARGET_GLOBAL_LDFLAGS := \
  $(call convert-to-clang-qcom-ldflags,$(TARGET_GLOBAL_LDFLAGS)) \
  $(CLANG_QCOM_CONFIG_arm_TARGET_EXTRA_LDFLAGS)
