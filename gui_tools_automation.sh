#!/bin/bash

# Function to prompt for directory inputs
prompt_for_inputs() {
    data=$(zenity --file-selection --directory --title="Select Data Directory")
    if [ -z "$data" ]; then
        zenity --error --text="No data directory selected"
        exit 1
    fi

if [[ "$1" == "Denovo" && "$2" == "VSEARCH" ]] ||  [ "$2" == "Bellerophon" ] || [ "$2" == "Perseus" ] || [[ "$2" == "UCHIME" && ( "$1" == "Reference-Based" || "$1" == "Denovo" ) ]] || [[ "$2" == "ChimeraSlayer" && ( "$1" == "Reference-Based" || "$1" == "Denovo" ) ]] ; then
						 
    mothur_location=$(zenity --file-selection --title="Select MOTHUR Executable")
    if [ -z "$mothur_location" ]; then
        zenity --error --text="No additional reference directory selected"
        exit 1
    fi

elif [[ "$1" == "Reference-Based" && "$2" == "VSEARCH" ]]; then  # Ensure consistency in case
    vsearch_executable=$(zenity --file-selection --title="Select VSEARCH Executable")
    echo "$vsearch_executable"
    if [ -z "$vsearch_executable" ]; then
        zenity --error --text="No VSEARCH executable selected"
        exit 1
    fi

    chmod +x "$vsearch_executable"  # Ensure the VSEARCH file is executable

else  # If $2 matches any of the uchime tools, prompt for the usearch executable
    additional_reference=$(zenity --file-selection --title="Select usearch Executable")
    echo "$additional_reference"
    if [ -z "$additional_reference" ]; then
        zenity --error --text="No usearch executable selected"
        exit 1
    fi

    chmod +x "$additional_reference"  # Ensure the usearch file is executable
fi

	if [[ "$1" == "Reference-Based" || ( "$1" == "Denovo" && ( "$2" == "ChimeraSlayer" || "$2" == "Bellerophon" ) ) ]]; then

		reference_location=$(zenity --file-selection --title="Select Reference File")
		if [ -z "$reference_location" ]; then
		    zenity --error --text="No reference file selected"
		    exit 1
		fi

	fi
}

# Function to show tools based on choice
show_tools() {
    choice=$1
    method=$2

    if [ "$choice" == "18S" ]; then
        if [ "$method" == "Reference-Based" ]; then
            tools=("ChimeraSlayer" "VSEARCH" "UCHIME2_Balanced" "UCHIME2_HighConfidence" "UCHIME2_Senstive" "UCHIME2_Specific" "UCHIME2_Denoised" "UCHIME")
        else
            tools=("Perseus" "Bellerophon" "ChimeraSlayer" "VSEARCH" "UCHIME3" "UCHIME")
        fi
    elif [ "$choice" == "16S" ]; then
        if [ "$method" == "Reference-Based" ]; then
            tools=("ChimeraSlayer" "VSEARCH" "UCHIME2_Balanced" "UCHIME2_HighConfidence" "UCHIME2_Senstive" "UCHIME2_Specific" "UCHIME2_Denoised" "UCHIME")
        else
            tools=("Perseus" "Bellerophon" "ChimeraSlayer" "VSEARCH" "UCHIME3" "UCHIME")
        fi
    fi

    selected_tool=$(zenity --list --title="Select Tool" --column="Tools" "${tools[@]}")
    if [ "$selected_tool" ]; then
        
        prompt_for_inputs "$method" "$selected_tool"
        run_tool "$selected_tool" "$method" "$data" "$mothur_location" "$reference_location" "$additional_reference" "$vsearch_executable"
    else
        zenity --error --text="No tool selected"
    fi
}

#for uchime3 input
modify_fasta_headers() {
    dir="$1"
    output_dir="$2"
    mkdir -p "$output_dir"

    for count_file in "$dir"/sample_*.count_table; do
        mock_number=$(basename "$count_file" | grep -oP '(?<=sample_)\d+(?=.count_table)')
        fasta_file="$dir/sample_${mock_number}.fasta"
        output_file="$output_dir/modified_sample_${mock_number}.fasta"

        declare -A abundances
        while read -r id count; do
            abundances["$id"]=$count
        done < <(awk 'NR>1 {print $1, $2}' "$count_file")

        header_seq_pairs=()
        
        header=""
        seq=""

        while IFS= read -r line; do
            line=$(echo "$line" | tr -d '\r' | sed 's/^[ \t]*//;s/[ \t]*$//')  # Remove spaces and carriage returns
            if [[ $line == ">"* ]]; then
                if [[ -n $header && -n $seq ]]; then
                    size=$(echo "$header" | grep -oP '(?<=size=)\d+')
                    header_seq_pairs+=("$size|$header|$seq")
                fi
                id="${line#>}"
                abundance=${abundances[$id]:-1}
                header=">${id};size=${abundance};"
                seq=""
            else
                seq+="$line"
            fi
        done < "$fasta_file"

        # Store last sequence
        if [[ -n $header && -n $seq ]]; then
            size=$(echo "$header" | grep -oP '(?<=size=)\d+')
            header_seq_pairs+=("$size|$header|$seq")
        fi

        # Sort by size numerically in **descending order**
        IFS=$'\n' sorted_output=($(sort -nr <<<"${header_seq_pairs[*]}"))
        unset IFS

        # Write sorted output
        {
            for entry in "${sorted_output[@]}"; do
                header=$(echo "$entry" | cut -d'|' -f2)
                seq=$(echo "$entry" | cut -d'|' -f3)
                echo "$header"
                echo "$seq"
            done
        } > "$output_file"
    done
}


# Function stubs for each tool and method
run_slayer_reference()
{
    data=$1
    mothur_location=$2
    reference_location=$3
    output_directory="${data}/${choice}_slayer_ref_output"
    

    mkdir -p "$output_directory"

    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
	mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
	
        # Perform the align.seqs command
        align_output="$output_directory/sample_${mock_number}.align"
        align_command="$mothur_location \"#set.dir(output=$output_directory); align.seqs(fasta=$fasta_file, reference=$reference_location)\""
        echo "$fasta_file" | eval "$align_command"
        
        chimera_command="$mothur_location \"#set.dir(output=$output_directory); chimera.slayer(fasta=$align_output, reference=$reference_location)\""
        echo "$align_output" | eval "$chimera_command"
    done
}

run_slayer_denovo()
{
    data=$1
    mothur_location=$2
    reference_location=$3
    output_directory="${data}/${choice}_slayer_denovo_output"
    

    mkdir -p "$output_directory"

    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
	mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
	
        # Perform the align.seqs command
        align_output="$output_directory/sample_${mock_number}.align"
        align_command="$mothur_location \"#set.dir(output=$output_directory); align.seqs(fasta=$fasta_file, reference=$reference_location)\""
        echo "$fasta_file" | eval "$align_command"
        count_table="$data/sample_${mock_number}.count_table"
        chimera_command="$mothur_location \"#set.dir(output=$output_directory); chimera.slayer(fasta=$align_output, count=$count_table, reference=self)\""
        echo "$align_output" | eval "$chimera_command"
    done
    
    for file in ${data}/*_R1_001.fasta ${data}/*_R1_001.count_table; do
    [ -e "$file" ] && rm -f "$file"
    done

}

run_vsearch_denovo()
{
    data=$1
    mothur_location=$2
    reference_location=$3
    output_directory="${data}/${choice}_vsearch_denovo_output"
    

    mkdir -p "$output_directory"

    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
	mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
	
        count_table="$data/sample_${mock_number}.count_table"
        chimera_command="$mothur_location \"#set.dir(output=$output_directory); chimera.vsearch(fasta=$fasta_file, count=$count_table, dereplicate=t)\""
        echo "$align_output" | eval "$chimera_command"
    done
    
    for file in ${data}/*_R1_001.fasta ${data}/*_R1_001.count_table; do
    [ -e "$file" ] && rm -f "$file"
    done
}

run_vsearch_reference()
{
	data=$1
	vsearch_executable=$2
	reference_location=$3
	
	final_output="${data}/${choice}_vsearch_ref_output"
	mkdir -p "$final_output"
#el reference.fasta
	# Loop over mock fasta files
	for fasta_file in "$data"/sample_*.fasta; do
	mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
	chimera_command="$vsearch_executable --uchime_ref $fasta_file --db $reference_location --chimeras $final_output/vsearch_sample_$mock_number.fasta"
	echo "$align_output" | eval "$chimera_command"
	done
}

run_bellerophon() {
    data=$1
    mothur_location=$2
    reference_location=$3
    output_directory="${data}/${choice}_bellerophon_output"
    

    mkdir -p "$output_directory"

    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
	mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
	
        # Perform the align.seqs command
        align_output="$output_directory/sample_${mock_number}.align"
        align_command="$mothur_location \"#set.dir(output=$output_directory); align.seqs(fasta=$fasta_file, reference=$reference_location)\""
        echo "$fasta_file" | eval "$align_command"
        
        chimera_command="$mothur_location \"#set.dir(output=$output_directory); chimera.bellerophon(fasta=$align_output)\""
        echo "$align_output" | eval "$chimera_command"
    done

}

run_perseus()
{
    data=$1
    mothur_location=$2
    final_output="${data}/${choice}_perseus_output"
    mkdir -p "$final_output"

    for fasta_file in "$data"/sample_*.fasta; do
        # Extract the mock number from the file name
        mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')

        # Perform the chimera.slayer command
        count_table="$data/sample_${mock_number}.count_table"
        chimera_command="$mothur_location \"#set.dir(output=$final_output); chimera.perseus(fasta=$fasta_file, count=$count_table)\""
        eval "$chimera_command"

    done
    
    for file in ${data}/*_R1_001.fasta ${data}/*_R1_001.count_table; do
    [ -e "$file" ] && rm -f "$file"
    done
}

run_uchime1_denovo()
{
    data=$1
    mothur_location=$2
    final_output="${data}/${choice}_uchime1_output"
    mkdir -p "$final_output"

    for fasta_file in "$data"/sample_*.fasta; do
        # Extract the mock number from the file name
        mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')

        # Perform the chimera.slayer command
        count_table="$data/sample_${mock_number}.count_table"
        chimera_command="$mothur_location \"#set.dir(output=$final_output); chimera.uchime(fasta=$fasta_file, count=$count_table)\""
        eval "$chimera_command"
    done
   
    for file in ${data}/*_R1_001.fasta ${data}/*_R1_001.count_table; do
    [ -e "$file" ] && rm -f "$file"
    done

}


run_uchime1_ref()
{
    data=$1
    mothur_location=$2
    reference_location=$3
    final_output="${data}/${choice}_uchime1_ref_output"

    mkdir -p "$final_output"

    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
        # Extract the mock number from the file name
        mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
        
        chimera_command="$mothur_location \"#set.dir(output=$final_output); chimera.uchime(fasta=$fasta_file, reference=$reference_location)\""
        echo "$align_output" | eval "$chimera_command"
    done
}

run_uchime2_sens(){
    data=$1
    usearch_location=$2
    reference_location=$3
    output_directory="${data}/${choice}_uchime2_sens_ref_align_output"
    
    mkdir -p "$output_directory"
    align_output="$output_directory/db.udb"
    align_command="$usearch_location -makeudb_usearch $reference_location -output $align_output"
    echo "$fasta_file" | eval "$align_command"
    
    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
    mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
        chimera_command="$usearch_location -uchime2_ref $fasta_file -db $align_output -uchimeout $output_directory/out_$mock_number.txt -strand plus -mode sensitive"
        
        echo "$align_output" | eval "$chimera_command"
    done
}

run_uchime2_high_conf(){
    data=$1
    usearch_location=$2
    reference_location=$3
    output_directory="${data}/${choice}_uchime2_high_conf_ref_align_output"
    mkdir -p "$output_directory"
    align_output="$output_directory/db.udb"
    align_command="$usearch_location -makeudb_usearch $reference_location -output $align_output"
    echo "$fasta_file" | eval "$align_command"
    
    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
    mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
        chimera_command="$usearch_location -uchime2_ref $fasta_file -db $align_output -uchimeout $output_directory/out_$mock_number.txt -strand plus -mode high_confidence"
        
        echo "$align_output" | eval "$chimera_command"
    done
}

run_uchime2_spec(){
    data=$1
    usearch_location=$2
    reference_location=$3
    output_directory="${data}/${choice}_uchime2_spec_ref_align_output"
    
    mkdir -p "$output_directory"
    align_output="$output_directory/db.udb"
    align_command="$usearch_location -makeudb_usearch $reference_location -output $align_output"
    echo "$fasta_file" | eval "$align_command"
    
    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
    mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
        chimera_command="$usearch_location -uchime2_ref $fasta_file -db $align_output -uchimeout $output_directory/out_$mock_number.txt -strand plus -mode specific"
        
        echo "$align_output" | eval "$chimera_command"
    done
}
#.align
run_uchime2_balanced(){
    data=$1
    usearch_location=$2
    reference_location=$3
    output_directory="${data}/${choice}_uchime2_balanced_ref_align_output"
   

    mkdir -p "$output_directory"
    
    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
    mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
        chimera_command="$usearch_location -uchime2_ref $fasta_file -db $reference_location -uchimeout $output_directory/out_$mock_number.txt -strand plus -mode balanced"
        
        echo "$align_output" | eval "$chimera_command"
    done
}

#.align
run_uchime2_denoised(){
    data=$1
    usearch_location=$2
    reference_location=$3
    output_directory="${data}/${choice}_uchime2_denoised_ref_align_output"
    

    mkdir -p "$output_directory"
    
    # Loop over mock fasta files
    for fasta_file in "$data"/sample_*.fasta; do
    mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')
        chimera_command="$usearch_location -uchime2_ref $fasta_file -db $reference_location -uchimeout $output_directory/out_$mock_number.txt -strand plus -mode denoised"
        
        echo "$align_output" | eval "$chimera_command"
    done
}

run_uchime3()
{
    data=$1
    usearch_location=$2
    final_output="${data}/${choice}_uchime3_output"
    
    mkdir -p "$final_output"

    for fasta_file in "$data"/sample_*.fasta; do
        modify_fasta_headers "$data" "$final_output"
        # Extract the mock number from the file name
        mock_number=$(basename "$fasta_file" | grep -oP '(?<=sample_)\d+(?=.fasta)')

        input_file="$final_output/modified_sample_$mock_number.fasta"

        chimera_command="$usearch_location -uchime3_denovo $input_file -uchimeout $final_output/out_$mock_number.txt -chimeras ch.fa -nonchimeras nonch.fa"

        eval "$chimera_command"
    done
}



# Function to run the selected tool
run_tool()
{
    tool=$1
    method=$2
    data=$3
    mothur_location=$4
    reference_location=$5
    usearch_location=$6
    vsearch_executable=$7

    case $tool in
        ChimeraSlayer)
            if [ "$method" == "Reference-Based" ]; then
                run_slayer_reference "$data" "$mothur_location" "$reference_location"
            else
                run_slayer_denovo "$data" "$mothur_location" "$reference_location"
            fi
            ;;     
        VSEARCH)
            if [ "$method" == "Reference-Based" ]; then
                run_vsearch_reference "$data" "$vsearch_executable" "$reference_location"
            else
                run_vsearch_denovo "$data" "$mothur_location"
            fi
            ;;
        UCHIME)
            if [ "$method" == "Reference-Based" ]; then
                run_uchime1_ref "$data" "$mothur_location" "$reference_location"
            else
                run_uchime1_denovo "$data" "$mothur_location"
            fi
            ;;
        UCHIME3)
                run_uchime3 "$data" "$usearch_location"
            ;;
        UCHIME2_Balanced)
                run_uchime2_balanced "$data" "$usearch_location" "$reference_location"
            ;;
        UCHIME2_HighConfidence)
                run_uchime2_high_conf "$data" "$usearch_location" "$reference_location"
            ;;
        UCHIME2_Senstive)
                run_uchime2_sens "$data" "$usearch_location" "$reference_location"
            ;;
        UCHIME2_Specific)
                run_uchime2_spec "$data" "$usearch_location" "$reference_location"
            ;;
        UCHIME2_Denoised)
                run_uchime2_denoised "$data" "$usearch_location" "$reference_location"
            ;;
        Bellerophon)
            run_bellerophon "$data" "$mothur_location" "$reference_location"
            ;;
        Perseus)
            run_perseus "$data" "$mothur_location"
            ;;
        *)
            zenity --error --text="Invalid tool selected"
            ;;
    esac
}

# Main script
choice=$(zenity --list --title="Select Choice" --column="Choice" "18S" "16S")

if [ "$choice" ]; then
    
    method=$(zenity --list --title="Select Method" --column="Method" "Reference-Based" "Denovo")
    if [ "$method" ]; then
        
        show_tools "$choice" "$method"
    else
        zenity --error --text="No method selected"
    fi
else
    zenity --error --text="No choice selected"
fi

