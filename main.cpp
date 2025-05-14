#include <fcntl.h>    // open
#include <unistd.h>   // read, write, close, ftruncate
#include <stdlib.h>   // malloc, free, strtol, exit, strdup
#include <stdio.h>    // snprintf, fprintf, perror
#include <string.h>   // memcpy, strlen, strcmp
#include <sys/stat.h> // mkdir, mode_t
#include <sys/types.h>
#include <errno.h>
#include <libgen.h> // dirname

// Helper function: recursively create directories (similar to "mkdir -p").
int mkpath(const char *dir, mode_t mode)
{
    char tmp[1024];
    char *p = NULL;
    size_t len;

    // Copy the directory path to a temporary buffer.
    snprintf(tmp, sizeof(tmp), "%s", dir);
    len = strlen(tmp);
    if (len == 0)
        return -1;
    // Remove trailing slash if present.
    if (tmp[len - 1] == '/')
        tmp[len - 1] = '\0';

    // Iterate through the path and create each subdirectory.
    for (p = tmp + 1; *p; p++)
    {
        if (*p == '/')
        {
            *p = '\0';
            if (mkdir(tmp, mode) != 0)
            {
                if (errno != EEXIST)
                    return -1;
            }
            *p = '/';
        }
    }
    // Create the final directory.
    if (mkdir(tmp, mode) != 0)
    {
        if (errno != EEXIST)
            return -1;
    }
    return 0;
}

// Create the parent directory of the given filepath.
int create_parent_directory(const char *filepath)
{
    char *path_copy = strdup(filepath);
    if (!path_copy)
        return -1;
    char *dir = dirname(path_copy);
    int ret = 0;
    // If dirname returns "." then there is no directory component.
    if (strcmp(dir, ".") != 0)
    {
        ret = mkpath(dir, 0755);
    }
    free(path_copy);
    return ret;
}

// The matrix_chain_multiplication function multiplies matrices in order.
// It returns a pointer to a newly allocated matrix which is the result of
// multiplying matrices[0] x matrices[1] x ... x matrices[count-1].
extern "C"
{
    int *matrix_chain_multiplication(int **matrices, int *rows, int *cols, int count);
}

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        fprintf(stderr, "Usage: %s <input_file_path> <output_file_path>\n", argv[0]);
        return 1;
    }

    // Ensure the output file's parent directory exists.
    if (create_parent_directory(argv[2]) != 0)
    {
        fprintf(stderr, "Failed to create output directory for %s\n", argv[2]);
        return 1;
    }

    // Open the input file for reading using the provided file path.
    int fd = open(argv[1], O_RDONLY);
    if (fd < 0)
    {
        perror("open input file");
        return 1;
    }

    // Read the entire input file into a buffer.
    // (Assume the file is not larger than 8192 bytes.)
    size_t buffer_size = 8192;
    char *input_buffer = (char *)malloc(buffer_size + 1);
    if (!input_buffer)
    {
        close(fd);
        return 1;
    }
    ssize_t bytes_read = read(fd, input_buffer, buffer_size);
    if (bytes_read < 0)
    {
        free(input_buffer);
        close(fd);
        return 1;
    }
    input_buffer[bytes_read] = '\0';
    close(fd);

    // Parse the input.
    // The first integer is the number of matrices.
    char *p = input_buffer;
    char *endptr;
    int count = (int)strtol(p, &endptr, 10);
    p = endptr;

    // Allocate arrays for the rows, columns, and the matrix pointers.
    int *rows_arr = (int *)malloc(count * sizeof(int));
    int *cols_arr = (int *)malloc(count * sizeof(int));
    int **matrices = (int **)malloc(count * sizeof(int *));
    if (!rows_arr || !cols_arr || !matrices)
    {
        free(input_buffer);
        if (rows_arr)
            free(rows_arr);
        if (cols_arr)
            free(cols_arr);
        if (matrices)
            free(matrices);
        return 1;
    }

    // For each matrix, first read its dimensions then its content.
    for (int i = 0; i < count; i++)
    {
        // Skip any whitespace.
        while (*p == ' ' || *p == '\n' || *p == '\r' || *p == '\t')
            p++;
        int r = (int)strtol(p, &endptr, 10);
        p = endptr;
        while (*p == ' ' || *p == '\n' || *p == '\r' || *p == '\t')
            p++;
        int c = (int)strtol(p, &endptr, 10);
        p = endptr;
        rows_arr[i] = r;
        cols_arr[i] = c;

        // Allocate memory for this matrix (stored in row-major order).
        int *mat = (int *)malloc(r * c * sizeof(int));
        if (!mat)
        {
            // Free any previously allocated matrices.
            for (int j = 0; j < i; j++)
            {
                free(matrices[j]);
            }
            free(matrices);
            free(rows_arr);
            free(cols_arr);
            free(input_buffer);
            return 1;
        }

        // Read r*c integers.
        for (int j = 0; j < r * c; j++)
        {
            while (*p == ' ' || *p == '\n' || *p == '\r' || *p == '\t')
                p++;
            mat[j] = (int)strtol(p, &endptr, 10);
            p = endptr;
        }
        matrices[i] = mat;
    }
    free(input_buffer); // no longer needed

    // Perform the chain multiplication.
    int *result = matrix_chain_multiplication(matrices, rows_arr, cols_arr, count);
    if (!result)
    {
        // Free the allocated matrices and arrays.
        for (int i = 0; i < count; i++)
            free(matrices[i]);
        free(matrices);
        free(rows_arr);
        free(cols_arr);
        return 1;
    }
    // The dimensions of the final result are:
    //   rows = rows_arr[0]  and  cols = cols_arr[count-1]
    int final_rows = rows_arr[0];
    int final_cols = cols_arr[count - 1];

    // Open the output file for writing using the provided file path.
    int out_fd = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (out_fd < 0)
    {
        perror("open output file");
        free(result);
        for (int i = 0; i < count; i++)
            free(matrices[i]);
        free(matrices);
        free(rows_arr);
        free(cols_arr);
        return 1;
    }

    // Additionally, explicitly truncate the file to zero length.
    if (ftruncate(out_fd, 0) < 0)
    {
        perror("ftruncate output file");
        close(out_fd);
        free(result);
        for (int i = 0; i < count; i++)
            free(matrices[i]);
        free(matrices);
        free(rows_arr);
        free(cols_arr);
        return 1;
    }

    // Write the final matrix to the output file.
    // Each row is formatted using snprintf and written with write.
    char out_line[1024];
    for (int i = 0; i < final_rows; i++)
    {
        int pos = 0;
        for (int j = 0; j < final_cols; j++)
        {
            int n = snprintf(out_line + pos, sizeof(out_line) - pos, "%d", result[i * final_cols + j]);
            pos += n;
            if (j < final_cols - 1)
            {
                if (pos < (int)sizeof(out_line) - 1)
                {
                    out_line[pos] = ' ';
                    pos++;
                    out_line[pos] = '\0';
                }
            }
        }
        if (pos < (int)sizeof(out_line) - 1)
        {
            out_line[pos] = '\n';
            pos++;
            out_line[pos] = '\0';
        }
        write(out_fd, out_line, pos);
    }
    close(out_fd);

    // Free all allocated memory.
    free(result);
    for (int i = 0; i < count; i++)
    {
        free(matrices[i]);
    }
    free(matrices);
    free(rows_arr);
    free(cols_arr);

    return 0;
}
