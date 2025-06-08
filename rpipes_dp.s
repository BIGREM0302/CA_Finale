.data
A: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
B: .word 30, 35, 15, 5, 10, 20
C: .word 35, 15, 5, 10, 20, 25
m: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
s: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
.global main

main:

la a0, A
la a1, B
la a2, C

li a3, 6


matrix_chain_multiplication:

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
    sw s10, 40(sp)
    sw s11, 44(sp)
    sw ra, 48(sp)

    mv s0, a0 # since a0 is pointer of pointer, no use in this part
    mv s1, a1 # row size
    mv s2, a2 # column size
    mv s3, a3 # number of matrix

# ---------- malloc m[n][n] ----------
    la      s4, m

# ---------- malloc s[n][n] ----------
    la      s5, s

# ---------- m[i][i] = 0 ----------
    li      t0, 0
table_diag_loop:
    beq     t0, s3, table_diag_done
    mul     t1, t0, s3       # i*n
    add     t1, t1, t0       # +i
    slli    t1, t1, 2
    add     t1, s4, t1
    sw      zero, 0(t1)
    addi    t0, t0, 1
    j       table_diag_loop
table_diag_done:

# ----------  len = 2 .. n ----------
    li      s6, 2 # s6 = l, initialized as 2
table_len_loop:
    bgt     s6, s3, table_done # if l > n, then complete

    li      t0, 0            # t0 = i
table_i_loop:
    sub     t1, s3, s6       # n-len
    bgt     t0, t1, table_next_len # if i > n-len, then nxt cycle

    add     t2, t0, s6       # t2 = j
    addi    t2, t2, -1       # j = i+len-1

    # m[i][j] = +infty
    mul     t3, t0, s3
    add     t3, t3, t2
    slli    t3, t3, 2
    add     a6, s4, t3 # find a6, the address of m[i][j]
    add     a7, s5, t3 # find a7, the address of s[i][j]
    li      t5, 0x7fffffff # maximum of signed, t6 as the temp value
    mv      t6, t0 # candidate of split point, initialize as i
    #sw      t4, 0(t3)

    mv      t4, t0           # t4 = k, = i initially
table_k_loop:
    beq     t4, t2, table_k_done # if k == j, then stop k loop

    # ---------- cost_left ----------
    mul     a3, t0, s3      # m[i, k]
    add     a3, a3, t4
    slli    a3, a3, 2
    add     a3, s4, a3
    lw      a3, 0(a3)

    # ---------- cost_right ----------
    addi    a4, t4, 1        # m[k+1, j]
    mul     a4, a4, s3
    add     a4, a4, t2
    slli    a4, a4, 2
    add     a4, s4, a4
    lw      a4, 0(a4)

    add     a3, a3, a4       # partial = a3 = left + right

    # ---------- term = B[i] * C[k] * C[j] ----------
    slli    a4, t0, 2        # offset rows[i]
    add     a4, s1, a4
    lw      a4, 0(a4)        # B[i]

    slli    a5, t4, 2        # offset cols[k]
    add     a5, s2, a5
    lw      a5, 0(a5)        # C[k]
    mul     a4, a4, a5       # B[i]*C[k]

    slli    a5, t2, 2        # offset cols[j]
    add     a5, s2, a5
    lw      a5, 0(a5)        # C[j]
    mul     a4, a4, a5       # B[i]*C[k]*C[j]

    add     a3, a3, a4       # total cost

    # ---------- dp: m,s ----------
    #lw      a5, 0(a6)        # current m[i][j]
    bge     a3, t5, table_skip_upd # if bigger, then skip update
    mv      t5, a3            #update temp value of m[i][j]
    mv      t6, t4            #update candidate of split position as k
    #sw      a3, 0(a6)        # m[i][j] = cost

    #mul     a6, t0, s3
    #add     a6, a6, t2
    #slli    a6, a6, 2
    #add     a6, s5, a6
    #sw      t4, 0(a7)        # s[i][j] = k
table_skip_upd:
    addi    t4, t4, 1        # k++
    j       table_k_loop
table_k_done:
    # store word
    sw      t5, 0(a6)
    sw      t6, 0(a7)
    addi    t0, t0, 1        # i++
    j       table_i_loop
table_next_len:
    addi    s6, s6, 1        # len++
    j       table_len_loop
table_done:
    mv      a3, s5           # return S base
    # prepare those parameters compute_result need
    # a0: matrices (int**)
    # a1: rows (int*)
    # a2: cols (int*)
    # a3: split_ptr (int*)
    # a4: i
    # a5: j
    # s9: count (¥þ°ì¶Ç¤J)
    mv a0, s0
    mv a1, s1
    mv a2, s2
    mv a4, zero # initialize at i = 0
    mv s9, s3 # the total number of matrix
    addi s3, s3, -1
    mv a5, s3 # initialize at j = n-1
    li a7, 10
    ecall