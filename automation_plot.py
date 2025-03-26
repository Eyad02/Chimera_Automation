import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


# Function to plot the data
def plot_data(df, title, filename, yaxis, tool_order):
    plt.figure(figsize=(10, 6))

    # Ensure column order
    df = df.set_index("Strata")[tool_order].reset_index()

    for col in tool_order:  
        if col in df.columns:  
            color = cb_colors.get(col, "#333333")  # Default to dark gray if missing
            plt.plot(df["Strata"], df[col], marker='o', label=col, linewidth=2, color=color)

    plt.xlabel("Strata", fontsize=14)
    plt.ylabel(yaxis, fontsize=14)
    plt.title(title, fontsize=16, weight='bold')
    plt.legend(loc='best', fontsize=12, frameon=True)
    plt.grid(True, linestyle='--', alpha=0.6)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

    plt.savefig(f"{filename}.png", dpi=400, bbox_inches="tight")
    plt.savefig(f"{filename}.svg", dpi=400, bbox_inches="tight")


# Function to plot boxplots
def plot_separate_boxplots(df, title, filename, tool_order):
    metrics = ['Accuracy', 'Sensitivity', 'Specificity']

    # Ensure consistent tool order
    df["Tool"] = pd.Categorical(df["Tool"], categories=tool_order, ordered=True)

    for metric in metrics:
        plt.figure(figsize=(8, 6))
        sns.boxplot(data=df, x='Tool', y=metric, palette=cb_colors, order=tool_order)

        plt.xlabel("Tool", fontsize=14)
        plt.ylabel(metric, fontsize=14)
        plt.title(title, fontsize=16, weight='bold')
        plt.xticks(rotation=45)
        plt.grid(True, linestyle='--', alpha=0.6)

        plt.savefig(f"{filename}_{metric.lower()}.png", dpi=400, bbox_inches="tight")
        plt.savefig(f"{filename}_{metric.lower()}.svg", dpi=400, bbox_inches="tight")
        plt.close()

# Define a fixed order for tools
denovo_tool_order = [
    "DADA2", "CATCh", "UCHIME3", "Perseus", 
    "Bellerophon", "UCHIME", "VSEARCH", "ChimeraSlayer"
]

ref_tool_order = [
    "UCHIME2-Specific", "UCHIME2-HighConfidence", "UCHIME2-Balanced",
    "UCHIME2-Denoised", "UCHIME2-Sensitive", "UCHIME", "VSEARCH",
    "ChimeraSlayer"
]

# Define a fixed colorblind-friendly color palette (Wong's palette)
cb_colors = {
    "UCHIME2-Specific": "#5E2D0C",      # Dark Chestnut
    "UCHIME2-HighConfidence": "#A04000", # Burnt Orange
    "UCHIME2-Balanced": "#E66100",      # Bright Orange
    "UCHIME2-Denoised": "#FF9500",      # Vivid Gold
    "UCHIME2-Sensitive": "#FFD700",     # Deep Yellow

    "UCHIME": "#1B4D89",      # Strong Blue (Unchanged)
    "VSEARCH": "#CC33FF",     # Bright Violet (Easier to distinguish)
    "ChimeraSlayer": "#0096C7", # Blue-Green (Replaces Strong Green)
    "DADA2": "#E69F00",       # Vibrant Orange (Unchanged, as it contrasts well)
    "CATCh": "#7570B3",       # Deep Purple (Unchanged)
    "UCHIME3": "#44AA99",     # Teal (Distinct from greens)
    "Perseus": "#882255",     # Dark Red-Violet (Unchanged, but could be darkened)
    "Bellerophon": "#EE3377"  # Strong Pink (More distinct from Perseus)
}


# Rename tools in dataframes
rename_dict = {
    "uchime2_spec": "UCHIME2-Specific",
    "uchime2_hc": "UCHIME2-HighConfidence",
    "uchime2_balanced": "UCHIME2-Balanced",
    "uchime2_denoised": "UCHIME2-Denoised",
    "uchime2_sensitive": "UCHIME2-Sensitive",
    "uchime": "UCHIME",
    "vsearch": "VSEARCH",
    "Slayer": "ChimeraSlayer",
    "dada2": "DADA2",
    "CATCh": "CATCh",
    "uchime3": "UCHIME3",
    "Perseus": "Perseus",
    "bellerophene": "Bellerophon"
}
x = ['pacbio', '16s', '18s']

for i in x: 
    reference_tools = pd.read_csv(f"/home/eyad/PLOTS_YA_GD3AN/{i}_div_box/{i}_ref_div.csv")  
    denovo_tools = pd.read_csv(f"/home/eyad/PLOTS_YA_GD3AN/{i}_div_box/{i}_denovo_div.csv")  
    ref_metrics_tools = pd.read_csv(f"/home/eyad/PLOTS_YA_GD3AN/{i}_div_box/{i}_ref_cm.csv")
    denovo_metrics_tools = pd.read_csv(f"/home/eyad/PLOTS_YA_GD3AN/{i}_div_box/{i}_denovo_cm.csv")

    reference_tools.rename(columns=rename_dict, inplace=True)
    denovo_tools.rename(columns=rename_dict, inplace=True)
    ref_metrics_tools["Tool"].replace(rename_dict, inplace=True)
    denovo_metrics_tools["Tool"].replace(rename_dict, inplace=True)

    # Ensure consistent column order for line plots
    reference_tools = reference_tools[["Strata"] + [t for t in ref_tool_order if t in reference_tools.columns]]
    denovo_tools = denovo_tools[["Strata"] + [t for t in denovo_tool_order if t in denovo_tools.columns]]

    # Ensure consistent tool order for boxplots
    ref_metrics_tools["Tool"] = pd.Categorical(ref_metrics_tools["Tool"], categories=ref_tool_order, ordered=True)
    denovo_metrics_tools["Tool"] = pd.Categorical(denovo_metrics_tools["Tool"], categories=denovo_tool_order, ordered=True)

    # Plot reference-based tools
    plot_data(reference_tools, "Performance of Reference-Based Tools", f"/home/eyad/PLOTS_YA_GD3AN/{i}_div_box/{i}_reference_based_plot", "Divergence", ref_tool_order)
    
    # Plot de novo-based tools
    plot_data(denovo_tools, "Performance of De Novo-Based Tools", f"/home/eyad/PLOTS_YA_GD3AN/{i}_div_box/{i}_denovo_based_plot", "Divergence", denovo_tool_order)
    
    # Plot boxplots
    plot_separate_boxplots(ref_metrics_tools, "Performance of Reference-Based Tools", f"/home/eyad/PLOTS_YA_GD3AN/{i}_div_box/{i}_ref_tools_boxplot", ref_tool_order)
    plot_separate_boxplots(denovo_metrics_tools, "Performance of De Novo-Based Tools", f"/home/eyad/PLOTS_YA_GD3AN/{i}_div_box/{i}_denovo_tools_boxplot", denovo_tool_order)


er_reference_tools = pd.read_csv(f"/home/eyad/PLOTS_YA_GD3AN/16s_div_box/16s_ref_er.csv")  
er_denovo_tools = pd.read_csv(f"/home/eyad/PLOTS_YA_GD3AN/16s_div_box/16s_denovo_er.csv")  

cr_reference_tools = pd.read_csv(f"/home/eyad/PLOTS_YA_GD3AN/16s_div_box/16s_ref_cr.csv")  
cr_denovo_tools = pd.read_csv(f"/home/eyad/PLOTS_YA_GD3AN/16s_div_box/16s_denovo_cr.csv")  

er_reference_tools.rename(columns=rename_dict, inplace=True)
er_denovo_tools.rename(columns=rename_dict, inplace=True)

cr_reference_tools.rename(columns=rename_dict, inplace=True)
cr_denovo_tools.rename(columns=rename_dict, inplace=True)


# Ensure consistent column order for line plots
er_reference_tools = er_reference_tools[["Strata"] + [t for t in ref_tool_order if t in er_reference_tools.columns]]
er_denovo_tools = er_denovo_tools[["Strata"] + [t for t in denovo_tool_order if t in er_denovo_tools.columns]]

# Ensure consistent column order for line plots
cr_reference_tools = cr_reference_tools[["Strata"] + [t for t in ref_tool_order if t in cr_reference_tools.columns]]
cr_denovo_tools = cr_denovo_tools[["Strata"] + [t for t in denovo_tool_order if t in cr_denovo_tools.columns]]


# Plot reference-based tools
plot_data(reference_tools, "Performance of Reference-Based Tools Error Rate", f"/home/eyad/PLOTS_YA_GD3AN/16s_div_box/er_cr/16s_reference_based_plot_er", "Error Rate", ref_tool_order)
# Plot de novo-based tools
plot_data(denovo_tools, "Performance of De Novo-Based Tools Error Rate", f"/home/eyad/PLOTS_YA_GD3AN/16s_div_box/er_cr/16s_denovo_based_plot_er", "Error Rate", denovo_tool_order)


# Plot reference-based tools
plot_data(reference_tools, "Performance of Reference-Based Tools", f"/home/eyad/PLOTS_YA_GD3AN/16s_div_box/er_cr/16s_ref_based_plot_cr", "Chimeric Range", ref_tool_order)
# Plot de novo-based tools
plot_data(denovo_tools, "Performance of De Novo-Based Tools", f"/home/eyad/PLOTS_YA_GD3AN/16s_div_box/er_cr/16s_denovo_based_plot_cr", "Chimeric Range", denovo_tool_order)
