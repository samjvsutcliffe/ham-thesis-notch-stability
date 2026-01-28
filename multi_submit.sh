#!/bin/bash
#export OMP_PROC_BIND=spread,close
#export BLIS_NUM_THREADS=1
read -p "Do you want to clear previous data? (y/n)" yn
case $yn in
    [yY] ) echo "Removing data";rm -r /nobackup/rmvn14/thesis/notch-stability/output-*; rm -r data-cliff-stability; break;;
    [nN] ) break;;
esac
set -e
module load aocc/5.0.0
module load aocl/5.0.0
sbcl --dynamic-space-size 16000 --load "build.lisp" --quit

export REFINE=0.25
export HEIGHT=600
#export FLOATATION=0.95
#export NOTCH_RATIO=1
#for f in 1.0 0.95 0.9 0.85 0.8
#do
#    export FLOATATION=$f
#    sbatch batch_cliff_stab.sh
#done

export FLOATATION=0.95
for f in 1.0 0.75 0.5 0.25 0
do
    export NOTCH_RATIO=$f
    sbatch batch_cliff_stab.sh
done

#export HEIGHT=450
#export FLOATATION=0.9
#sbatch batch_cliff_stab.sh

#export FLOATATION=0.8
#sbatch batch_cliff_stab.sh
#export HEIGHT=600
#export FLOATATION=0.95
#sbatch batch_cliff_stab.sh
#export FLOATATION=0.9
#sbatch batch_cliff_stab.sh

#export HEIGHT=850
#export FLOATATION=1.0
#sbatch batch_cliff_stab.sh
