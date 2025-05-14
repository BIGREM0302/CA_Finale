import re
import os
import json
import math
from colorama import Fore, Style, init

def read_json_file(filename):
    with open(filename, 'r') as f:
        data = json.load(f)
    return data

def extract_cache_sizes(json_data):
    cache_sizes = {}
    associativity = {}

    cache_sizes['l1d'] = json_data['system'].get('l1dcache', {}).get('size', 'Not found')
    cache_sizes['l1i'] = json_data['system'].get('l1icache', {}).get('size', 'Not found')
    cache_sizes['l2'] = json_data['system'].get('l2cache', {}).get('size', 'Not found')

    associativity['l1d'] = json_data['system'].get('l1dcache', {}).get('assoc', 'Not found')
    associativity['l1i'] = json_data['system'].get('l1icache', {}).get('assoc', 'Not found')
    associativity['l2'] = json_data['system'].get('l2cache', {}).get('assoc', 'Not found')

    return cache_sizes, associativity

def parse_line(line):
    match = re.match(r"(\d+):.*@main.*", line)
    if match:
        return "main", int(match.group(1))
    
    match = re.match(r"(\d+):.*@exit.*", line)
    if match:
        return "exit", int(match.group(1))
    
    return None, None

def calculate_execution_time(filename):
    with open(filename, 'r') as file:
        start_time = None
        end_time = None

        for line in file:
            point, timestamp = parse_line(line)
            if point == "main" and start_time is None:
                start_time = timestamp // 1000
                # print(f"Found entry point @main at time {start_time} in file {filename}")
            elif point == "exit" and end_time is None:
                end_time = timestamp // 1000
                # print(f"Found exit point @exit at time {end_time} in file {filename}")
            
            if start_time is not None and end_time is not None:
                break
        
        if start_time is not None and end_time is not None:
            execution_time = end_time - start_time
            # print(f"Execution time: {execution_time} ns in file {filename}")
            return execution_time
        else:
            print(f"Couldn't find both entry point @main and exit point @exit in file {filename}.")

# file path
config_filename = './m5out_public/config.json'
exec_file_path = "./m5out_public/out_exec_{}.txt"
exec_file_index = [5]

# cache size
json_data = read_json_file(config_filename)
cache_sizes, associativity = extract_cache_sizes(json_data)

if cache_sizes['l2'] == 'Not found':
    cache_sizes['l2'] = 0

print(f"{Fore.GREEN}L1DCache Size: {cache_sizes['l1d']}{Style.RESET_ALL}")
print(f"{Fore.GREEN}L1ICache Size: {cache_sizes['l1i']}{Style.RESET_ALL}")
print(f"{Fore.GREEN}L2Cache Size: {cache_sizes['l2']}{Style.RESET_ALL}")

# execution time
execution_time = {}
for index in exec_file_index:
    filename = exec_file_path.format(index)
    if os.path.exists(filename):
        execution_time[f'p{index}'] = calculate_execution_time(filename)
        print(f"{Fore.GREEN}Test Case {index} Execution Time: {execution_time[f'p{index}']} ns{Style.RESET_ALL}")
    else:
        print(f"{Fore.RED}File {filename} does not exist.{Style.RESET_ALL}")


# score formula
if cache_sizes['l2'] == 0:
    score = sum(execution_time.values()) * (math.log2(cache_sizes['l1d']) + math.log2(cache_sizes['l1i']))
else:
    score = sum(execution_time.values()) * (math.log2(cache_sizes['l1d']) + math.log2(cache_sizes['l1i']) + math.log2(cache_sizes['l2']) * 0.5)
print(f"{Fore.GREEN}Score: {score}{Style.RESET_ALL}")
