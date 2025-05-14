import os
from colorama import Fore, Style, init

# Initialize colorama (autoreset ensures the color resets after each print)
init(autoreset=True)

def compare_files(file1, file2):
    """Read and compare two files. Return True if they are identical."""
    try:
        with open(file1, 'r') as f1, open(file2, 'r') as f2:
            content1 = f1.read()
            content2 = f2.read()
        return content1 == content2
    except Exception as e:
        # If an error occurs (like file not found), you might want to print/log it.
        print(f"Error comparing {file1} and {file2}: {e}")
        return False

def main():
    base_path = "./"
    
    # Loop over test indices.
    # For public tests: indices 0-5 (files answer_00.txt to answer_05.txt)
    # For private tests: indices 6-10 (files answer_06.txt to answer_10.txt)
    for i in range(6):  # 0 through 10
        # Determine the directory based on index
        answer_dir = os.path.join(base_path, "answer", "public")
        golden_dir = os.path.join(base_path, "golden", "public")
        
        # Format the file names with zero-padded indices (e.g., 00, 01, ..., 10)
        answer_file = os.path.join(answer_dir, f"answer_{i:02d}.txt")
        golden_file = os.path.join(golden_dir, f"golden_{i:02d}.txt")
        
        # Compare the files
        if compare_files(answer_file, golden_file):
            print(f"{Fore.GREEN}P{i} succeed{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}P{i} fail{Style.RESET_ALL}")

if __name__ == "__main__":
    main()
