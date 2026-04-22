import pandas as pd
import matplotlib.pyplot as plt

# --- 1. Data Setup ---
# Including all 9 data points for each sample
raw_data = {
    'Stringency': [2, 3, 4, 5, 6, 7, 8, 9, 10],
    'TIL11': [0.2321, 0.2191, 0.2048, 0.1849, 0.1662, 0.1534, 0.1381, 0.1247, 0.1156],
    'TM': [0.4052, 0.3905, 0.3678, 0.3436, 0.3095, 0.2897, 0.2721, 0.2569, 0.2436],
    'B104_R1': [0.5424, 0.5372, 0.5292, 0.5140, 0.5031, 0.4920, 0.4811, 0.4651, 0.4549],
    'B104_R2': [0.6721, 0.6663, 0.6601, 0.6489, 0.6410, 0.6292, 0.6212, 0.6093, 0.6014]
}
df = pd.DataFrame(raw_data)

# Prepare the full table by transposing the dataframe
# Samples will be rows, Stringency levels (2-10) will be columns
table_df = df.set_index('Stringency').T

# --- 2. Create Figure with Subplots ---
# Adjusted figsize to (14, 10) to make room for the wider table
fig, (ax_plot, ax_table) = plt.subplots(2, 1, figsize=(14, 10), gridspec_kw={'height_ratios': [1.5, 1]})

# --- 3. The Sensitivity Plot ---
ax_plot.plot(df['Stringency'], df['B104_R2'], 'o-', label='Maize B104 (Rep 2)', color='#004d40', linewidth=2.5)
ax_plot.plot(df['Stringency'], df['B104_R1'], 'o-', label='Maize B104 (Rep 1)', color='#00897b', linewidth=2.5)
ax_plot.plot(df['Stringency'], df['TM'], 's--', label='Teosinte (TM)', color='#d81b60', linewidth=2)
ax_plot.plot(df['Stringency'], df['TIL11'], 's--', label='Teosinte (TIL11)', color='#8e24aa', linewidth=2)

ax_plot.set_title('ATAC-seq Library Quality: FRiP vs. Peak Stringency', fontsize=16, weight='bold', pad=20)
ax_plot.set_ylabel('FRiP Score', fontsize=13)
ax_plot.set_xlabel('Stringency Threshold (Coverage)', fontsize=13)
ax_plot.legend(loc='upper right', frameon=False, fontsize=11)
ax_plot.grid(axis='y', linestyle=':', alpha=0.6)
ax_plot.set_ylim(0, 0.8)

# --- 4. The Full Data Table ---
ax_table.axis('off')
# Use the full transposed dataframe (9 columns of data)
table = ax_table.table(cellText=table_df.values.round(3), 
                       rowLabels=table_df.index, 
                       colLabels=[f"Str {s}" for s in df['Stringency']], 
                       loc='center', 
                       cellLoc='center')

table.auto_set_font_size(False)
table.set_fontsize(10)
table.scale(1.0, 3.0) # Scaled vertically for better readability on a slide

# Style headers: Bold and Light Gray background
for (row, col), cell in table.get_celld().items():
    if row == 0 or col == -1:
        cell.set_text_props(weight='bold')
        cell.set_facecolor('#f2f2f2')

plt.tight_layout()
plt.savefig("frip_full_summary.svg", format='svg', bbox_inches='tight')
print("Successfully generated: frip_full_summary.svg")