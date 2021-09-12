# Directory structure

In case you are still getting familiarized with the `Git` workflow and/or [GitHub](https://help.github.com/en/github), it is recommended to go back to the basics using the command line. Go to the directory where you plan to store your source code and from the command line write:

```bash
git clone https://github.com/3dq5-2021/lab<number>-<your GitHub group>.git
```

If you are using GitHub Desktop you will get the link for the repo to be cloned when you click the `Clone or download` button while browsing your repo in GitHub. A folder with the same name as the repo from GitHub `lab<number>-<your GitHub group>` will be created. Do all the work in this folder, which is now under version control. After you have reached a relevant milestone in your work, perform the following:

```bash
git add -A
git commit -m "your message for this version"
```  
Finally, when you are ready to upload the changes to GitHub do:

```bash
git push
``` 

There are many arguments for `git push`, but normally you should not need them if you have cloned the repository from GitHub (because the master branch should automatically track the remote). In case the above workflow is not sufficient on your local machine, you will have to study the configuration of your `Git` client and decide which additional arguments to use to make sure that the repo is pushed back to ` https://github.com/3dq5-2021/lab<number>-<your GitHub group>.git`.
              
The `.gitignore` file from your assignment repo is already set up to accept only the source files relevant for the design, implementation and verification flow used in this course. Should you decide to modify this file (not advised!), the changes must be clearly documented and justified.

All the lab material released for this course will follow the following skeleton for the directory structure:

```bash
├── ...
├── experiment or exercise subfolder
│   ├── board
│   │   ├── Settings specific for the board
│   ├── data
│   │   ├── Input data for simulation
│   ├── doc
│   │   ├── Any additional documentation
│   ├── rtl
│   │   ├── Verilog design files
│   ├── sim
│   │   ├── Modelsim script files
│   ├── syn
│   │   ├── Quartus project/settings files
│   ├── tb
│   │   ├── Testbench files used for simulation
├── ...
├── README.md
└── .gitignore
```

The source code for each of the experiments is nested beneath the corresponding `experiment` subfolder.

To ensure that synthesis files are kept separate from simulation files, the working directory for each `Quartus` project **must** be in the corresponding `syn` sub-folder. Note, with the exception of the first experiment in this course, the project and settings files (`.qpf` and `.qsf`) are already provided in the `syn` sub-folder. The start-up code for all the design files is provided in the `rtl` sub-folder. The testbench files (used to manage the simulation) are in the `tb` sub-folder (the testbench files should **not** be touched at this time of the course!). To simulate your design, after launching `Modelsim`, make sure the working directory is changed to the `sim` sub-folder where the `.do` files are provided. To launch a simulation, in the `Modelsim` shell type `do run.do`. Whenever you wish to update the board events, you need to edit the `board_events.txt` file from the `data` sub-folder. The meaning of this file, and how board simulation is handled in general by the custom framework, is elaborated further in the [board simulation](board-simulation.md) section.

Note, the exercise sub-folder has been set-up to include the same sources as for the in-lab experiment on which they are based on. There is no need to change any file names, so long as the directory structure is kept the same. If you need (or choose) to add new design files to your project, you will have to update both the `Quartus` project (check where the design sources are listed in the `.qsf` file from the `syn` sub-folder) **and** the `Modelsim` project (check where the design sources are used in the `compile.do` file from the `sim` sub-folder).