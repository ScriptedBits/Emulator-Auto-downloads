import json
import math
import re
from datetime import datetime

# Load emulator data from emulators.json
with open("emulators.json", "r") as f:
    emulators = json.load(f)

# Sort the emulators alphabetically by name
emulators = sorted(emulators, key=lambda x: x["emulator"].lower())

# Split emulators into two columns for the table
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

# Add a timestamp to force changes (optional)
timestamp = f"<!-- Updated at {datetime.now()} -->"

# Load the existing README.md
with open("README.md", "r") as f:
    readme_content = f.read()

# Use a regex to replace the "Currently Supported Emulators" section
updated_readme = re.sub(
    r"(## Currently Supported Emulators: ##\n\n\|.*?\|\n)",
    f"## Currently Supported Emulators: ##\n\n{new_table}\n{timestamp}",
    readme_content,
    flags=re.DOTALL
)

# Write the updated content back to README.md
with open("README.md", "w") as f:
    f.write(updated_readme)

print("README.md updated successfully.")
