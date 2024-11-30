import json
import math
import re

# Load emulator data
with open("emulators.json", "r") as f:
    emulators = json.load(f)

# Sort the emulators alphabetically by name
emulators = sorted(emulators, key=lambda x: x["emulator"].lower())

# Split emulators into two columns
midpoint = math.ceil(len(emulators) / 2)
column1 = emulators[:midpoint]
column2 = emulators[midpoint:]

# Generate table format
new_table = "| **Emulator**           | **System**          | --- | **Emulator**           | **System**          |\n"
new_table += "|------------------------|---------------------|-----|------------------------|---------------------|\n"

# Add rows to the table
for col1, col2 in zip(column1, column2):
    col1_text = f"**{col1['emulator']}** | {col1['system']}"
    col2_text = f"**{col2['emulator']}** | {col2['system']}" if col2 else ""
    new_table += f"| {col1_text:<23} | {col2_text:<23} |\n"

# Load existing README.md
with open("README.md", "r") as f:
    readme_content = f.read()

# Update the "Currently Supported Emulators" section
updated_readme = re.sub(
    r"(## Currently Supported Emulators: ##\n\n\|.*?\|\n)",  # Regex to match the table
    f"## Currently Supported Emulators: ##\n\n{new_table}",
    readme_content,
    flags=re.DOTALL
)

# Write updated README.md
with open("README.md", "w") as f:
    f.write(updated_readme)

# print("Supported emulators table updated successfully.")
