import os
import argparse
import numpy as np
import mdtraj

def reimage_traj(trajectory, pdbtopology, format='DCD', unitcell_lengths=None, unitcell_angles=None):
    traj_basename = os.path.splitext(trajectory)[0]
    #Trajectory basename
    traj_basename = os.path.splitext(trajectory)[0]
    #PDB-file basename
    pdb_basename = os.path.splitext(pdbtopology)[0]

    # Load trajectory
    print("Loading trajectory using mdtraj.")
    traj = mdtraj.load(trajectory, top=pdbtopology)

    numframes = len(traj._time)
    print("Found {} frames in trajectory.".format(numframes))
    print("PBC information in trajectory:")
    print("Unitcell lengths:", traj.unitcell_lengths[0])
    print("Unitcell angles", traj.unitcell_angles[0])
    
    # If PBC information is missing from traj file (OpenMM: Charmmfiles, Amberfiles option etc) then provide this info
    if unitcell_lengths is not None:
        print("unitcell_lengths info provided by user.")
        unitcell_lengths_nm = [i / 10 for i in unitcell_lengths]
        traj.unitcell_lengths = np.array(unitcell_lengths_nm * numframes).reshape(numframes, 3)
        traj.unitcell_angles = np.array(unitcell_angles * numframes).reshape(numframes, 3)
    # else:
    #    print("Missing PBC info. This can be provided by unitcell_lengths and unitcell_angles keywords")

    imaged = traj.image_molecules()
    
    # Save trajectory in format
    if format == 'DCD':
        imaged.save(traj_basename + '_reimaged.dcd')
        print("Saved reimaged trajectory:", traj_basename + '_reimaged.dcd')
    elif format == 'PDB':
        imaged.save(traj_basename + '_reimaged.pdb')
        print("Saved reimaged trajectory:", traj_basename + '_reimaged.pdb')
    else:
        print("Unknown trajectory format.")
    
    return None
    

def main():
    parser = argparse.ArgumentParser(description='Reimage trajectory.')
    parser.add_argument('trajectory', type=str, help='Path to the trajectory file.')
    parser.add_argument('pdbtopology', type=str, help='Path to the PDB topology file.')
    parser.add_argument('--format', type=str, default='DCD', help='Format of the trajectory file.')
    parser.add_argument('--unitcell_lengths', type=float, nargs=3, help='Unit cell lengths.')
    parser.add_argument('--unitcell_angles', type=float, nargs=3, help='Unit cell angles.')

    args = parser.parse_args()

    reimage_traj(args.trajectory, args.pdbtopology, args.format, args.unitcell_lengths, args.unitcell_angles)

if __name__ == '__main__':
    main()
