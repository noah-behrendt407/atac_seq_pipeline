import pandas as pd
import matplotlib.pyplot as plt

# 1. Inputting the raw peak count data
data = {
    'Sample': ['TIL11_TB_S3', 'TM_Tiller_Bud', 'B104_WT1', 'B104_WT2'],
    '2x': [109004, 168083, 109061, 108224],
    '3x': [94520, 148393, 105556, 104077],
    '4x': [81176, 122206, 100678, 100020],
    '5x': [65185, 99601, 92237, 93572],
    '6x': [52629, 74583, 86917, 89582],
    '7x': [45205, 62138, 82016, 84320],
    '8x': [37486, 52399, 77679, 81133],
    '9x': [31268, 44730, 71816, 76842],
    '10x': [27369, 38655, 68404, 74090]
}

df = pd.DataFrame(data)

# Format numbers with commas for the visual table
df_display = df.copy()
for col in df.columns[1:]:
    df_display[col] = df_display[col].apply(lambda x: f"{x:,}")

# 2. Create the Figure
fig, ax = plt.subplots(figsize=(14, 3))
ax.axis('off')

# Render the table
table = ax.table(cellText=df_display.values, 
                 colLabels=df_display.columns, 
                 loc='center', 
                 cellLoc='center')

# 3. Styling
table.auto_set_font_size(False)
table.set_fontsize(10)
table.scale(1.1, 2.5) # Scale width and height

# Bold the headers and add the gray background
for (row, col), cell in table.get_celld().items():
    if row == 0:
        cell.set_text_props(weight='bold')
        cell.set_facecolor('#f0f0f0')
    if col == 0:
        cell.set_text_props(weight='bold')

plt.title('Peak Counts vs. Stringency Threshold (q-value < 0.1)', weight='bold', pad=20)

# 4. Save as SVG
plt.savefig("peak_counts_table.svg", format='svg', bbox_inches='tight')
print("Successfully generated: peak_counts_table.svg")