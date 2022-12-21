/**
 * Copyright 1993-2015 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

/**
 * Vector addition: C = A + B.
 *
 * This sample is a very basic sample that implements element by element
 * vector addition. It is the same as the sample illustrating Chapter 2
 * of the programming guide with some additions like error checking.
 */

#include <stdio.h>

// For the CUDA runtime routines (prefixed with "cuda_")
#include <cuda_runtime.h>

#include <helper_cuda.h>
/**
 * CUDA Kernel Device code
 *
 * Computes the vector addition of A and B into C. The 3 vectors have the same
 * number of elements numElements.
 */
__global__ void
vectorAdd(const float *A, const float *B, float *C, int numElements)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;

    if (i < numElements)
    {
        C[i] = A[i] + B[i];
    }
}

/**
 * Host main routine
 */
int main(void)
{
    // Print the vector length to be used, and compute its size
    int numElements = 1;
    size_t size = numElements * sizeof(float);
    printf("[Vector addition of %d elements]\n", numElements);
    float *A, *B, *C;
    checkCudaErrors(cudaMallocManaged(&A, numElements * sizeof(float)));
    checkCudaErrors(cudaMallocManaged(&B, numElements * sizeof(float)));
    checkCudaErrors(cudaMallocManaged(&C, numElements * sizeof(float)));

    A[0] = 0.123456789;
    B[0] = 0.1;

    // Launch the Vector Add CUDA Kernel
    int threadsPerBlock = 256;
    int blocksPerGrid = (numElements + threadsPerBlock - 1) / threadsPerBlock;
    printf("CUDA kernel launch with %d blocks of %d threads\n", blocksPerGrid, threadsPerBlock);
    vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(A, B, C, numElements);
    cudaDeviceSynchronize();

    printf("%f\n", C[0]);
    if (abs(C[0] - 0.2234567) < 1e-6)
        printf("Test PASSED\n");
    else{
        printf("Test Failed.\n");
    }

    // Free device global memory
    checkCudaErrors(cudaFree(A));
    checkCudaErrors(cudaFree(B));
    checkCudaErrors(cudaFree(C));
    printf("Done\n");
    return 0;
}
