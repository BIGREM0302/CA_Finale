.data
A: .word 2, 3, 1, 4, 5, 6
B: .word 3, 2, 1
C: .word 0, 0

.text
.global main

main:

la a1, A
la a2, B
la a0, C

li a3, 2
li a4, 3
li a5, 3
li a6, 1

matrix_multiplication:
    # assume the address of two matricies have been saved to s9, s10
    # assume the address of two matricies have been saved to a1, a2
    # size: a: (t3, t4), b: (t5, t6), c: (t3, t6)
    # size: a: (s4, s5), b: (s6, s7), c: (s4, s7)
    # size: a: (a3, a4), b: (a5, a6), c: (a3, a6)
    # TODO: optimization: tiled matrix multiplication
    mv      t0, zero          # i = 0
i_loop:
    bge     t0, a3, done      # if i >= a's row, done
    mv      t1, zero          # j = 0
j_loop:
    bge     t1, a6, next_i    # if j >= b's col, next i
    mv      t2, zero             # sum = 0
    mv      t3, zero          # k = 0
k_loop:
    bge     t3, a4, store_c   # if k >= a's col = b's row, store

    # A[i][k] = *(a1 + (i * a's col + k) * 4)
    mul     t4, t0, a4        # i * A_cols
    add     t4, t4, t3        # i * A_cols + k
    slli    t4, t4, 2         # offset * 4
    add     t4, a1, t4
    lw      t5, 0(t4)         # t5 = A[i][k]

    # B[k][j] = *(a2 + (k * b's col + j) * 4)
    mul     t4, t3, a6        # k * B_cols
    add     t4, t4, t1        # k * B_cols + j
    slli    t4, t4, 2
    add     t4, a2, t4
    lw      t6, 0(t4)         # t6 = B[k][j]

    # sum += A[i][k] * B[k][j]
    mul     t5, t5, t6
    add     t2, t2, t5

    addi    t3, t3, 1 # k = k + 1
    j       k_loop

store_c:
    # C[i][j] = sum ¡÷ *(a0 + (i * B's col + j) * 4) C's base address is on a0
    mul     t4, t0, a6
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

    li a7, 10
    ecall
    #jr ra
    #return