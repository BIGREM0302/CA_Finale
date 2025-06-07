.text
.globl matrix_chain_multiplication

matrix_chain_multiplication:

    # Your implementation here
    # a0 stores the addresses of all matricies, a1 stores row size, a2 stores column size, a3 stores number
    # of matricies
    #first multiply in order
    addi sp, sp, -52
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    sw s4, 16(sp)
    sw s5, 20(sp)
    sw s6, 24(sp)
    sw s7, 28(sp)
    sw s8, 32(sp)
    sw s9, 36(sp)
    sw s10,40(sp)
    sw s11,44(sp)
    sw ra, 48(sp)
    
    mv s0, a0 # since a0 is pointer of pointer
    mv s1, a1 # row size
    mv s2, a2 # column size
    mv s3, a3 # number of matrix
    addi s3, s3, -1 # n-1
    slli t0, s3, 2 # (n-1)*4
    add s0, s0, t0
    add s1, s1, t0
    add s2, s2, t0
    # s4, s5, s6, s7
    mv s8, s3 # s8 = a3 - 1 = n - 1
    #mv s3, zero
n_loop:
    beq s8, zero, result # when s8 = 0, complete
    beq s8, s3, initial # when s8 = s3

normal:
    mv s10, a0
    lw s9, 0(s0)
    addi s0, s0, -4
    # row #
    lw s4, 0(s1)
    addi s1, s1, -4
    # col #
    lw s5, 0(s2)
    addi s2, s2, -4
    
    j call_subfunction

initial:
    lw s10, 0(s0)
    addi s0, s0, -4
    lw s9, 0(s0)
    addi s0, s0, -4
    # row #
    lw s6, 0(s1)
    addi s1, s1, -4
    lw s4, 0(s1)
    addi s1, s1, -4
    # col #
    lw s7, 0(s2)
    addi s2, s2, -4
    lw s5, 0(s2)
    addi s2, s2, -4

call_subfunction:
    # new matrix
    mul a0, s4, s7 # size of new matrix: A's row # * B's col #
    slli a0, a0, 2
    #addi sp, sp, -8 
    #sw s9, 0(sp)
    #sw s10, 4(sp)
    call malloc # allocate memory, address is stored in a0
    #lw s9, 0(sp)
    #lw s10, 4(sp)
    #addi sp, sp, 8
    jal matrix_multiplication # should use jump and link
    mv s6, a1 # the return width
    mv s7, a2 # the return height

next_n:
    addi s8, s8, -1
    j n_loop

matrix_multiplication:
    li      a3, 16             # a3 = TILE_K (=16)
    li      t0, 0              # t0 = i  (row index)
i_loop:
    bge     t0, s4, mm_done
    li      t1, 0              # t1 = j  (col index)
j_loop:
    bge     t1, s7, next_i
    li      t6, 0              # t6 = sum
    li      t2, 0              # t2 = kk (tile base)
kk_outer:                       # for kk = 0; kk < p; kk += TILE_K
    bge     t2, s5, store_c
    li      t3, 0              # t3 = k'  (inside tile 0..TILE_K-1)
kk_inner:
    add     t4, t2, t3         # t4 = k = kk + k'
    bge     t4, s5, kk_next

    # ---- load A[i][k] into t5 ----
    mul     t5, t0, s5         # i * p
    add     t5, t5, t4
    slli    t5, t5, 2
    add     t5, s9, t5
    lw      t5, 0(t5)          # t5 = A[i][k]

    # ---- load B[k][j] into t4 ----
    mul     t4, t4, s7         # k * c
    add     t4, t4, t1
    slli    t4, t4, 2
    add     t4, s10, t4
    lw      t4, 0(t4)          # t4 = B[k][j]

    # ---- accumulate ----
    mul     t5, t5, t4
    add     t6, t6, t5         # sum += A*B

    addi    t3, t3, 1
    blt     t3, a3, kk_inner   # k' < TILE_K ?
kk_next:
    add     t2, t2, a3         # kk += TILE_K
    j       kk_outer

store_c:                       # C[i][j] = sum
    mul     t4, t0, s7         # i * c
    add     t4, t4, t1
    slli    t4, t4, 2
    add     t4, a0, t4
    sw      t6, 0(t4)

    addi    t1, t1, 1          # ++j
    j       j_loop
next_i:
    addi    t0, t0, 1          # ++i
    j       i_loop

mm_done:
    mv      a1, s4             # return height  (rows of C)
    mv      a2, s7             # return width   (cols of C)
    jr      ra
# ───────────────────────────────────────────────────────────────

result:
    # Return to main program after completion (Remember to store the return address at the beginning)
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    lw s4, 16(sp)
    lw s5, 20(sp)
    lw s6, 24(sp)
    lw s7, 28(sp)
    lw s8, 32(sp)
    lw s9, 36(sp)
    lw s10,40(sp)
    lw s11,44(sp)
    lw ra, 48(sp)
    addi sp, sp, 52
    #li a0, 4
    #call malloc
    # jr ra
    jr ra
