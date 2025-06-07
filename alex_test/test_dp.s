.text
.globl matrix_chain_multiplication

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

    mv s0, a0 # since a0 is pointer of pointer
    mv s1, a1 # row size
    mv s2, a2 # column size
    mv s3, a3 # number of matrix

# ---------- malloc m[n][n] ----------
    mul     a0, s3, s3       # n*n
    slli    a0, a0, 2        # *4 bytes
    call    malloc
    mv      s4, a0           # m base

# ---------- malloc s[n][n] ----------
    mul     a0, s3, s3
    slli    a0, a0, 2
    call    malloc
    mv      s5, a0           # s base

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
    li      s6, 2
table_len_loop:
    bgt     s6, s3, table_done

    li      t0, 0            # i
table_i_loop:
    sub     t1, s3, s6       # n-len
    bgt     t0, t1, table_next_len

    add     t2, t0, s6
    addi    t2, t2, -1       # j = i+len-1

    # m[i][j] = +∞
    mul     t3, t0, s3
    add     t3, t3, t2
    slli    t3, t3, 2
    add     t3, s4, t3
    li      t4, 0x7fffffff
    sw      t4, 0(t3)

    mv      t4, t0           # k = i
table_k_loop:
    beq     t4, t2, table_k_done

    # ---------- cost_left ----------
    mul     a3, t0, s3
    add     a3, a3, t4
    slli    a3, a3, 2
    add     a3, s4, a3
    lw      a3, 0(a3)

    # ---------- cost_right ----------
    addi    a4, t4, 1        # k+1
    mul     a4, a4, s3
    add     a4, a4, t2
    slli    a4, a4, 2
    add     a4, s4, a4
    lw      a4, 0(a4)

    add     a3, a3, a4       # partial = left + right

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
    lw      a5, 0(t3)        # current m[i][j]
    bge     a3, a5, table_skip_upd
    sw      a3, 0(t3)        # m[i][j] = cost

    mul     a6, t0, s3
    add     a6, a6, t2
    slli    a6, a6, 2
    add     a6, s5, a6
    sw      t4, 0(a6)        # s[i][j] = k
table_skip_upd:
    addi    t4, t4, 1        # k++
    j       table_k_loop
table_k_done:
    addi    t0, t0, 1        # i++
    j       table_i_loop
table_next_len:
    addi    s6, s6, 1        # len++
    j       table_len_loop
table_done:
    mv      s11, s5           # return S base

result:
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
    lw s10, 40(sp)
    lw s11, 44(sp)
    lw ra, 48(sp)
    addi sp, sp, 52
    jr ra
