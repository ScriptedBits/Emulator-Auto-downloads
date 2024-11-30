import json
from datetime import datetime

# File paths
README_PATH = "README.md"
EMULATORS_JSON_PATH = "emulators.json"

# Function to update the README
def update_readme():
    # Load emulators data
    with open(EMULATORS_JSON_PATH, "r") as f:
        emulators = json.load(f)
    
    # Build the table rows
    rows = []
    for i in range(0, len(emulators), 2):
        emulator1 = emulators[i]
        emulator2 = emulators[i+1] if i + 1 < len(emulators) else {"name": "", "system": ""}
        row = f"| **{emulator1['name']}** | {emulator1['system']} |   | **{emulator2['name']}** | {emulator2['system']} |"
        rows.append(row)
    
    # Table header and separator
    header = "| **Emulator** | **System** |   | **Emulator** | **System** |"
    separator = "|--------------|------------|---|--------------|------------|"
    
    # Combine header, separator, and rows
    table = "\n".join([header, separator] + rows)
    
    # Update the README
    with open(README_PATH, "r") as f:
        readme = f.read()
    
    # Find and replace the section in README
    start_marker = "## Currently Supported Emulators: ##"
    end_marker = "<!-- Updated at"
    updated_at = f"<!-- Updated at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} -->"
    start_idx = readme.find(start_marker)
    end_idx = readme.find(end_marker)
    
    if start_idx != -1 and end_idx != -1:
        updated_readme = (
            readme[:start_idx + len(start_marker)] +
            "\n\n" + table + "\n\n" +
            updated_at +
            readme[end_idx + len(end_marker):]
        )
        
        with open(README_PATH, "w") as f:
            f.write(updated_readme)
        print("README.md updated successfully.")
    else:
        print("Could not find the 'Currently Supported Emulators' section in README.md.")

if __name__ == "__main__":
    update_readme()
