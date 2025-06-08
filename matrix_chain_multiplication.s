# a0: matrices (int**)
# a1: rows (int*)
# a2: cols (int*)
# a3: split_ptr (int*)
# a4: i
# a5: j
# s9: count (全域傳入)
.text
.globl matrix_chain_multiplication

# first calculate the split matrix

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
    mul     a0, s3, s3       # n*n
    slli    a0, a0, 2        # *4 bytes
    call    malloc
    mv      s4, a0           # s4 = m base

# ---------- malloc s[n][n] ----------
    mul     a0, s3, s3
    slli    a0, a0, 2
    call    malloc
    mv      s5, a0           # s5 = s base

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
    add     t3, t3, t2       # t3 = i*n + j
    slli    t3, t3, 2
    add     a6, s4, t3 # find a6, the address of m[i][j]
    add     a7, s5, t3 # find a7, the address of s[i][j]
    li      t5, 0x7fffffff # maximum of signed, t6 as the temp value
    mv      t6, t0 # candidate of split point, initialize as i

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
    bge     a3, t5, table_skip_upd # if bigger, then skip update
    mv      t5, a3            #update temp value of m[i][j]
    mv      t6, t4            #update candidate of split position as k

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
    # s9: count (全域傳入)
    mv a0, s0
    mv a1, s1
    mv a2, s2
    mv a4, zero # initialize at i = 0
    mv s9, s3 # the total number of matrix
    addi s3, s3, -1
    mv a5, s3 # initialize at j = n-1


    jal compute_result

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
    jr ra # return to c++ code part

# a0: matrices (int**)
# a1: rows (int*)
# a2: cols (int*)
# a3: split_ptr (int*)
# a4: i
# a5: j
# s9: count

# top-bottom find answer

compute_result:
    # save the previous ra, s0 ~ s7
    # s2,s3,s4,s5 keep
    addi sp, sp, -24
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s6, 12(sp)
    sw s7, 16(sp)
    sw s8, 20(sp)

    # a3 = dp table, a4 = i, a5 = j

    # base case: if i == j → return matrices[i]
    beq a4, a5, return_leaf

    # t0 = i * count + j, count = s9
    mul t0, a4, s9
    add t0, t0, a5
    slli t0, t0, 2
    add t1, a3, t0
    lw t2, 0(t1)        # t2 = split[i][j]

    # k = t2
    mv s6, a4    # save i
    mv s7, a5    # save j
    mv s8, t2    # save k

    # left = compute_result(matrices, rows, cols, split, i, k)
    # parameters
    mv a0, s2    # matrices
    mv a1, s3    # rows
    mv a2, s4    # cols
    mv a3, s5    # split_ptr
    mv a5, t2    # k

    call compute_result # = jal ra, compute_result # return matrix's address is in a0
    mv s0, a0    # s0 = left_ptr, the pointer to the left matrix, s0 will be saved always

    # right = compute_result(matrices, rows, cols, split, k+1, j)
    # parameters
    mv a0, s2    # matrices
    mv a1, s3    # rows
    mv a2, s4    # cols
    mv a3, s5    # split_ptr
    addi a4, s8, 1 # k+1
    mv a5, s7    # j

    call compute_result # return matrix's address is in a0
    mv s1, a0    # s1 = right_ptr

    # malloc new matrix: rows[i] × cols[j] × 4
    slli t3, s6, 2     # i*4
    add t3, s3, t3     # row's address + offset
    lw t3, 0(t3)       # t3 = rows[i]
    mv a3, t3

    slli t4, s8, 2  # k*4
    add t5, s3, t4
    addi t5, t5, 4  # (k+1)*4
    add t4, s4, t4
    lw t4, 0(t4)    # t4 = col[k]
    lw t5, 0(t5)    # t5 = row[k+1]
    mv a4, t4
    mv a5, t5

    slli t6, s7, 2     # j*4
    add t6, s4, t6     # col's address + offset
    lw t6, 0(t6)       # t6 = cols[j]
    mv a6, t6

do_mallocd:
    mul t3, t3, t6
    slli a0, t3, 2     # malloc size = rows[i] * cols[j] * 4
    call malloc        # address is stored in a0, a0 to a4 are contaminated

    # malloc new matrix: rows[i] × cols[j] × 4
    slli t3, s6, 2     # i*4
    add t3, s3, t3     # row's address + offset
    lw t3, 0(t3)       # t3 = rows[i]
    mv a3, t3

    slli t4, s8, 2  # k*4
    add t5, s3, t4
    addi t5, t5, 4  # (k+1)*4
    add t4, s4, t4
    lw t4, 0(t4)    # t4 = col[k]
    lw t5, 0(t5)    # t5 = row[k+1]
    mv a4, t4
    mv a5, t5

    slli t6, s7, 2     # j*4
    add t6, s4, t6     # col's address + offset
    lw t6, 0(t6)       # t6 = cols[j]
    mv a6, t6

    add a0, a0, zero
    # multiply_matrix(new_matrix, left, right, rows[i], cols[k], rows[k+1], cols[j])
    # prepare parameters for multiply matrix~
    mv a1, s0 # left matrix
    mv a2, s1 # right matrix

    call matrix_multiplication
    j end_compute

return_leaf:
    # a0 = matrices[i]
    slli t0, a4, 2
    add t0, a0, t0
    lw a0, 0(t0) # a0 now stores the address of matrix i

end_compute:
    # restore s registers value
    lw ra, 0(sp) # very important, restore the return address
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s6, 12(sp)
    lw s7, 16(sp)
    lw s8, 20(sp)
    addi sp, sp, 24
    ret

matrix_multiplication:
    # assume the address of two matricies have been saved to a1, a2
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
    # C[i][j] = sum → *(a0 + (i * B's col + j) * 4) C's base address is on a0
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
    jr ra
