#!/bin/bash

prefix_list="seqtab_mock_4"
# mock5 mock12 mock13 mock15 mock18 mock21 mock22 mock23 mock19
output="/home/bioinformatics/Engy/Tools_installation/octopus/"

cd /home/bioinformatics/Engy/Tools_installation/octopus/

for prefix in $prefix_list
do
    fasta_file="$prefix.fasta"
    name="$prefix.names"
    slayer="$prefix.slayer.chimeras"
    perseus="$prefix.perseus.chimeras"
    uchime="$prefix.uchime.chimeras"
       
perl CATCh.pl _f $fasta_file _n $name _h $output _i "$prefix" _m d _p 12 _y $slayer _z $perseus _x $uchime 

done
