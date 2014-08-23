lnpm.sh
=======
A bash script to make npm operations faster and less storage intensive. And providing the ability to manage modules locally.

This script solves the problem of having node_modules installed in every directory in which you have a node project. It allows node modules to be read from a centralized directory on the file system and when a particular module does not exist it will download the package to the centralized directory for continued use. No more downloading modules every time you start a new node project and no longer do node modules have to be spread out all over your hard drive. Every version of a module in use is conveniently stored in one place.

Preparing your system to use lnpm:

Clone this repo or simply copy the lnpm.sh code and paste it into a file of the same name on your system.
Move or copy lnpm.sh into a folder you have designated for scripts or add whatever directory lnpm.sh is stored in to your path. (export PATH="$PATH:<lnpm.sh parent directory>")
Set the permission of lnpm.sh to be executable (chmod u+x lnpm.sh)
Create a directory for the purpose of storing node modules for lnpm to use.
Add the following line to your ~/.bashrc file:
export LNPMDIR=<THE FULL PATH OF THE LOCAL DIRECTORY YOU WILL USE TO STORE THE NODE PACKAGES>
Run source ~/.bashrc or restart
Open a terminal window and type lnpm. If setup is correct you should see the following message:
Invalid First Parameter
Valid First Parameters are: install, configure, convert, update, revert and copy

After that is done, the easiest way to get started is to copy an existing node_modules directory from one of your existing projects to where you want your centralized location. Then run lnpm configure. This will change all the directory names to <modulename>---<version>. This makes the modules usable with lnpm and your ready to go. If you find some other module directories later that your want to add, you can easily copy to the lnpm directory and run lnpm configure again to set them up. You can also install modules using npm from within the lnpm directory and then run lnpm configure.


lnpm.sh install <module name>
Searches the lnpm directory for the each module and if it exist it will do the following as needed:
If no package.json exists, it will run npm.init to interactively create it.
If no dependencies object exists, it will add it to the package.json.
If no reference to the module exists in the dependencies object, it will be added.
If the module does not exist in the lnpm directory, it will be download and assimilated into the lnpm directory and the previous steps will then be carried out.
Note that if there is more that one version of a module in the lnpm directory, you will be prompted with a selection list to choose the one to install.

lnpm.sh install [<modulename,s> [--save] [--save-dev]]

install - Running lnpm install without any arguments will install based on the existing package json. If no package.json exists it will error out. If the directory from which the command is run has already been installed with npm, you should not use this command. First use 'convert' which will prepare the project for use with lnpm. Otherwise your will end up with the module directories still installed locally in your project.

lnpm install <modulename,s> -Installs the module,s and adds it to package.json as a dependency, creating the package.json interactively first if needed.

lnpm <modulename,s> --save -same as lnpm <modulename,s>

lnpm <modulename,s> --save-dev -Installs the module,s and adds it to package.json as a devdependency, creating the package.json interactively first if needed.

lnpm configure
Makes an existing node_modules directory compatible with lnpm.sh by renaming the directories to include versions. (<modulename>--<ver>) You can run this from any directory. It always works on the directory designated for for lnpm. You can also copy unprepared npm directories into this folder and run lnpm configure to conform them.

update [<modulename>]
Without a module name this will add the latest version of all modules not already stored in the local folder. If a module name is provided only that module will be affected. Note that with lnpm, modules are not replaced with update. The latest version is only added to the the lnpm folder as an option. Also note that if you have many modules in the lnpm folder, updating all of them could take some time.

revert
Reverts the lmpm modules directory directories to standard node names. Since lnpm allows the centralized storage of multiple module versions by adding the version to the directory name, directories that are part of a multi-version module will remain unaltered. You will need to choose a version and rename the directory manually