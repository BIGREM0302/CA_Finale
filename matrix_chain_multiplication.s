.text
.globl matrix_chain_multiplication

matrix_chain_multiplication:

    # Your implementation here
    # a0 stores the addresses of all matricies, a1 stores row size, a2 stores column size, a3 stores number
    # of matricies
    #first multiply in order
    addi sp, sp, -40
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    sw s4, 16(sp)
    sw s5, 20(sp)
    sw s6, 24(sp)
    sw s7, 28(sp)
    sw s8, 32(sp)
    sw ra, 36(sp)
    
    mv s0, a0 # since a0 is pointer of pointer
    mv s1, a1 # row size
    mv s2, a2 #column size
    mv s3, a3 # number of matrix
    # s4, s5, s6, s7
    mv s8, zero

    addi s3, s3, -1
    #mv s3, zero
n_loop:
    bge s8, s3, result
    beq s8, zero, initial
normal:
    mv s9, a0
    lw s10, 0(s0)
    addi s0, s0, 4
    # row #
    lw s6, 0(s1)
    addi s1, s1, 4
    # col #
    lw s7, 0(s2)
    addi s2, s2, 4
    
    j call_subfunction

initial:
    lw s9, 0(s0)
    addi s0, s0, 4
    lw s10, 0(s0)
    addi s0, s0, 4
    # row #
    lw s4, 0(s1)
    addi s1, s1, 4
    lw s6, 0(s1)
    addi s1, s1, 4
    # col #
    lw s5, 0(s2)
    addi s2, s2, 4
    lw s7, 0(s2)
    addi s2, s2, 4

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
    mv s4, a1 # the return width
    mv s5, a2 # the return height

next_n:
    addi s8, s8, 1
    j n_loop

matrix_multiplication:
    # assume the address of two matricies have been saved to s9, s10
    # size: a: (t3, t4), b: (t5, t6), c: (t3, t6)
    # size: a: (s4, s5), b: (s6, s7), c: (s4, s7)
    # TODO: optimization: tiled matrix multiplication
    mv      t0, zero          # i = 0
i_loop:
    bge     t0, s4, done      # if i >= a's row, done
    mv      t1, zero          # j = 0
j_loop:
    bge     t1, s7, next_i    # if j >= b's col, next i
    mv      t2, zero             # sum = 0
    mv      t3, zero          # k = 0
k_loop:
    bge     t3, s5, store_c   # if k >= a's col = b's row, store

    # A[i][k] = *(s9 + (i * a's col + k) * 4)
    mul     t4, t0, s5        # i * A_cols
    add     t4, t4, t3        # i * A_cols + k
    slli    t4, t4, 2         # offset * 4
    add     t4, s9, t4
    lw      t5, 0(t4)         # t5 = A[i][k]

    # B[k][j] = *(a5 + (k * b's col + j) * 4)
    mul     t4, t3, s7        # k * B_cols
    add     t4, t4, t1        # k * B_cols + j
    slli    t4, t4, 2
    add     t4, s10, t4
    lw      t6, 0(t4)         # t6 = B[k][j]

    # sum += A[i][k] * B[k][j]
    mul     t5, t5, t6
    add     t2, t2, t5

    addi    t3, t3, 1 # k = k + 1
    j       k_loop

store_c:
    # C[i][j] = sum → *(a0 + (i * B's col + j) * 4) C's base address is on a0
    mul     t4, t0, s7
    add     t4, t4, t1
    slli    t4, t4, 2
    add     t4, a0, t4
    sw      t2, 0(t4)

    addi    t1, t1, 1 # j = j + 1
    j       j_loop

next_i:
    addi    t0, t0, 1 # i = i + 1
    j       i_loop

done:
    # store C's height and width
    mv a1, s4 # A's row
    mv a2, s7 # B's col
    jr ra
    #return

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
    lw ra, 36(sp)
    addi sp, sp, 40
    #li a0, 4
    #call malloc
    # jr ra
    jr ra
