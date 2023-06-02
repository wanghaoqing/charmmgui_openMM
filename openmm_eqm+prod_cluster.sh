#!/bin/bash

# Slurm script generator

for i in {1..5}; do
    dir_name="run_$i"
    mkdir -p "$dir_name"

    # Generate the Slurm job script for this run
    cat << 'EOF' > "${dir_name}/slurm_job.sh"
#!/bin/bash

#SBATCH --job-name=openMM
#SBATCH --time=96:00:00
#SBATCH --partition=rondror

#SBATCH --tasks=1 --ntasks-per-socket=1 --gres=gpu:1
#SBATCH --constraint=GPU_MEM:24GB

#SBATCH --mail-type=FAIL
#SBATCH --mail-user=hwanagb@stanford.edu

# Output and error files
#SBATCH -o {{dir_name}}/run.out
#SBATCH -e {{dir_name}}/run.err

source ~/.bashrc
conda activate openMM

# Now we start the actual job.

init="step5_input"
equi_prefix="step6.%d_equilibration"
prod_prefix="step7_production"
prod_step="step7"

# The directory name is now hardcoded
dir_name="{{dir_name}}"

# Check latest equilibration file
latest_eq=$(ls -v ${dir_name}/step6.*_equilibration*.rst | tail -n 1)
if [[ $latest_eq ]]; then
    cnt=$(echo $latest_eq | grep -oP '(?<=step6\.).*(?=_equilibration)') 
    cnt=$((cnt + 1))
else
    cnt=1
fi

# Equilibration
    
while (( cnt <= 6 )); do
  pcnt=$((cnt - 1))
  istep=$(printf "${equi_prefix}" "${cnt}")
  pstep=$(printf "${equi_prefix}" "${pcnt}")
  input_param="-t toppar.str -p ${init}.psf -c ${init}.crd"
  if (( cnt == 1 )); then input_param="${input_param} -b sysinfo.dat"; fi
  if (( cnt != 1 )); then input_param="${input_param} -irst ${dir_name}/${pstep}.rst"; fi
  python -u openmm_run.py -i ${istep}.inp ${input_param} -orst ${dir_name}/${istep}.rst -odcd ${dir_name}/${istep}.dcd > ${dir_name}/${istep}.out
  cnt=$((cnt + 1))
done

# Check latest production file
latest_prod=$(ls -v ${dir_name}/${prod_step}_*.rst | tail -n 1)
if [[ $latest_prod ]]; then
	cnt=$(echo $latest_prod | grep -oP '(?<=step7_)\d+')
	cnt=$((cnt + 1))
else
	cnt=1
fi

# Production
    
cntmax=20
while (( cnt <= cntmax )); do
      pcnt=$((cnt - 1))
      istep=${prod_step}_${cnt}
      if (( cnt == 1 )); then pstep=$(printf "${equi_prefix}" 6); else pstep=${prod_step}_${pcnt}; fi
      input_param="-t toppar.str -p ${init}.psf -c ${init}.crd -irst ${dir_name}/${pstep}.rst"
      python -u openmm_run.py -i ${prod_prefix}.inp ${input_param} -orst ${dir_name}/${istep}.rst -odcd ${dir_name}/${istep}.dcd > ${dir_name}/${istep}.out
      cnt=$((cnt + 1))
done

EOF

    # Replace the placeholder with the actual directory name
    sed -i "s/{{dir_name}}/${dir_name}/g" "${dir_name}/slurm_job.sh"
done