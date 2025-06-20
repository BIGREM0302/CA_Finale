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
    # prepare those parameters compute_result need
    # a0: matrices (int**)
    # a1: rows (int*)
    # a2: cols (int*)
    # a3: split_ptr (int*)
    # a4: i
    # a5: j
    # s9: count (全域傳入)
    mv a2, s2
    mv a4, zero # initialize at i = 0
    mv s9, s3 # the total number of matrix
    addi a5, s9, -1

    mv s2, s0    # save matrix address
    mv s3, s1    # save row address
    mv s4, a2    # save col address

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
    addi sp, sp, -24
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s6, 12(sp)
    sw s7, 16(sp)
    sw s8, 20(sp)

    # base case: if i == j → return matrices[i]
    beq a4, a5, return_leaf

    # t0 = i * count + j, count = s9
    mul t0, a4, s9
    add t0, t0, a5
    slli t0, t0, 2
    add t1, s5, t0
    lw t2, 0(t1)        # t2 = split[i][j]

    # k = t2
    mv s6, a4    # save i
    mv s7, a5    # save j
    mv s8, t2    # save k

    # left = compute_result(matrices, rows, cols, split, i, k)
    # parameters
    mv a5, t2    # k

    call compute_result # = jal ra, compute_result # return matrix's address is in a0
    mv s0, a0    # s0 = left_ptr, the pointer to the left matrix, s0 will be saved always

    # right = compute_result(matrices, rows, cols, split, k+1, j)
    # parameters
    addi a4, s8, 1 # k+1
    mv a5, s7    # j

    call compute_result # return matrix's address is in a0
    mv s1, a0    # s1 = right_ptr

    # malloc new matrix: rows[i] × cols[j] × 4
    slli t3, s6, 2     # i*4
    add t3, s3, t3     # row's address + offset
    lw t3, 0(t3)       # t3 = rows[i]

    slli t6, s7, 2     # j*4
    add t6, s4, t6     # col's address + offset
    lw t6, 0(t6)       # t6 = cols[j]

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
    add t0, s2, t0
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
    li      s11, 32             # s11 = TILE_K (=16)
    li      t0, 0              # t0 = i  (row index)
i_loop:
    bge     t0, a3, mm_done
    li      t1, 0              # t1 = j  (col index)
j_loop:
    bge     t1, a6, next_i
    li      t6, 0              # t6 = sum
    li      t2, 0              # t2 = kk (tile base)
kk_outer:                       # for kk = 0; kk < p; kk += TILE_K
    bge     t2, a4, store_c
    li      t3, 0              # t3 = k'  (inside tile 0..TILE_K-1)
kk_inner:
    add     t4, t2, t3         # t4 = k = kk + k'
    bge     t4, a4, kk_next

    # ---- load A[i][k] into t5 ----
    mul     t5, t0, a4         # i * p
    add     t5, t5, t4
    slli    t5, t5, 2
    add     t5, a1, t5
    lw      t5, 0(t5)          # t5 = A[i][k]

    # ---- load B[k][j] into t4 ----
    mul     t4, t4, a6         # k * c
    add     t4, t4, t1
    slli    t4, t4, 2
    add     t4, a2, t4
    lw      t4, 0(t4)          # t4 = B[k][j]

    # ---- accumulate ----
    mul     t5, t5, t4
    add     t6, t6, t5         # sum += A*B

    addi    t3, t3, 1
    blt     t3, s11, kk_inner   # k' < TILE_K ?
kk_next:
    add     t2, t2, s11         # kk += TILE_K
    j       kk_outer

store_c:                       # C[i][j] = sum
    mul     t4, t0, a6         # i * c
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
    jr      ra

#---------