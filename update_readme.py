import json
from datetime import datetime, timezone

def update_readme():
    # Load emulators.json
    with open("emulators.json", "r", encoding="utf-8") as f:
        emulators = json.load(f)

    # Sort emulators alphabetically by name
    sorted_emulators = sorted(emulators, key=lambda x: x["name"].lower())

    # Split emulators into two columns
    half = len(sorted_emulators) // 2 + (len(sorted_emulators) % 2)
    column1 = sorted_emulators[:half]
    column2 = sorted_emulators[half:]

    # Prepare table rows with an extra space for readability
    table_rows = [
        f"| **{col1['name']}** | {col1['system']}  |     | **{col2['name']}** | {col2['system']} |"
        for col1, col2 in zip(column1, column2)
    ]

    # If odd number of rows, add a final row for the remaining entry
    if len(column1) > len(column2):
        table_rows.append(f"| **{column1[-1]['name']}** | {column1[-1]['system']}  |     |  |  |")

    # Create the updated table content
    table_header = (
        "| **Emulator**           | **System**          | --- | **Emulator**           | **System**          |\n"
        "|------------------------|---------------------|-----|------------------------|---------------------|\n"
    )
    table_content = "\n".join(table_rows)
    # updated_table = f"## Currently Supported Emulators: ##\n\n{table_header}{table_content}\n<!-- Updated at {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')} -->"

    emulator_count = len(sorted_emulators)
    updated_table = f"## Currently Supported Emulators: {emulator_count} ##\n\n{table_header}{table_content}\n<!-- Updated at {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')} -->"

    
    # Load the existing README
    with open("README.md", "r", encoding="utf-8") as f:
        readme = f.read()

    # Locate the supported emulators section
    # start_marker = "## Currently Supported Emulators: ##"
    start_marker = "## Currently Supported Emulators:"
    end_marker = "<!-- Updated at"
    start_idx = readme.find(start_marker)
    end_idx = readme.find(end_marker)

    if start_idx == -1 or end_idx == -1:
        # If markers are not found, append the new table at the end
        readme += f"\n\n{updated_table}\n"
    else:
        # Update the section
        end_idx = readme.find("\n", end_idx)  # Find the end of the updated timestamp line
        readme = (
            readme[:start_idx]
            + updated_table
            + readme[end_idx:]
        )

    # Save the updated README
    with open("README.md", "w", encoding="utf-8") as f:
        f.write(readme)

    print("README.md updated successfully.")

if __name__ == "__main__":
    update_readme()
