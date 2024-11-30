import json
import math
import re
from datetime import datetime

# File paths
EMULATORS_JSON_PATH = "emulators.json"
README_PATH = "README.md"

# Load emulator data
with open(EMULATORS_JSON_PATH, "r") as f:
    emulators = json.load(f)

# Sort emulators alphabetically
emulators = sorted(emulators, key=lambda x: x["emulator"].lower())

# Split emulators into two columns for table
midpoint = math.ceil(len(emulators) / 2)
column1 = emulators[:midpoint]
column2 = emulators[midpoint:]

# Generate the new table format
new_table = "| **Emulator**           | **System**          | --- | **Emulator**           | **System**          |\n"
new_table += "|------------------------|---------------------|-----|------------------------|---------------------|\n"

for col1, col2 in zip(column1, column2):
    col1_text = f"**{col1['emulator']}** | {col1['system']}"
    col2_text = f"**{col2['emulator']}** | {col2['system']}" if col2 else ""
    new_table += f"| {col1_text:<23} | {col2_text:<23} |\n"

# Add a timestamp for debugging purposes
timestamp = f"<!-- Updated at {datetime.now()} -->"

# Load README.md
with open(README_PATH, "r") as f:
    readme_content = f.read()

# Regex to find the "Currently Supported Emulators" section
regex_pattern = r"(## Currently Supported Emulators: ##\n\n.*?)(?=\n##|$)"
new_emulators_section = f"## Currently Supported Emulators: ##\n\n{new_table}\n{timestamp}"

# Replace the section in README.md
updated_readme = re.sub(regex_pattern, new_emulators_section, readme_content, flags=re.DOTALL)

# Check if changes were made
if updated_readme != readme_content:
    # Write the updated content back to README.md
    with open(README_PATH, "w") as f:
        f.write(updated_readme)
    print("README.md updated successfully.")
else:
    print("No changes detected in README.md.")
