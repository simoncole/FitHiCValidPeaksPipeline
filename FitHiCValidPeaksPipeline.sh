#!/bin/bash

PAIRS_DIR=$1
RESOLUTION=$2
CHR_LENS=$3
OUTPUT_DIR=$4
NUM_PASSES=$5
PATH_TO_UTILS=$6

PATH_TO_PYTHON="python3"
PATH_TO_FITHIC="fithic"

#if the output dir doesn't exist, create it
if [ ! -d "$OUTPUT_DIR" ]
then
    mkdir $OUTPUT_DIR
fi

#First, generate the fragments file with the given parameters
"${PATH_TO_PYTHON}" "${PATH_TO_UTILS}/createFitHiCFragments-fixedsize.py" \
--chrLens "${CHR_LENS}" \
--outFile "${OUTPUT_DIR}/fragments.gz" \
--resolution ${RESOLUTION}
pairsFiles=()

#get each UNZIPPED pairs file
for file in $PAIRS_DIR/*;
do
    extension=${file##*.}
    if [ $extension == "pairs" ]
    then
        pairsFiles+=($file)
    fi
done

NUM_FILES=${#pairsFiles[@]}
fileCounter=1
for pairsFile in "${pairsFiles[@]}";
do
    BASE_FILE=${pairsFile%.*}
    START_LINE=$(awk '/^#columns/{print NR+1; exit}' "$pairsFile")

    echo "making contacts file for ${pairsFile}"
    "${PATH_TO_UTILS}/validPairs2FitHiC-fixedSizeUpdated.sh" \
    "$RESOLUTION" \
    "${BASE_FILE##*/}contacts" \
    <(tail -n +$START_LINE "$pairsFile") \
    "$OUTPUT_DIR"

    #run FitHiC on each
    echo -e "running FitHiC on ${pairsFile}, file #${fileCounter} of ${NUM_FILES}\n"
    fithic -f "${OUTPUT_DIR}/fragments.gz" \
    -i "${OUTPUT_DIR}/${BASE_FILE##*/}contacts_fithic.contactCounts.gz" \
    -o "$OUTPUT_DIR" \
    -r $RESOLUTION \
    -p $NUM_PASSES \
    -l "${BASE_FILE##*/}"

    ((filesFinished++))
done

