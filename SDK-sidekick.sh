#!/usr/bin/env bash

# start in a working directory that docker operates on (e.g. ~/Desktop)

## input command
# kbase-app-runner.sh seanjungbluth yes kb_SPAdes no /Applications/ResearchSoftware atom

##variables
# 1 = your_kbase_username (e.g. seanjungbluth)
# 2 = force overwrite? (yes/no)
# 3 = module_name (e.g. kb_SPAdes)
# 4 = new app? (yes/no)
# 5 = path to app (if existing)
# 6 = which editor to use (subl|atom)

set -eu

your_kbase_username=${1}
username=$your_kbase_username

module_name=${3}
EDITOR=${6}


if [ ${2} == "yes" ]; then
  printf "${blue}"
  printf "\n\n***Step 0) Remove previous instance of ${module_name}, if it exists\n"
  printf "${reset}"
  if [ -d "$module_name" ]; then
    printf "\n  ***Warning: Previous folder/version of ${module_name} found, removing...\n"
    rm -Rf $module_name
  fi
fi


printf "${blue}"
printf "\n\n***Step 1) Initialize the module - https://kbase.github.io/kb_sdk_docs/tutorial/3_initialize.html\n"
printf "${reset}"
if [ ${4} == "no" ]; then
  if $(cp -r ${5}/${module_name} ./); then
    printf "\nSuccess: module copied from: ${5}\n"
    printf "\nAttempting command: make\n"
    cd ./${module_name} && make && cd ../
    #   printf ""
    # else
    #   printf "\nError: Couldn't build ${module_name} using the kb-sdk make function"
    #   exit 1
    # fi
  else
    printf "\nError: Couldn't find: ${module_name} in ${5}, are you sure this app exists in that location?"
    exit 1
  fi
else
  kb-sdk init --language python --user ${your_kbase_username} ${module_name} # initialize a new KBase App
fi
printf "\n***Step 1) Finished: Module successfully built!\n"
printf "\n  [Enter] to proceed to Step 2) Build and test docker image\n"
read dummy



# printf "\n\n***Step 1) Initialize the module - https://kbase.github.io/kb_sdk_docs/tutorial/3_initialize.html\n"
# if [ ${4} == "no" ]; then
#   if $(cp -r ${5}/${module_name} ./); then
#     printf "\nSuccess: module copied from: ${5}\n"
#     printf "\nAttempting command: make\n"
#     if $(cd ./${module_name} && make && cd ../); then
#       printf ""
#     else
#       printf "\nError: Couldn't build ${module_name} using the kb-sdk make function"
#       exit 1
#     fi
#   else
#     printf "\nError: Couldn't find: ${module_name} in ${5}, are you sure this app exists in that location?"
#     exit 1
#   fi
# else
#   kb-sdk init --language python --user ${your_kbase_username} ${module_name} # initialize a new KBase App
# fi
# printf "\n***Step 1) Finished: Module successfully built!\n"
# printf "\n  [Enter] to proceed to Step 2) Build and test docker image\n"
# read dummy

printf "${blue}"
printf "\n\n***Step 2) Build and test docker image\n"
printf "${reset}"
printf "\n  --Procedure: \n"
printf "\n  A) edit/construct Docker image at ${module_name}/Dockerfile\n"
printf "\n  ----a) Guide for making Docker images: https://kbase.github.io/kb_sdk_docs/howtos/edit_your_dockerfile.html\n"
printf "\n  ----b) Generally it is recommended to lock any requirements in your app to specific versions. The advantage is that your app will be more reliable and guards against breaking changes in its dependencies.\n"
printf "\n  ----c) You can install binaries to a directory like /kb/deployment/bin and then add them to your path. Docker container command, ENV PATH='/kb/deployment/bin:${PATH}'\n"
printf "\n  B) comment out any entry point to allow testing in bash\n"
sed "s/ENTRYPOINT/#ENTRYPOINT/" ${module_name}/Dockerfile > ${module_name}/Dockerfile.tmp && mv ${module_name}/Dockerfile.tmp ${module_name}/Dockerfile
printf "\n  B) build Docker image by editing the ${module_name}/Dockerfile\n"
docker build -t ${module_name}:latest ${module_name}/
printf "\n  C) test Docker image\n"
printf "\n  When you are done, type <exit> to leave the Docker container\n"
docker run -it ${module_name}:latest /bin/bash
printf "\n  D) if the commands work as expected, then the next step is to set up the ENTRYPOINT as needed for KBase Apps (performing now)\n"
sed "s/#ENTRYPOINT/ENTRYPOINT/" ${module_name}/Dockerfile > ${module_name}/Dockerfile.tmp && mv ${module_name}/Dockerfile.tmp ${module_name}/Dockerfile
docker build -t ${module_name}:latest ${module_name}/

printf "\n  [Enter] to proceed to Step 3) Customize the template files for your App\n"
read dummy

printf "${blue}"
printf "\n\n***Step 3) Customize the template files for your App\n"
printf "${reset}"
printf "\n  --Modify these files - typically developers follow this path: \n"
printf "\n  3A) ${module_name}/${module_name}.spec\n"
printf "\n  --Work on the MyModule.spec file. This will autogenerate methods in your MyModuleImpl.py file, which is where the core of your method functionality will reside.\n"
printf "\n  [Enter] to proceed to Step 3B\n"
read dummy
printf "\n  3B) Continue developing the app by working on unit tests.\n"
printf "\n  ----a): Test files can go within the test/ directory in your app, such as test/data/\n"
printf "\n  ----b): Ways you can speed up your tests: Option 1: Make sure all your custom docker setup, such as compiling binaries, is at the top of your Dockerfile so it always gets cached. Option 2: Reduce the number of files you download and upload. Option 3: Reuse existing example files on the workspace so you don’t have to upload files. Option 4: Separate out your modules into functions that only take local data and files, and test those separately.\n"
printf "\n  [Enter] to proceed to Step 3C\n"
read dummy
printf "\n  3C) ${module_name}/lib/*/*Impl.py"
printf "\n  --Work on the functionality of the app in the autogenerated MyModuleImpl.py file.\n"
printf "\n  ----a): Working with reference data? Put simple data into the /data directory of your app’s repository. If the data is too large to host on Github, check out the following guide: https://kbase.github.io/kb_sdk_docs/howtos/work_with_reference_data.html\n"
printf "\n  ----b): How do I organize my app’s code? Option 1: Create multiple functions and do everything inside the implementation file. Webpage link to example: https://github.com/kbaseapps/kb_quast/blob/master/kb_quast.spec. Option 2 (preferred for complex multi-module/package apps): Create a utils directory, create a runner or utility class, pass in the configuration file and parameter files to it, and do everything in there. Webpage link to example: https://github.com/kbaseapps/FastANI/blob/master/lib/FastANI/FastANIImpl.py\n"
printf "\n  [Enter] to proceed to Steps 3D&E\n"
read dummy
printf "\n  3D) ${module_name}/ui/narrative/methods/*/spec.json"
printf "\n  3E) ${module_name}/ui/narrative/methods/*/display.yaml"
printf "\n  --Define the UI by modifying spec.json and display.yaml files\n"
printf "\n  ----a): Look at the UI specification guide for more info on spec.json and display.yaml files. Webpage link: https://kbase.github.io/kb_sdk_docs/references/UI_spec.html\n"
printf "\n  ----b): You can also experiment with UI generation with the App Spec Editor Narrative. Webpage link: https://narrative.kbase.us/narrative/ws.28370.obj.1\n"
printf "\n  [Enter] to proceed to Step 3F\n"
read dummy
printf "\n  3F) ${module_name}/kbase.yml"
printf "\n  --If sufficient work involved, add yourself as an author to kbase.yml. Also bump the version number appropriately.\n"
printf "\n  Opening files in ${EDITOR}\n"
# $EDITOR ${module_name}
printf "\n  [Enter] to proceed to Step 4) Share code via Github\n"
read dummy

printf "${blue}"
printf "\n\n***Step 4) Share code via Github.\n"
printf "${reset}"
printf "\n  [Enter] to proceed to Step 5) Set up your developer credentials\n"
read dummy

printf "${blue}"
printf "\n\n***Step 5) Set up your developer credentials.\n"
printf "${reset}"
printf "\n  Go to https://narrative.kbase.us/#auth2/account, click Developer Tokens, and generate a new token.\n"
echo "https://narrative.kbase.us/#auth2/account" | pbcopy && printf "\n  *Action: KBase website copied to clipboard, paste in web browser*\n"
printf "\n  Copy Dev token here: "
read kbasedevtoken
mkdir ${module_name}/test_local
printf "test_token=${kbasedevtoken}\n" > ${module_name}/test_local/test.cfg
printf "auth_service_url=https://kbase.us/services/auth/api/legacy/KBase/Sessions/Login/" >> ${module_name}/test_local/test.cfg
printf "\n  [Enter] to proceed to Step 6) Run kb-sdk test to validate the module\n"
read dummy

printf "${blue}"
printf "\n\n***Step 6) Run kb-sdk test to validate the module.\n"
printf "${reset}"
cd ${module_name} && kb-sdk test
printf "\n  [Enter] to proceed to Step 7) Adding a custom icon\n"
read dummy

printf "${blue}"
printf "\n\n***Step 7) Adding a custom icon for one or multiple apps in your modules.\n"
printf "${reset}"
printf "\n  A) Feel free to repurpose the icons from existing KBase apps, or make your own. Your icon can be PNG, GIF, or JPEG (the KBase ones are PNG) and should fit in a square 200x200 pixels. To match our existing icons, use these guidelines: \n"
printf "\n  --200x200px image with 40px rounded edges\n"
printf "\n  --Font: Futura Condensed Medium, 72pt, white\n"
printf "\n  --72dpi PNG\n"
printf "\n  B) PDF vector and PNG bitmap versions that we used for our icons are available here: https://github.com/kbase/kb_sdk_docs/tree/master/source/images/app-icons\n"
printf "\n  C) Alternatively, generate and icon using ImageMagick"
printf "\n  Run the command: convert -size 200x200 -gravity center -background DarkOliveGreen4 -font Times-Italic -fill white label:"{icon_name}" ${module_name}.png"
printf "\n  A list of colors is found here: https://imagemagick.org/script/color.php"
printf "\n  An online tool to round corners is found here: https://pinetools.com/round-corners-image"
printf "\n"
printf "\n  [Enter] to proceed to Step 8) Register your module\n"
read dummy

printf "${blue}"
printf "\n\n***Step 8) Register your module (if not previously registered).\n"
printf "${reset}"
printf "  Register your module here: https://appdev.kbase.us/#appcatalog/register\n"
echo "https://appdev.kbase.us/#appcatalog/register" | pbcopy && printf "\n  *Action: KBase Module Registration website copied to clipboard, paste in web browser*\n"
read dummy
