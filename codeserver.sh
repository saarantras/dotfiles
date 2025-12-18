#!/bin/bash

#SBATCH --partition=devel
#SBATCH -t 6:00:00
#SBATCH -c 1
#SBATCH --mem=10G
#SBATCH --output=vscode_slurm.txt

# vscode_slurm.sh

# Usage:
# sbatch vscode_slurm.sh

# After this script successfully starts running, use the last line of the
# logfile 'vscode_slurm.txt' (in the directory you submitted the job from)
# to set up a connection from the cluster to your own VSCode app on a remote computer.
# An example last line will look like:

######################
# vscode_slurm.txt
######################
# ...
# To grant access to the server, please log into https://github.com/login/device and use code ​XXXX-XXXX
######################

module load VSCode
code tunnel
