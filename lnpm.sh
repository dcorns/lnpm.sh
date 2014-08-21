#!/usr/bin/env bash
#Created by Dale Corns codefellow@gmail.com Copyright (c)2014 Dale Corns
#https://github.com/dcorns  www.linkedin.com/in/dalecorns/
#GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
#Please report any bugs https://github.com/dcorns/bash_scripts/issues
echo lnpm started > lnpm.log
date >> lnpm.log
clear
#*******************************************Variables*******************************************************************
#set the local node modules directory here/usr/bin/env
nd=$(echo $LNPMDIR)
#nd='/data/Projects/node_modules/'
#define colors
red='\e[0;31m'
green='\e[0;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
default='\e[0m'
havedependencies=false
havedevdependencies=false
localpackageadded=false
alreadydep=false
alreadydev=false
declare -a depobj
declare -a devobj
declare -a pkgjson
declare -a deplist
declare -a depverlist
declare -a devlist
declare -a devverlist
cwd=$(pwd)
#Add parameters to function scopes
pkginstall=$2
declare -a currentpaths
declare -a currentversions
#devinstall=$3
modparam=''
declare -a pkgpaths
declare -a pkglist
declare -a verlist
declare -a params
declare -i count
pkgpath=''
pkgver=''
pkgcount=0
copy=false
testpath='/data/Projects/node_modules/grunt-casper--0.3.10'
#******************************************Functions********************************************************************

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++setupDirs++++++++++++++++++++++++++++++++++++++++++++++
#Configure existing directory that already contains normal node modules to work with lnpm
setupDirs(){
echo [48] 'setupDirs()'${1} ''${2} ''${3} >> ${cwd}/lnpm.log
#Rename each directory with a 0-0-0 extention for version identification
    #Proccess directories
    preparedcount=0
    cd $nd
    for path in $nd*; do
    [ -d "${path}" ] || continue # if not a directory, skip
    dirname="$(basename "${path}")"

    cd "$dirname"
    ver=$(grep '"version"' package.json)
    pkgname=$(grep '"_id"' package.json)
    pkgnm=${pkgname#*:} #remove everything left of the colon
    pknm=${pkgnm%*,}
    pknmlength=${#pknm}
    charvalid=true
    count=1
    pknam=''
    #extract everything left of the @ to retrieve package name
    while (( count < $pknmlength )); do
    testval=${pknm:count:1}
    if [ $testval == "@" ]; then
    charvalid=false
    fi
    if [ $charvalid = true ]; then
    pknam=$pknam${pknm:count:1}
    fi
    let count+=1
    done
    pknam=${pknam:1:${#pknam}-1}
    #extract from version field to retrieve version number
    vers=${ver#*:} #remove most everything left of the colon
    #get rid of extra space, comma and quotes
    verslength=${#vers}
    vers=${vers:2:verslength-4}
    newdir=$pknam--$vers
    cd ..
    #if the directory does not have a version number with name add it here otherwise leave alone
    if [ "$newdir" != "$dirname" ]; then
        mv $dirname "$newdir"
        #echo -e ${green}$dirname 'prepared'${default}
        let preparedcount+=1
    fi
done
}

#++++++++++++++++++++++++++++++++++++++++++++++++++update+++++++++++++++++++++++++++++++++++++++++++++++++++++++
#add latest packages from npm registry to local directory
update(){
cd $nd
#Run setupDirs in case update is being run on a directory that has not yet configured sub directory names
setupDirs
#Create a temp directory and copy all modules over, striping them their version from directory name
#Run npm update
#Configure the temp directories and copy what does not already exist to the local folder, then remove temp directory and contents
if [ "$pkginstall" == "" ]; then
echo -e ${yellow}'update all chosen: This could take a while. To avoid this include a package to update as the second parameter'${default}
        echo "Enter 'yes' to continue"
        read
        if [ "$REPLY" = 'yes' ]; then
            splitdirnames
            count=0
            pkgchecked=false
            currentpkglist=${pkglist[@]}
            declare -a pkgProccessed
            for pkg in ${currentpkglist[@]}; do
                #pkglist is part of an array set that includes pkgverlist and pkgpaths so pkglist may have duplicate package names. So the following filter is required to avoid multiple upgrades on the same package
                pkgchecked=false
                for ppkg in ${pkgProccessed[@]}; do
                    if [ ${pkg} = ${ppkg} ]; then
                        pkgchecked=true
                    fi
                done
                if [ ${pkgchecked} != true ]; then
                    pkginstall=${pkg}
                    updateLocalPackage ${pkg}
                    pkgProccessed[count]=${pkg}
                    let count+=1
                fi
            done
        else
            echo -e ${red}'user canceled update'${default}
            cd ..
            rm incoming_modules -R
            exit 0
        fi
    else
        echo -e ${yellow}$pkginstall 'module included'${default}
        #verifiy existing package exists, if not offer to install it
        getPackageCount ${pkginstall}
        if [ ${pkgcount} -lt 1 ]; then
            echo -e ${yellow}'An existing version of' $pkginstall 'was not found, would you like to install it instead? (no to cancel) (yes)'${default}
            read
            if [ "$REPLY" == "no" ]; then
               echo -e ${red}'User cancled update'${default}
               exit 0
            else
                npm install $pkginstall
                setupDirs
                exit 0
            fi
        fi
        updateLocalPackage ${pkginstall}
    fi
    echo -e ${green}'Update Complete'${default}
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++revertDirs+++++++++++++++++++++++++++++++++++++++++++++++++++
#revert the local folder or some other folder to standard package names
revertDirs(){
echo [158] 'revertDirs()'${1} ''${2} ''${3} >> ${cwd}/lnpm.log
cd $nd

dircount=0
dupscount=0
for path in $nd*; do
    [ -d "${path}" ] || continue # if not a directory, skip
    dirname="$(basename "${path}")"
    cd "$dirname"
    #remove everything in directory name including double dash to end to get package name
    basedir=${dirname%%'--'*}
    #remove everything in directory name including double dash to front to get version
    vers=${dirname##*'--'}
    #check for multi-version packages and add version back to the directory name of duplicates

    for i in ${adir[@]};do
    if [ ${i} = $basedir ]; then
        duprecorded=false
        for ii in ${dups[@]};do
            if [ ${ii} = ${i} ]; then
                duprecorded=true
            fi
        done
        if [ $duprecorded != true ]; then
                dups[dupscount]=$basedir
                let dupscount=dupscount+1
        fi
    fi
    done
    adir[$dircount]=$basedir
    edir[$dircount]=$dirname
    cd ..
    let dircount=dircount+1
done

dircount=0
for j in ${adir[@]};do
    isdup=false
     for k in ${dups[@]};do
        if [ ${j} = ${k} ]; then
            isdup=true
        fi
    done
    if [ $isdup != true ]; then
    mv ${edir[$dircount]} ${j}
    fi
    let dircount=dircount+1
done

exit 0
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++install++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#*************************************lnpm install code*****************************************************************
install(){
local pkgin=${1}
echo -e '\e[1;34m'[219] 'install() pkgin='${pkgin}'\e[0m' >> ${cwd}/lnpm.log
#Check for package locally, else install from repo and setup the directory, else error invalid package
setpackage ${pkgin}
#verify or create package.json file
checkpackagejson
#parce package.json and set flags for proccessing
parcepkgjson
#Make package dev and dep lists
makeDepList
makeDevList
#if not already in package.json dependencies object, add it
checkpackageDep ${pkgin}
checkpackageDev ${pkgin}


if [ "$modparam" = "--save-dev" ]; then
    if [ $alreadydev = false ]; then
        echo -e ${green}'adding' ${pkgin} 'version' ${pkgver} "to package.json devdependencies"${default}
        addpackageDev ${pkgin}
    fi
fi

if [ "$modparam" = "--save" ] || [ "$modparam" = "" ]; then
    if [ $alreadydep = false ]; then
    echo -e ${green}'adding' ${pkgin} 'version' ${pkgver} "to package.json dependencies"${default}
    addpackageDep ${pkgin}
    fi
fi
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++check3++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#validate the third parameter devinstall
check3(){
echo [252] 'check3() modparam='${modparam} >> ${cwd}/lnpm.log
case $modparam in
    '--save-dev') ;;
    '--save') ;;
    '') ;;
    *) echo -e ${red}'Valid options are --save, --save-dev'${default}
       exit 0
       ;;
esac
}
#Extract package names versions and paths from local package directory
splitdirnames(){
echo -e '\e[1;34m'[260] 'splitdirnames()'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
    dircount=0
    for path in $nd*; do
    [ -d "${path}" ] || continue # if not a directory, skip
    basedirname="$(basename "${path}")"
    #remove everything in directory name including double dash to end to get package name
    basedir=${basedirname%%'--'*}
    #remove everything in directory name including double dash to front to get version
    vers=${basedirname##*'--'}
    #add values to arrays
    pkglist[$dircount]=$basedir
    verlist[$dircount]=$vers
    pkgpaths[$dircount]='"'$nd$basedirname'"'
    let dircount=dircount+1
done
}

setpackage()
{
echo -e '\e[1;34m'[279] 'setpackage()'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
local pkgin=${1}
if [ "$pkgin" != "" ]; then
#see if the package ($pkgin) exists in the local directory
    #get local package list set $pkgpath and $pkgver if at least one package is in the list
    getPackageCount ${pkgin}
    if [ ${pkgcount} -gt 0 ]; then
        #set package path
        pkgpath=${currentpaths[0]}
        pkgver=${currentversions[0]}
        if [ ${pkgcount} -lt 2 ]; then
        echo [290] 'pkgcount='${pkgcount} 'pkgin='${pkgin} 'found locally' >> ${cwd}/lnpm.log
        fi
        #If more than one version then manage (pkgexists advances one more before exiting loop)
        #Offer user list to select which version to use and place selection in global $pkgpath and $pkgver
        if [ $pkgcount -gt 1 ]; then
        echo [294] 'pkgcount='${pkgcount} 'pkgin='${pkgin} 'found locally' >> ${cwd}/lnpm.log
            options=${currentversions[@]}
            select s in $options; do
            count=0
            for cv in ${currentversions[@]}; do
                if [ $cv = $s ]; then
                    pkgpath=${currentpaths[count]}
                    pkgver=${currentversions[count]}
                fi
                let count=${count}+1
            done
            break
            done
        fi
#not in local directory, download it if it exists in npm registry
    else
        cd $nd
        npm install $pkgin
        setupDirs
        getPackageCount ${pkgin}
        if [ $pkgcount -gt 0 ]; then
            setpackage ${pkgin}
        else
            echo [318] 'Package '${pkgin} 'not found locally or remotely' >> ${cwd}/lnpm.log
        exit 0
        fi
    fi
else
#echo -e ${yellow}'No package specified for installation. Installing from package.json'${default}
convert
fi
}

#check for package.json and if exist, otherwise create it
checkpackagejson()
{
#check for package.json and npm init if it does not exist
echo -e '\e[1;34m'[337] 'checkpackagejson()''\e[0m' >> ${cwd}/lnpm.log
cd $cwd
local pkg=$(find package.json)
if [ "$pkg" != 'package.json' ]; then
    npm init
fi
}
#Check for package in dependencies
checkpackageDep(){
local pkgin=${1}
echo -e '\e[1;34m'[346] 'checkpackageDep() pkgin='${pkgin}'\e[0m' >> ${cwd}/lnpm.log
if [ $localpackageadded = true ]; then
        echo "New package added, bypass package.json dependencies check"
    else
        p=0;
        while (( ${#deplist[@]} > $p )); do
            if [ $pkgin = ${deplist[$p]} ]; then
                alreadydep=true
                if [ $pkgver = ${depverlist[$p]} ]; then
                echo -e ${yellow}$pkgin $pkgver is already in package.json dependencies object${default}
                else
                echo -e ${yellow}'Another version ('${depverlist[p]}') of' ${deplist[p]} 'is already in package.json!'${default}
                exit 0
                fi
            fi
            let p+=1
        done
    fi
}
#Check for package in devdependencies
checkpackageDev(){
local pkgin=$1
echo -e '\e[1;34m'[369] 'checkpackageDev() pkgin='${pkgin} 'localpackageadded='${localpackageadded}'\e[0m' >> ${cwd}/lnpm.log
#if [ $localpackageadded = true ]; then
 #       echo "New package added, bypass package.json devdependencies check"
  #  else
        cv=0;
        while (( ${#devlist[@]} > $cv )); do
            if [ $pkgin == ${devlist[$cv]} ]; then
                if [ $pkgver == ${devverlist[$cv]} ]; then
                alreadydev=true
                echo -e ${yellow}$pkgin $pkgver is already in package.json devDependencies object${default}
                else
                echo -e ${yellow}'Another version ('${depverlist[p]}') of' ${deplist[p]} 'is already in package.json!'${default}
                exit 0
                fi
            fi
            let cv+=1
        done
   # fi
}
addpackageDep(){
local pkgin=${1}
local dp=0
#extract package.json lines to array
echo -e '\e[1;34m'[390] 'addpackageDep() pkgin='${pkgin}'\e[0m' >> ${cwd}/lnpm.log
readarray -t pkgjson < package.json
cd $cwd
#make temp package.json file
touch package.njson
#if dependencies object already exists in package.json just add the package to it
if [ $havedependencies = true ]; then
    while (( ${#pkgjson[@]} > dp )); do
        pkgline=${pkgjson[dp++]}
        echo $pkgline >> package.njson
        dep=$(echo $pkgline | grep -o 'dependencies')
        if [ "$dep" = 'dependencies' ]; then
            echo '"'$pkgin'"': '"'$pkgver'"'"," >> package.njson
        fi
    done
else
#create dependencies object and add the package to it
    size=${#pkgjson[@]}
    let size-=1
    count=1
    while (( ${#pkgjson[@]} > dp )); do
        pkgline=${pkgjson[dp++]}
            if [ $size = $count ]; then
                echo $pkgline',' >> package.njson #add comma to last object
                depends='"dependencies"'
                echo $depends': {' >> package.njson
                echo '"'$pkgin'"': '"'$pkgver'"' >> package.njson
                echo "}" >> package.njson
            else
                echo $pkgline >> package.njson
            fi
        let count+=1
    done
fi
writepackagejson
writelink ${pkgin} ${pkgver}
echo -e ${green}$pkgin $pkgver 'added to package.json dependencies'${default}
}

addpackageDev(){
local pkgin=${1}
local ad=0
#extract package.json lines to array
echo -e '\e[1;34m'[432] 'addpackageDev() pkgin='${pkgin}'\e[0m' >> ${cwd}/lnpm.log
readarray -t pkgjson < package.json
cd $cwd
#make temp package.json file
touch package.njson
depends='"devDependencies"'
echo [439] 'havedevdependencies='${havedevdependencies} >> ${cwd}/lnpm.log
if [ $havedevdependencies = true ]; then
    while (( ${#pkgjson[@]} > ad )); do
        pkgline=${pkgjson[ad++]}
        echo $pkgline >> package.njson
        dep=$(echo $pkgline | grep -o 'devDependencies')
        if [ "$dep" = 'devDependencies' ]; then
            echo '"'$pkgin'"': '"'$pkgver'"'"," >> package.njson
        fi
    done
else
    size=${#pkgjson[@]}
    let size-=1
    count=1
    while (( ${#pkgjson[@]} > ad )); do
        pkgline=${pkgjson[ad++]}
        dep=$(echo $pkgline | grep -o 'devDependencies')
        #if the result is invalid the if statement will generate error however program still executes as expected
        if [ $size = $count ]; then
            echo $pkgline',' >> package.njson
            depends='"devDependencies"'
            echo $depends': {' >> package.njson
            echo '"'$pkgin'"': '"'$pkgver'"' >> package.njson
            echo "}" >> package.njson
        else
            echo $pkgline >> package.njson
        fi
        let count+=1
    done
fi
#replace package.json with modified
writepackagejson
writelink ${pkgin} ${pkgver}
echo -e ${green}$pkgin $pkgver 'added to package.json devdependencies'${default}
}
writepackagejson(){
echo -e '\e[1;34m'[474] 'writepackagejson()''\e[0m' >> ${cwd}/lnpm.log
rm package.json
mv package.njson package.json
}
#sets havedependencies and havedevdependencies if exists, stores existing dependencies and devDependencies objects to
#depobj and devobj respectively
#requires pkgjson
parcepkgjson(){
#extract package.json lines to array and other stuff that isn't really needed
echo -e '\e[1;34m'[483] 'parcepkgjson()''\e[0m' >> ${cwd}/lnpm.log
readarray -t pkgjson < package.json
count=1
depstart=false
devstart=false
depcount=0
devcount=0
local i=0
    while (( ${#pkgjson[@]} > i )); do
        pkgline=${pkgjson[i++]}
        testforDep=$(echo $pkgline | grep -o 'dependencies')
        if [ "$testforDep" == "dependencies" ]; then
            havedependencies=true
            depstart=true
        fi
        if [ $depstart = true ]; then
            depend=$(echo $pkgline | grep -0 '}')
            if [ "$depend" != "}," ] && [ "$depend" != "}" ]; then
                depobj[$depcount]=$pkgline
                let depcount+=1
            else
                depobj[$depcount]=$pkgline
                let depcount+=1
                depstart=false
            fi
        fi
        testforDevDep=$(echo $pkgline | grep -o 'devDependencies')
        if [ "$testforDevDep" == "devDependencies" ]; then
            havedevdependencies=true
            devstart=true
        fi
        if [ $devstart = true ]; then
            devend=$(echo $pkgline | grep -0 '}')
            if [ "$devend" != "}" ] && [ "$devend" != "}," ]; then
                devobj[$devcount]=$pkgline
                let devcount+=1
            else
                devobj[$devcount]=$pkgline
                let devcount+=1
                devstart=false
            fi
        fi
        let count+=1
    done
}

#requires depobj, havedependencies
makeDepList(){
echo -e '\e[1;34m'[527] 'makeDepList()'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
    if [ $havedependencies = true ]; then
        echo -e ${green}'building deplist'${default}
        depobjlength=${#depobj[@]}
        dpo=1
        count=0
        while (( depobjlength-1 > dpo )); do
            pkgjsondep=${depobj[dpo]}
            #drop everything after package name
            basepkgdep=${pkgjsondep%%':'*}
            #drop everything before last version text
            basepkgdepver=${pkgjsondep##*':'}
            #drop the comma if it has one
            basepkgdepver=${basepkgdepver%%','*}
            depverlist[count]=$basepkgdepver
            deplist[count]=$basepkgdep
            let dpo+=1
            let count+=1
        done
    fi
}

#requires devobj, havedevdependencies
makeDevList(){
echo -e '\e[1;34m'[551] 'makeDevList()''\e[0m' >> ${cwd}/lnpm.log
    if [ $havedevdependencies = true ]; then
        echo -e ${green}'building devlist'${default}
        devobjlength=${#devobj[@]}
        dvo=1
        count=0
        while (( devobjlength-1 > dvo )); do
            pkgjsondev=${devobj[dvo]}
            #drop everything after package name
            basepkgdev=${pkgjsondev%%':'*}
            #drop everything before last version text
            basepkgdevver=${pkgjsondev##*':'}
            #drop the comma if it has one
            basepkgdevver=${basepkgdevver%%','*}
            devverlist[count]=$basepkgdevver
            devlist[count]=$basepkgdev
            let dvo+=1
            let count+=1
        done
    fi
}

getPackageCount(){
echo -e '\e[1;34m'[580] 'getPackageCount() pkgin='${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
#Checks for versions of pkgin($1) in the local directory and pkgcount+1 for each version found
#If there is a match, it also sets currentpaths and currentversions arrays to match directories found
    splitdirnames
    local pkgin=${1}
    pkgidx=0
    pkgcount=0
    for p in ${pkglist[@]}; do
        if [ ${p} = ${pkgin} ]; then
            echo ${p}
            currentpaths[$pkgcount]=${pkgpaths[$pkgidx]}
            currentversions[$pkgcount]=${verlist[$pkgidx]}
            let pkgcount=${pkgcount}+1
        fi
        let pkgidx=${pkgidx}+1
    done
}

convert(){
    echo -e '\e[1;34m'[598] 'convert()'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
    parcepkgjson
    makeDepList
    makeDevList
    local count=0
    local vrs=0
    local devVrs=0
    for dep in ${deplist[@]}; do
        #check for version in local node storage
        vrs=$(setVersion ${dep} ${depverlist[${count}]})
        echo [608] 'vrs='${vrs} >> ${cwd}/lnpm.log
        #if the version exists create sym link
        if [ ${#vrs} -lt 2 ]; then
            echo -e ${red}"Invalid dependency setting in package.json:" ${dep} ${depverlist[${count}]}${default}
        else
            local pkln=${#dep}
            local apkln=`expr $pkln - 2`
            local pkgin=`expr substr ${dep} 2 $apkln`
            writelink ${pkgin} ${vrs}
            echo -e ${green}"Converted" ${pkgin} ${vrs}${default}
        fi
        let count+=1
    done
    count=0
    for dev in ${devlist[@]}; do
        #check for version in local node storage
        devVrs=$(setVersion ${dev} ${devverlist[${count}]})
        #if the version exists create sym link
        if [ ${#devVrs} -lt 2 ]; then
            echo -e ${red}"Invalid dev dependency setting in package.json:" ${dev} ${devverlist[${count}]}${default}
        else
            local pkvln=${#dev}
            local apkvln=`expr $pkvln - 2`
            local pkgvin=`expr substr ${dev} 2 $apkvln`
            writelink ${pkgvin} ${devVrs}
            echo -e ${green}"Converted " ${pkgvin} ${devVrs}${default}
        fi
        let count+=1
    done
    exit 0
}

getLatestLocalVer(){
    local latestLocalVer=0.0.0
    setPackageCount ${1}
    if [ ${pkgcount} -lt 2 ]; then
        latestLocalVer=${currentversions[0]}
    else
        if [ ${pkgcount} -gt 1 ]; then
            cV1=0
            cV2=0
            cV3=0
            cVtest=""
            for cV in ${currentversions[@]}; do
                idx=`expr index ${cV} .`
                cVtest=${cV:${idx}}
                V1=${cV:0:${idx}-1}
                if [ ${V1} -ge ${cV1} ]; then
                    cV1=${V1}
                fi
            done
            for cV in ${currentversions[@]}; do
                idx=`expr index ${cVtest} .`
                V2=${cVtest:0:${idx}-1}
                if [[ ${V1} -eq ${cV1} ]] && [[ ${V2} -ge ${cV2} ]]; then
                    cV2=${V2}
                fi
            done
            for cV in ${currentversions[@]}; do
                cVtest=${cVtest:${idx}}
                if [[ ${V1} -eq ${cV1} ]] && [[ ${V2} -eq ${cV2} ]] && [[ ${cVtest} -gt ${cV3} ]]; then
                    cV3=${cVtest}
                fi
            done
            latestLocalVer=${cV1}.${cV2}.${cV3}
        fi
    fi
    echo ${latestLocalVer}
}

updateLocalPackage(){
local rver=$(checkForLatestVer ${1})
if [ ${rver} != 0 ]; then
    cd ${nd}
    npm install ${1}
    setupDirs
    dirsSetup=${preparedcount}
    if [ $dirsSetup -gt 0 ]; then
        echo -e ${green}$1 'version' ${rver} 'added to local package directory.'${default}
    else
        echo -e ${red}$1 'version' ${rver} 'was not added to local package directory.'${default}
    fi
else
    echo -e ${yellow}'Latest version of' ${1} 'already installed locally'${default}
fi
}

writeRemoteView(){
    npm view $1 > ${nd}remoteView.tmp
}

getRemoteLatestVer(){
    writeRemoteView $1
    local rvers=$(grep "version:" ${nd}remoteView.tmp)
    #extract from version field to retrieve version number
    local rvers=${rvers#*:} #remove most everything left of the colon
    #get rid of extra space, comma and quotes
    local rverslength=${#rvers}
    rvers=${rvers:2:rverslength-4}
    echo ${rvers}
}

checkForLatestVer(){
#if latest version is local return 0 else return version from remote
local rlv=$(getRemoteLatestVer $1)
setPackageCount ${1}
local result=${rlv}
    for cp in ${currentversions[@]}; do
        if [ ${cp} == ${rlv} ]; then
            result=0
        fi
    done
echo ${result}
}

setPackageCount(){
echo -e '\e[1;34m'[724] 'setPackageCount()'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
#Checks for versions of $1 in the local directory and pkgcount+1 for each version found
#If there is a match, it also sets currentpaths and currentversions arrays to match directories found
    splitdirnames
    pkgidx=0
    pkgcount=0
    for p in ${pkglist[@]}; do
        if [ ${p} = $1 ]; then
            currentpaths[$pkgcount]=${pkgpaths[$pkgidx]}
            currentversions[$pkgcount]=${verlist[$pkgidx]}
            let pkgcount=${pkgcount}+1
        fi
        let pkgidx=${pkgidx}+1
    done
}

setVersion(){
echo -e '\e[1;34m'[741] 'setVersion()' ${1} ${2} ${3}'\e[0m' >> ${cwd}/lnpm.log
local result=""
local ln=${#2}
local pkln=${#1}
local apkln=`expr $pkln - 2`
local pkgin=`expr substr $1 2 $apkln`
local verstr=`expr substr $2 1 1`
local strln=${ln}
local rgx=''
local verin=0.0.0
local vpiece=0
local dots=""
local ndots=0
local testver=""
local greatestN=0
local v1=0
local v2=0
local v3=0
local versionLocal=0

let strln=${strln}-2
verstr=${2:1:${strln}}
ln=${#verstr}
pkln=${#pkgin}
#load currentversion array with versions for pkgin
setPackageCount ${pkgin}

#Any version
rgx='^[x \*]$'
if [[ ${verstr} =~ $rgx ]]; then
    result=$(anyVersion ${pkgin})
    versionLocal=$(isLocal ${pkgin} ${result})
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
    fi
fi
#Exact version
local rgx='^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
if [[ ${verstr} =~ $rgx ]]; then
    result=$(exactVersion ${pkgin} ${verstr})
    echo [784] 'result='${result} ''${2} ''${3} >> ${cwd}/lnpm.log
    versionLocal=$(isLocal ${pkgin} ${result})
    echo [786] 'versionLocal'${versionLocal} ''${2} ''${3} >> ${cwd}/lnpm.log
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
        exit 0
    fi
    exit 0
fi
#Compatible ^
rgx='^\^'
if [[ ${verstr} =~ $rgx ]]; then
result=$(compatibleVersion ${pkgin} ${verstr})
versionLocal=$(isLocal ${pkgin} ${result})
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
        exit 0
    fi
fi
#Reasonably close ~
rgx='^~'
if [[ ${verstr} =~ $rgx ]]; then
result=$(reasonablyClose ${pkgin} ${verstr})
versionLocal=$(isLocal ${pkgin} ${result})
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
        exit 0
    fi
fi
#Greater than equal
rgx='^>='
if [[ ${verstr} =~ $rgx ]]; then
result=$(greaterThanEqual ${pkgin} ${verstr})
versionLocal=$(isLocal ${pkgin} ${result})
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
        exit 0
    fi
fi
#Less than equal
rgx='^<='
if [[ ${verstr} =~ $rgx ]]; then
result=$(lessThanEqual ${pkgin} ${verstr})
versionLocal=$(isLocal ${pkgin} ${result})
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
        exit 0
    fi
fi
#Less than
rgx='^<'
if [[ ${verstr} =~ $rgx ]]; then
result=$(lessThanVersion ${pkgin} ${verstr})
versionLocal=$(isLocal ${pkgin} ${result})
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
        exit 0
    fi
fi
#Greater than
rgx='^>'
if [[ ${verstr} =~ $rgx ]]; then
echo [862] 'result='${result} >> ${cwd}/lnpm.log
result=$(greaterThanVersion ${pkgin} ${verstr})
echo [864] 'result='${result} >> ${cwd}/lnpm.log
versionLocal=$(isLocal ${pkgin} ${result})
echo [866] 'versionLocal='${versionLocal} 'result='${result} 'verstr='${verstr} >> ${cwd}/lnpm.log
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
        exit 0
    fi
fi
#Any sub release d.x, d.*
rgx='[0-9]*\.[x\*]$'
if [[ ${verstr} =~ $rgx ]]; then
result=$(anySubVersionX ${pkgin} ${verstr})
versionLocal=$(isLocal ${pkgin} ${result})
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
        exit 0
    fi
fi
#Any sub release d d.d
rgx='^[0-9][0-9]*$|^[0-9][0-9]*\.[0-9][0-9]*$'
if [[ ${verstr} =~ $rgx ]]; then
result=$(anySubVersionD ${pkgin} ${verstr})
versionLocal=$(isLocal ${pkgin} ${result})
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
    else
        echo -
        exit 0
    fi
fi
#PreRelease -... All pre-release versions return themselves only
rgx='^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\-[^\.,][0-9a-zA-Z\.]*$'
if [[ ${verstr} =~ $rgx ]]; then
    result=$(preReleaseVersion ${pkgin} ${verstr})
    versionLocal=$(isLocal ${pkgin} ${result})
    if [ ${versionLocal} -eq 1 ]; then
        echo ${result}
        exit 0
        else
        echo -
        exit 0
    fi
fi
#Build Number +... Included All that include a build number return themselves only

}

removeFirstDot(){
local ln=${#1}
local count=1
local test=""
while [ ${count} -lt ${ln} ]; do
    test=`expr substr ${1} ${count} 1`
    if [ ${test} = "." ]; then
        echo `expr substr ${1} $((${count}+1)) $((${#1}-${count}))`
        exit 0
    else
        let count+=1
    fi
done
}
#take in a number Major, Minor, and Patch numbers and return the that number or a greater number if found in local
#else return one or more -1's
getGreatest(){
echo -e '\e[1;34m'[935] 'getGreatest() 1='${1} '2='${2} '3='${3}'\e[0m' >> ${cwd}/lnpm.log
local vpiece=""
local test=""
local v1=0
local v2=0
local v3=0
local v1out=$1
local v2out=$2
local v3out=$3
local localVerFound=false
echo [944] 'currentversions[@]='${currentversions[@]} >> ${cwd}/lnpm.log
for pc in ${currentversions[@]}; do
echo [936] 'pc='${pc} >> ${cwd}/lnpm.log
    vpiece=$(removeFirstDot ${pc})
    v1=${pc%%'.'*}
    v2=${vpiece%%'.'*}
    v3=${pc##*'.'}
    if [ ${v1} -gt ${v1out} ]; then
        v1out=${v1}
        v2out=${v2}
        v3out=${v3}
        localVerFound=true
    else
        if [ ${v1out} -eq ${v1} ]; then
            if [ ${v2} -gt ${v2out} ]; then
                v2out=${v2}
                v3out=${v3}
                localVerFound=true
            else
                if [ ${v2} -eq ${v2out} ]; then
                    if [ ${v3} -ge ${v3out} ]; then
                        v2out=${v2}
                        v3out=${v3}
                        localVerFound=true
                    fi
                fi
            fi
        fi
    fi
done
echo [974] 'localVerFound='${localVerFound} >> ${cwd}/lnpm.log
if [ ${localVerFound} = true ]; then
    echo ${v1out}.${v2out}.${v3out}
else
    echo -1.-1.-1
fi
}

getMajorGreatestOrEqual(){
local vpiece=""
local test=""
local v1=0
local v2=0
local v3=0
local v1out=$1
local v2out=$2
local v3out=$3
local localVerFound=false
for pc in ${currentversions[@]}; do
    vpiece=$(removeFirstDot ${pc})
    v1=${pc%%'.'*}
    v2=${vpiece%%'.'*}
    v3=${pc##*'.'}
    if [ ${v1} -gt ${v1out} ]; then
        v1out=${v1}
        v2out=${v2}
        v3out=${v3}
        localVerFound=true
    else
        if [ ${v1} -eq ${v1out} ]; then
            if [ ${v2} -gt ${v2out} ]; then
                v2out=${v2}
                v3out=${v3}
                localVerFound=true
            else
                if [ ${v2} -eq ${v2out} ]; then
                    if [ ${v3} -gt ${v3out} ]; then
                        v3out=${v3}
                        localVerFound=true
                    else
                        if [ ${v3} -eq ${v3out} ]; then
                        localVerFound=true
                        fi
                    fi
                fi
            fi
        fi
    fi
done
if [ ${localVerFound} = true ]; then
    echo ${v1out}.${v2out}.${v3out}
else
    echo -1.-1.-1
fi
}
#Returns first version that is less than or equal input if local
getLessOrEqual(){
local vpiece=""
local v1=0
local v2=0
local v3=0
local v1out=$1
local v2out=$2
local v3out=$3
for pc in ${currentversions[@]}; do
    vpiece=$(removeFirstDot ${pc})
    v1=${pc%%'.'*}
    v2=${vpiece%%'.'*}
    v3=${pc##*'.'}
    if [ ${v1} -lt ${v1out} ]; then
        v1out=${v1}
        v2out=${v2}
        v3out=${v3}
        echo ${v1out}.${v2out}.${v3out}
        exit 0
    else
        if [ ${v1} -eq ${v1out} ]; then
            if [ ${v2} -lt ${v2out} ]; then
                v1out=${v1}
                v2out=${v2}
                v3out=${v3}
                echo ${v1out}.${v2out}.${v3out}
                exit 0
            else
                if [ ${v2} -eq ${v2out} ]; then
                    if [ ${v3} -lt ${v3out} ]; then
                        v1out=${v1}
                        v2out=${v2}
                        v3out=${v3}
                        echo ${v1out}.${v2out}.${v3out}
                        exit 0
                    else
                        if [ ${v3} -eq ${v3out} ]; then
                            v1out=${v1}
                            v2out=${v2}
                            v3out=${v3}
                            echo ${v1out}.${v2out}.${v3out}
                            exit 0
                        else
                            echo -1.-1.-1
                            exit 0
                        fi
                    fi
                fi
            fi
        fi
    fi
done
echo -1.-1.-1

}
#Return return version less than input if local
getLess(){
echo -e '\e[1;34m'[1089] 'getLess()'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
local vpiece=""
local v1=0
local v2=0
local v3=0
local v1out=$1
local v2out=$2
local v3out=$3
for pc in ${currentversions[@]}; do
    vpiece=$(removeFirstDot ${pc})
    v1=${pc%%'.'*}
    v2=${vpiece%%'.'*}
    v3=${pc##*'.'}
    if [ ${v1} -lt ${v1out} ]; then
        v1out=${v1}
        v2out=${v2}
        v3out=${v3}
        echo ${v1out}.${v2out}.${v3out}
        exit 0
    else
        if [ ${v1} -eq ${v1out} ]; then
            if [ ${v2} -lt ${v2out} ]; then
                v1out=${v1}
                v2out=${v2}
                v3out=${v3}
                echo ${v1out}.${v2out}.${v3out}
                exit 0
            else
                if [ ${v2} -eq ${v2out} ]; then
                    if [ ${v3} -lt ${v3out} ]; then
                        v1out=${v1}
                        v2out=${v2}
                        v3out=${v3}
                        echo ${v1out}.${v2out}.${v3out}
                        exit 0
                    else
                        echo -1.-1.-1
                        exit 0
                    fi
                fi
            fi
        fi
    fi
done
echo -1.-1.-1

}

getStartsWith(){
#get major release d
echo -e '\e[1;34m'[1139] 'getStartsWith'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
local pkg=$1
local vin=$2
local testv=0
local vpiece=0
local v1=-1
local v2=-1
local v3=-1
local patchver=0
    rgx='^[0-9][0-9]*$'
    if [[ ${vin} =~ $rgx ]]; then
        v1=${vin}
        testv=$(getSubRelease ${v1} ${v2} ${v3})
        patchver=${testv##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${vin}
            testv=$(getSubRelease ${v1} ${v2} ${v3})
        fi
        echo ${testv}
        exit 0
    fi
    #get major release and minor release d.d
    rgx='^[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${vin} =~ $rgx ]]; then
        v1=${vin%%'.'*}
        v2=${vin##*'.'}
        testv=$(getSubRelease ${v1} ${v2} ${v3})
        patchver=${testv##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${vin}
            testv=$(getSubRelease ${v1} ${v2} ${v3})
        fi
        echo ${testv}
        exit 0
    fi
    #get major release and minor release and patch release d.d.d
    rgx='^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${vin} =~ $rgx ]]; then
        vpiece=$(removeFirstDot ${vin})
        v1=${vin%%'.'*}
        v2=${vpiece%%'.'*}
        v3=${vin##*'.'}
        testv=$(getSubRelease ${v1} ${v2} ${v3})
        patchver=${testv##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${vin}
            testv=$(getSubRelease ${v1} ${v2} ${v3})
        fi
        echo ${testv}
        exit 0
    fi
echo ${testv}
exit 0
}

getSubRelease(){
local vpiece=""
local v1=0
local v2=0
local v3=0
local v1out=$1
local v2out=$2
local v3out=$3
for pc in ${currentversions[@]}; do
    vpiece=$(removeFirstDot ${pc})
    v1=${pc%%'.'*}
    v2=${vpiece%%'.'*}
    v3=${pc##*'.'}
    if [ ${v1} -eq ${v1out} ]; then
        v1out=${v1}
        if [ ${v2} -eq ${v2out} ] || [ ${v2out} -eq -1 ]; then
                v1out=${v1}
                v2out=${v2}
                if [ ${v3} -eq ${v3out} ] || [ ${v3out} -eq -1 ]; then
                        v1out=${v1}
                        v2out=${v2}
                        v3out=${v3}
                        echo ${v1out}.${v2out}.${v3out}
                        exit 0
                fi
        fi
    fi
done
echo -1.-1.-1
}

anyVersion(){
#check if latest version is already local and if not update it
local pkg=$1
local blockechowiththis=$(updateLocalPackage ${pkg})
local iver=$(getLatestLocalVer ${pkg})
echo ${iver}
}

exactVersion(){
echo -e '\e[1;34m'[1240] 'exactVersion()'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
local pkg=$1
local ver=$2
local loc=$(isLocal ${pkg} ${ver})
echo [1239] 'loc='${loc} >> ${cwd}/lnpm.log
if [ ${loc} -lt 1 ]; then
    remoteInstall ${pkg} ${ver}
fi
echo ${ver}
}
#A compatible version is anything less that the major release number except in the case of ^0.0.x (refactor later)
compatibleVersion(){
local pkg=$1
local ver=$2
#drop the ^
local verin=`expr substr ${2} 2 $((${#2}-1))`
#get major release x
local rgx='^[0-9][0-9]*$'
local v1=-1
local v2=-1
local v3=-1
local testver=""
local patchver=0
if [[ ${verin} =~ $rgx ]]; then
    v1=${verin}
    v2=-1
    v3=-1
    testver=$(getGreatest ${v1} ${v2} ${v3})
    patchver=${testver##*'.'}
    if [ ${patchver} -eq -1 ]; then
        remoteInstall ${pkg} ${ver}
        testver=$(getGreatest ${v1} ${v2} ${v3})
    fi
    echo ${testver}
    exit 0
fi
#^1.2.3 := >=1.2.3-0 <2.0.0-0 "Compatible with 1.2.3". When using caret operators, anything from the specified version (including prerelease) will be supported up to, but not including, the next major version (or its prereleases). 1.5.1 will satisfy ^1.2.3, while 1.2.2 and 2.0.0-beta will not.
rgx='^[0-9][0-9]*\.[0-9][0-9]*$'
if [[ ${verin} =~ $rgx ]]; then
    v1=${verin%%'.'*}
    v2=-1
    v3=-1
    testver=$(getGreatest ${v1} ${v2} ${v3})
    patchver=${testver##*'.'}
    if [ ${patchver} -eq -1 ]; then
        remoteInstall ${pkg} ${ver}
        testver=$(getGreatest ${v1} ${v2} ${v3})
    fi
echo ${testver}
exit 0
fi
#^0.x.x versions are special: the first non-zero component indicates potentially breaking changes, meaning the caret operator matches any version with the same first non-zero component starting at the specified version.^0.0.2 := =0.0.2 "Only the version 0.0.2 is considered compatible"
rgx='^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
if [[ ${verin} =~ $rgx ]]; then
    vpiece=$(removeFirstDot ${verin})
        v1=${verin%%'.'*}
        v2=${vpiece%%'.'*}
        v3=${verin##*'.'}
    if [ ${v1} -gt 0 ]; then
        v2=-1
        v3=-1
    else
        if [ ${v2} -gt 0 ]; then
            v3=-1
        fi
    fi
    testver=$(getGreatest ${v1} ${v2} ${v3})
    patchver=${testver##*'.'}
    if [ ${patchver} -eq -1 ]; then
        remoteInstall ${pkg} ${ver}
        testver=$(getGreatest ${v1} ${v2} ${v3})
    fi
echo ${testver}
exit 0
fi
}

reasonablyClose(){
echo -e '\e[1;34m'[1319] 'reasonablyClose()'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
local pkg=$1
local verstr=$2
local v1=-1
local v2=-1
local v3=-1
#drop the ~
local verin=`expr substr ${verstr} 2 $((${#verstr}-1))`
    #get major release x
local rgx='^[0-9][0-9]*$'
local testver=""
local patchver=0
if [[ ${verin} =~ $rgx ]]; then
    v1=${verin}
    testver=$(getSubRelease ${v1} ${v2} ${v3} )
    patchver=${testver##*'.'}
    if [ ${patchver} -eq -1 ]; then
        remoteInstall ${pkg} ${verstr}
        testver=$(getSubRelease ${v1} ${v2} ${v3})
    fi
echo ${testver}
exit 0
fi
#get major release and minor release x.x
rgx='^[0-9][0-9]*\.[0-9][0-9]*$'
if [[ ${verin} =~ $rgx ]]; then
    v1=${verin%%'.'*}
    v2=${verin##*'.'}
    v3=-1
    testver=$(getSubRelease ${v1} ${v2} ${v3} )
    patchver=${testver##*'.'}
    if [ ${patchver} -eq -1 ]; then
        remoteInstall ${pkg} ${verstr}
        testver=$(getSubRelease ${v1} ${v2} ${v3})
    fi
echo ${testver}
exit 0
fi
#~1.2.3 := >=1.2.3-0 <1.3.0-0 "Reasonably close to 1.2.3". When using tilde operators, prerelease versions are supported as well, but a prerelease of the next significant digit will NOT be satisfactory, so 1.3.0-beta will not satisfy ~1.2.3.
rgx='^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
if [[ ${verin} =~ $rgx ]]; then
    vpiece=$(removeFirstDot ${verin})
    v1=${verin%%'.'*}
    v2=${vpiece%%'.'*}
    v3=-1
    testver=$(getSubRelease ${v1} ${v2} ${v3})
    patchver=${testver##*'.'}
    if [ ${patchver} -eq -1 ]; then
        remoteInstall ${pkg} ${verstr}
        testver=$(getSubRelease ${v1} ${v2} ${v3})
    fi
echo ${testver}
exit 0
fi
echo ${verin}
exit 0
}

greaterThanEqual(){
local pkg=${1}
local verstr=${2}
#Remove >=
local verin=`expr substr ${2} 3 $((${#2}-2))`
local v1=-1
local v2=-1
local v3=-1
local testver=-1
local patchver=0
#get major release x
    rgx='^[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        v1=${verin}
        v2=-1
        v3=-1
        testver=$(getMajorGreatestOrEqual ${v1} ${v2} ${v3})
        patchver=${testver##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${ver}
            testver=$(getMajorGreatestOrEqual ${v1} ${v2} ${v3})
        fi
        echo ${testver}
        exit 0
    fi
    #get major release and minor release x.x
    rgx='^[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        v1=${verin%%'.'*}
        v2=${verin##*'.'}
        v3=-1
        testver=$(getMajorGreatestOrEqual ${v1} ${v2} ${v3})
        patchver=${testver##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${ver}
            testver=$(getMajorGreatestOrEqual ${v1} ${v2} ${v3})
        fi
        echo ${testver}
        exit 0
    fi
    #get major release and minor release and patch release x.x.x
    rgx='^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        vpiece=$(removeFirstDot ${verin})
        v1=${verin%%'.'*}
        v2=${vpiece%%'.'*}
        v3=${verin##*'.'}
        testver=$(getMajorGreatestOrEqual ${v1} ${v2} ${v3})
        patchver=${testver##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${ver}
            testver=$(getMajorGreatestOrEqual ${v1} ${v2} ${v3})
        fi
        echo ${testver}
        exit 0
    fi
echo ${2}
exit 0
}

lessThanEqual(){
echo -e '\e[1;34m'[1452] 'lessThanEqual()'${1} ''${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
local pkg=$1
local verstr=$2
local v1=-1
local v2=-1
local v3=-1
local testver=-1
local patchver=0
#remove <=
local verin=`expr substr ${verstr} 3 $((${#verstr}-2))`
#get major release x
    rgx='^[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        v1=${verin}
        v2=-1
        v3=-1
        testver=$(getLessOrEqual ${v1} ${v2} ${v3})
        patchver=${testver##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${verstr}
            testver=$(getLessOrEqual ${v1} ${v2} ${v3})
        fi
        echo ${testver}
        exit 0
    fi
    #get major release and minor release x.x
    rgx='^[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        v1=${verin%%'.'*}
        v2=${verin##*'.'}
        v3=-1
        testver=$(getLessOrEqual ${v1} ${v2} ${v3})
        patchver=${testver##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${verstr}
            testver=$(getLessOrEqual ${v1} ${v2} ${v3})
        fi
        echo ${testver}
        exit 0
    fi
    #get major release and minor release and patch release x.x.x
    rgx='^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        vpiece=$(removeFirstDot ${verin})
        v1=${verin%%'.'*}
        v2=${vpiece%%'.'*}
        v3=${verin##*'.'}
        testver=$(getLessOrEqual ${v1} ${v2} ${v3})
        patchver=${testver##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${verstr}
            testver=$(getLessOrEqual ${v1} ${v2} ${v3})
        fi
        echo ${testver}
        exit 0
    fi
echo ${2}
exit 0
}

lessThanVersion(){
local pkg=$1
local verstr=$2
local v1=-1
local v2=-1
local v3=-1
local testver=-1
local patchver=0
#remove <
local verin=`expr substr ${verstr} 2 $((${#verstr}-1))`
    #get major release x
    rgx='^[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        v1=${verin}
        v2=-1
        v3=-1
        testver=$(getLess ${v1} ${v2} ${v3})
        patchver=${testver##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${verstr}
            testver=$(getLess ${v1} ${v2} ${v3})
        fi
        echo ${testver}
        exit 0
    fi
    #get major release and minor release x.x
    rgx='^[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        v1=${verin%%'.'*}
        v2=${verin##*'.'}
        v3=-1
        testver=$(getLess ${v1} ${v2} ${v3})
        patchver=${testver##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${verstr}
            testver=$(getLess ${v1} ${v2} ${v3})
        fi
        echo ${testver}
        exit 0
    fi
    #get major release and minor release and patch release x.x.x
    rgx='^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        vpiece=$(removeFirstDot ${verin})
        v1=${verin%%'.'*}
        v2=${vpiece%%'.'*}
        v3=${verin##*'.'}
        testver=$(getLess ${v1} ${v2} ${v3})
        echo [1570] 'testver='${testver} >> ${cwd}/lnpm.log
        patchver=${testver##*'.'}
        if [ ${patchver} -eq -1 ]; then
            remoteInstall ${pkg} ${verstr}
            testver=$(getLess ${v1} ${v2} ${v3})
        fi
        echo ${testver}
        exit 0
    fi
echo ${2}
exit 0
}

greaterThanVersion(){
echo -e ${blue}[1593] 'greaterThanVersion()' ${1} ${2} ${3}${default} >> ${cwd}/lnpm.log
local pkg=$1
local verstr=$2
local v1=-1
local v2=-1
local v3=-1
local testver=-1
local remoteAdded=0
#remove >
local verin=`expr substr ${verstr} 2 $((${#verstr}-1))`
    #get major release x
    rgx='^[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        v1=${verin}
        v2=-1
        v3=-1
        testver=$(getGreatest ${v1} ${v2} ${v3})
        v3=${testver##*'.'}
        echo [1609] 'testver='${testver} >> ${cwd}/lnpm.log
        if [ ${v3} -eq -1 ]; then
            remoteInstall ${pkg} ${verstr}
            testver=$(getGreatest ${v1} ${v2} ${v3})
        fi
    fi
    #get major release and minor release x.x
    rgx='^[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        v1=${verin%%'.'*}
        v2=${verin##*'.'}
        v3=-1
        testver=$(getGreatest ${v1} ${v2} ${v3})
        v3=${testver##*'.'}
        if [ ${v3} -eq -1 ]; then
            remoteInstall ${pkg} ${verstr}
            testver=$(getGreatest ${v1} ${v2} ${v3})
        fi
    fi
    #get major release and minor release and patch release x.x.x
    rgx='^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
    if [[ ${verin} =~ $rgx ]]; then
        vpiece=$(removeFirstDot ${verin})
        v1=${verin%%'.'*}
        v2=${vpiece%%'.'*}
        v3=${verin##*'.'}
        testver=$(getGreatest ${v1} ${v2} ${v3})
        v3=${testver##*'.'}
        if [ ${v3} -eq -1 ]; then
            remoteInstall ${pkg} ${verstr}
            testver=$(getGreatest ${v1} ${v2} ${v3})
        fi
    fi
    echo [1643] 'testver='${testver} 'verin='${verin} >> ${cwd}/lnpm.log
    if [ ${testver} = ${verin} ]; then
        echo ${2}
    else
    echo [1647] 'testver='${testver} >> ${cwd}/lnpm.log
        echo ${testver}
    fi
}

anySubVersionX(){
local pkg=$1
local verin=$2
#remove x or * and .
local verin=`expr substr ${verin} 1 $((${#verin}-2))`
    echo $(getStartsWith ${pkg} ${verin})
    exit 0
}

anySubVersionD(){
local pkg=$1
local verin=$2
echo $(getStartsWith ${pkg} ${verin})
exit 0
}

preReleaseVersion(){
local pkg=$1
echo ${2}
exit 0
}

writelink(){
# $1 package name $2 package version
local nmd=$(find ${cwd}/node_modules -maxdepth 0 )
if [ "${nmd}" != "${cwd}/node_modules" ]; then
    echo -e ${green}Creating project symbolic link folder${default}
    mkdir ${cwd}/node_modules
fi
local nsl=$(find ${cwd}/node_modules/$1 -maxdepth 0)
if [ "${nsl}" != "${cwd}/node_modules/${1}" ]; then
    echo -e ${green}Creating symbolic link for ${1}${default}
    ln -s ${nd}/$1"--"$2 ${cwd}/node_modules/$1
else
    #remove existing link first
    rm ${cwd}/node_modules/$1
    echo -e ${green}Creating new symbolic link for ${1}${default}
    ln -s ${nd}/$1"--"$2 ${cwd}/node_modules/$1
fi
}

isLocal(){
echo -e '\e[1;34m'[1697] 'isLocal() pkg='${1} 'ver='${2} ''${3} >> ${cwd}/lnpm.log
splitdirnames
local count=0
local pkg=$1
local ver=$2
for pk in ${pkglist[@]}; do
    if [ "${pk}" = "${pkg}" ]; then
        if [ "${verlist[${count}]}" = "${ver}" ]; then
            echo 1
            exit 0
        fi
    fi
    let count+=1
done
echo 0
}

remoteInstall(){
echo [1702] 'remoteInstall() pkg='${1} 'ver='${2} ''${3} >> ${cwd}/lnpm.log
local pkg=$1
local ver=$2
cd ${nd}
#direct output of npm install to variable to keep it from being returned with echo from this function
local npmoutput=$(npm install ${pkg}@${ver})
echo [1680] 'npmoutput='${npmoutput} ''${2} ''${3} >> ${cwd}/lnpm.log
setupDirs
setPackageCount ${pkg}
cd ${cwd}
}

setNodeDir(){
local nmd=$(find ${pkginstall} -maxdepth 0 )
if [ "${nmd}" != "${pkginstall}" ]; then
    mkdir ${pkginstall}
fi
nmd=$(find ${pkginstall} -maxdepth 0 )
if [ "${nmd}" = "${pkginstall}" ]; then
    echo export LNPMDIR=${pkginstall} >> ~/.bashrc
    echo -e ${green}lnpm local directory set successfully${default}
else
    echo -e ${red}lnpm local directory set FAILED${default}
fi
}

copypkg(){
local pkgin=${1}
echo -e '\e[1;34m'[1701] 'copypkg() 1='${pkgin} '2='${2} ''${3}'\e[0m' >> ${cwd}/lnpm.log
setpackage ${pkgin}
echo [1702] 'Selected version='${pkgver} 'path='${pkgpath} >> ${cwd}/lnpm.log
mkdir ${cwd}/node_modules -p

local nsl=$(find ${cwd}/node_modules/$pkgin -maxdepth 0)
if [ "${nsl}" != "${cwd}/node_modules/${1}" ]; then
    echo [1708] 'no sl for '${pkgin} 'copying directory from local' >> ${cwd}/lnpm.log
    echo [1709] 'pkgpath='${pkgpath} 'cwd='${cwd} 'pkgin='${pkgin} 'pkgver=' ${pkgver} >> ${cwd}/lnpm.log
    #Must use nd and cwd from the root of script to properly copy because functions execute in their own evironment
    #Which means that files and directories are out of scope
    cp ${nd}/${pkgin}--${pkgver} ${cwd}/node_modules/${pkgin} -a -R
else
    #remove existing link first or directory, which allows using copy to change versions
    echo [1708] 'sl for '${pkgin} 'exists, deleting' >> ${cwd}/lnpm.log
    rm ${cwd}/node_modules/$pkgin -R
    echo [1713] 'Deleted link, now copying local directory as '${pkgin} >> ${cwd}/lnpm.log
    echo [1715] 'pkgpath='${pkgpath} 'cwd='${cwd} 'pkgin='${pkgin} 'pkgver=' ${pkgver} >> ${cwd}/lnpm.log
    cp ${nd}/${pkgin}--${pkgver} ${cwd}/node_modules/${pkgin} -a -R
fi
}
#/////////////////////////////////////////////////SCRIPT START//////////////////////////////////////////////////////////
#validate input
#rchek=$(find ${nd})
#if [ "${rchek}" != "${nd}" ]; then
    #echo -e ${red}"Node modules directory invalid. Set var nd on line 10 to valid path for local node modules"${default}
    #exit 1
#else
#Store all parameters except first (and last if preceeded by a -) in params, first is the command and last is any modifier
count=1
echo [1734] 'paramcount'${#} >> ${cwd}/lnpm.log
for pars in ${*}; do
    if [ ${count} -gt 1 ]; then
        if [ ${count} -lt ${#} ];
        then
            params+=(${pars})
        else
            regx='^-[\w]*'
            if [[ "${pars}" =~ $regx ]]; then
                modparam=${pars}
            else
                params+=(${pars})
            fi
        fi
    fi
    let count+=1
done
echo [1735] 'params='${params[@]} 'modparam='${modparam} >> ${cwd}/lnpm.log
echo -e '\e[1;34m'[1730] 'Swtich Statement Begins 1='${1}'\e[0m' >> ${cwd}/lnpm.log
    case $1 in
        'install')
            check3
            for pak in ${params[@]}; do
            install ${pak}
            done
            exit 0
        ;;
        'update')
            update
            exit 0
        ;;
        'configure')
            setupDirs
            exit 0
        ;;
        'revert')
            echo -e ${yellow}'Reverting local node package directories will break all projects relying on lnpm'${default}
            echo -e ${yellow}'Make sure to remove the path from each package entry in package.json and run npm  install'${default}
            echo -e ${yellow}'in the projects directory for each lnpm project you wish to make an npm'${default}
            echo -e ${yellow}'Since lnpm allows you to store multiple package versions by adding the version number to the'${default}
            echo -e ${yellow}'directory name (normally just package name), this proccess will not alter'${default}
            echo -e ${yellow}'directory names that are part multi packages you will need to rename the version desired manually'${default}
            echo -e ${yellow}'Enter yes to continue'${default}
            read
            if [ "$REPLY" != 'yes' ]; then
                exit 0
            fi
            revertDirs
            exit 0
        ;;
        'convert')
            echo -e ${yellow}'Existing node directories will be replaced with symbolic links to local directory'${default}
            echo -e ${yellow}'Enter yes to continue'${default}
            read
            if [ "$REPLY" != 'yes' ]; then
                exit 0
            fi
            rm node_modules -R
            mkdir node_modules
            convert
            exit 0
        ;;
        'setNodedir')
            setNodeDir
            exit 0
        ;;
        'copy')
        #In cases where the node package will not accept being a link the package is copied to the project directory
        #The global var copy is set to true and the normal install proccess is carried out except it will copy insead
        #of creating a link
            copy=true
            for cpkg in ${params[@]}; do
            copypkg ${cpkg}
            done
        ;;
        *)
            echo -e ${red}'Invalid First Parameter'${default}
            echo -e ${green}'Valid First Parameters are: install, configure, convert, update, revert and copy'${default}
            exit 0
        ;;
    esac
#fi