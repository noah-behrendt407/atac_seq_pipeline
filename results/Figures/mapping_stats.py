import pandas as pd
import matplotlib.pyplot as plt

# The data you provided
data = [
    ["TIL11_TB_S3", 299180352, 296098780, 89480894],
    ["TM_Tiller_bud_R1_S49", 575283548, 564508262, 358483976],
    ["B104WT1_AM_S14", 236269392, 234737012, 91330242],
    ["B104WT2_AM_S16", 263952276, 262623118, 109869608]
]

columns = ["Sample", "Total Sequences", "Mapped & Paired", "MQ0 Reads"]
df = pd.DataFrame(data, columns=columns)

# Calculate rates
df["Mapping Rate (%)"] = (df["Mapped & Paired"] / df["Total Sequences"] * 100).round(2)
df["MQ0 Rate (%)"] = (df["MQ0 Reads"] / df["Mapped & Paired"] * 100).round(2)

# Format large numbers with commas for the table
df_display = df.copy()
for col in ["Total Sequences", "Mapped & Paired", "MQ0 Reads"]:
    df_display[col] = df_display[col].apply(lambda x: f"{x:,}")

# --- KEY FIX 1: Increase Figure Height to (12, 6) ---
fig, ax = plt.subplots(figsize=(12, 6))
ax.axis('off')

# Render the table
table = ax.table(cellText=df_display.values, 
                 colLabels=df_display.columns, 
                 loc='center', 
                 cellLoc='center')

# Styling
table.auto_set_font_size(False)
table.set_fontsize(11)
table.scale(1.2, 3.0) # Increased vertical scale for cleaner rows

# Bold the header row
for (row, col), cell in table.get_celld().items():
    if row == 0:
        cell.set_text_props(weight='bold')
        cell.set_facecolor('#E6E6E6')

# --- KEY FIX 2: Use set_title with a 'y' coordinate to push it up ---
ax.set_title("Whole-Genome Mapping and Alignment Quality Summary", 
             weight='bold', 
             fontsize=16, 
             pad=40, 
             y=0.9)

# Save as SVG
plt.savefig("mapping_stats_table.svg", format='svg', bbox_inches='tight')
print("Successfully generated: mapping_stats_table.svg with title")