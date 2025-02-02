#!/bin/bash

wait_step() {
  while [ ! -f $OUT_DIR/step${1}.done ]
  do
    sleep 10
  done
}

die() { echo "$@" 1>&2 ; exit 1; }

#Parameters:
#PYTHON= 
#CODE_DIR= 
#INPUT_TEXTS="/home/jdaiber1/compounds/plain_text/*.txt" 
#OUT_DIR="~/compounds/out_hu"
#STEP=1-4
#FUGENELEMENTE="" 

# Run: [PARAMETERS] bash train_splitter.sh
#
# The PYTHON bin must be accessible from every machine and must have all the required dependencies.
# Create a virtualenv with all the requirements for the training.
#  virtualenv --system-site-packages venv
#  venv/bin/python setup.py install

MIN_LENGTH=5
PROTOTYPE_JOBS=100
MIN_SUPPORT=10
FUGENELEMENTE=""

if [ -z "$STEP" ]; then
  STEP=1
fi

if ["$STEP" = "1" ]; then
  mkdir $OUT_DIR || die "OUT_DIR exists!"
fi

cd $CODE_DIR/jobs

#Step 1: Train w2v
if [ "$STEP" -le "1" ]; then
  qsub -v CODE_DIR="$CODE_DIR",OUT_DIR="$OUT_DIR",PYTHON="$PYTHON",INPUT_TEXTS="$INPUT_TEXTS" train_word2vec.sh
fi

wait_step 1

#Step 2: Extract candidates:
#python extract_candidates.py -w /home/jdaiber1/compounds/out/w2v.bin -b /home/jdaiber1/compounds/out/dawg -c /home/jdaiber1/compounds/out/candidates -o /home/jdaiber1/compounds/out/annoy_index -i /home/jdaiber1/compounds/out/candidates_index.p -l 5 -n 100 -f ""

if [ "$STEP" -le "2" ]; then
  qsub -v CODE_DIR="$CODE_DIR",OUT_DIR="$OUT_DIR",PYTHON="$PYTHON",MIN_LENGTH="$MIN_LENGTH",FUGENELEMENTE="$FUGENELEMENTE" extract_candidates.sh
fi

wait_step 2

#Step 3: Collect and filter candidates

if [ "$STEP" -le "3" ]; then
  $PYTHON training/filter_and_split_candidates.py $OUT_DIR/candidates_index.p $PROTOTYPE_JOBS $MIN_SUPPORT
fi

#Step 4: Extract prototypes
if [ "$STEP" -le "4" ]; then
  mkdir -p $OUT_DIR/prototypes/log/

  for i in {1..$PROTOTYPE_JOBS}
  do
   qsub -v INPUT="candidates_index.p.$i",OUTPUT="output$i",PYTHON="$PYTHON",CODE_DIR="$CODE_DIR",OUT_DIR="$OUT_DIR" find_dir_vectors.sh
  done
fi

