CUDA_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
include $(CUDA_DIR)/../common.mk


#
# Auxiliary
#

DUMMY=
SPACE=$(DUMMY) $(DUMMY)
COMMA=$(DUMMY),$(DUMMY)

define join-list
$(subst $(SPACE),$(2),$(1))
endef


#
# CUDA detection
#

$CUDA_PATH ?= /usr/local/cuda

CUDA_ROOT ?= ${CUDA_PATH}

MACHINE := $(shell uname -m)
ifeq ($(MACHINE), x86_64)
LDFLAGS += -L$(CUDA_ROOT)/lib64
endif
ifeq ($(MACHINE), i686)
LDFLAGS += -L$(CUDA_ROOT)/lib
endif

CPPFLAGS += -isystem $(CUDA_ROOT)/include -isystem $(CUDA_DIR)/../common/cuda

NVCC=$(CUDA_ROOT)/bin/nvcc

LDLIBS   += -lcudart -lnvToolsExt


#
# NVCC compilation
#
SMS ?= 75
ifeq ($(SMS),)
$(info >>> WARNING - no SM architectures have been specified - waiving sample <<<)
SAMPLE_ENABLED := 0
endif

ifeq ($(GENCODE_FLAGS),)
# Generate SASS code for each SM architecture listed in $(SMS)
$(foreach sm,$(SMS),$(eval GENCODE_FLAGS += -gencode arch=compute_$(sm),code=sm_$(sm)))

# Generate PTX code from the highest SM architecture in $(SMS) to guarantee forward-compatibility
HIGHEST_SM := $(lastword $(sort $(SMS)))
ifneq ($(HIGHEST_SM),)
GENCODE_FLAGS += -gencode arch=compute_$(HIGHEST_SM),code=compute_$(HIGHEST_SM)
endif
endif

# NOTE: passing -lcuda to nvcc is redundant, and shouldn't happen via -Xcompiler
# TODO: pass all CXXFLAGS to nvcc using -Xcompiler (i.e. -O3, -g, etc.)
NONCUDA_LDLIBS = $(filter-out -lcuda -lcudart,$(LDLIBS))

ifneq ($(strip $(NONCUDA_LDLIBS)),)
NVCC_LDLIBS += -Xcompiler $(call join-list,$(NONCUDA_LDLIBS),$(COMMA))
endif
NVCC_LDLIBS += -lcuda -lnvToolsExt

NVCCFLAGS += --generate-line-info -g $(GENCODE_FLAGS)
ifdef DEBUG
NVCCFLAGS += -g --device-debug
endif

%: %.cu
	$(NVCC) $(CPPFLAGS) $(NVCCFLAGS) $(NVCC_LDLIBS) -o $@ $^

%.o: %.cu
	$(NVCC) $(CPPFLAGS) $(NVCCFLAGS) -c -o $@ $<

%.ptx: %.cu
	$(NVCC) $(CPPFLAGS) $(NVCCFLAGS) -ptx -o $@ $<
