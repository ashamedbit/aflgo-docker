import re
from collections import defaultdict

# Function to insert printf statements into the corresponding files
def insert_printf(warning_file, base_dir):
    with open(warning_file, 'r') as f:
        warnings = f.readlines()

    # Group warnings by file
    warnings_by_file = defaultdict(list)
    for warning in warnings:
        # Parse the file path and line number from the warning
        match = re.match(r"(.*):(\d+)", warning.strip())
        if not match:
            print(f"Skipping invalid warning: {warning}")
            continue

        file_path, line_number = match.groups()
        warnings_by_file[file_path].append(int(line_number))

    for file_path, line_numbers in warnings_by_file.items():
        full_path = f"{base_dir}/{file_path}"

        try:
            # Read the file content
            with open(full_path, 'r') as source_file:
                lines = source_file.readlines()

            # Sort line numbers in descending order to avoid shifting issues
            line_numbers = sorted(line_numbers, reverse=True)
            for line_number in line_numbers:
                # Check if the line starts with a function definition and contains '{'
                if "{" in lines[line_number - 1]:
                    # Add printf after '{'
                    brace_index = lines[line_number - 1].find("{")
                    lines[line_number - 1] = (
                        lines[line_number - 1][: brace_index + 1]
                        + f' printf(" Reached {file_path}:{line_number}: SEGV\\n");'
                        + lines[line_number - 1][brace_index + 1 :]
                    )
                else:
                    # Insert the printf statement before the specified line
                    printf_statement = f'printf(" Reached {file_path}:{line_number}: SEGV\\n");\n'
                    lines.insert(line_number - 1, printf_statement)

            # Write the modified content back to the file
            with open(full_path, 'w') as source_file:
                source_file.writelines(lines)

            print(f"Inserted printf statements in {full_path}")
        except FileNotFoundError:
            print(f"File not found: {full_path}")
        except Exception as e:
            print(f"Error processing {full_path}: {e}")


# Example usage
# Replace 'warnings.txt' with the path to your warnings file
# Replace '/path/to/base/dir' with the base directory containing your source files

insert_printf('BBtargets-libxml.txt', './test/libxml2')
insert_printf('BBtargets-PROJ.txt', './test/PROJ')
insert_printf('BBtargets-zstd.txt', './test/zstd')
