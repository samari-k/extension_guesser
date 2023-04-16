#! /bin/bash
#
# a script to identify files with a tampered extension
# by making an educated guess based on the MIME type


# define some colors for nicer output
RED="\e[31m"
GREEN="\e[32m"
YELLOW='\e[33m'
BLUE="\e[34m"
MAGENTA='\e[35m'
ENDCOLOR="\e[0m"


print_usage() {
  echo "Usage: $0 [OPTIONS] FILE [FILE ...]"
  echo "Identifies files with a tampered extension"
  echo "by making an educated guess based on the MIME type."
  echo ""
  echo "Options:"
  echo "  -r, --rename  Rename the file to the correct extension"
  echo "  -v, --verbose Print more information about each file"
  echo "  -h, --help    Print this help message and exit"
  echo ""
  echo "Example usage:"
  echo "  $0 --verbose --rename *.jpg"
}


################################
# parse options
################################

longopts="verbose,rename,help"

options=$(getopt -o 'vrh' --long "$longopts" -- "$@")

eval set -- "$options"
verbose='false'
rename='false'

while true; do
  case "$1" in
    -r | --rename) 
      rename='true' 
      shift;;
    -v | --verbose) 
      verbose='true'
      shift;;
    -h | --help) 
      print_usage
      exit;;
    --) shift; break;;
    *)
      print_usage
      exit 1;;
  esac
done

files=$@
if [[ $files == "" ]]; then
  print_usage
  exit 1
fi

################################
# some helper functions
################################

get_ext() {
  ext=`echo "$1" | cut -d "." -f 2`
  echo $ext
}

guess_ext() {
  ext=`grep "$(file -b --mime-type $1)\s" /etc/mime.types | sed 's/\s\s*/ /g' | cut -d ' ' -f 1 --complement`
  #ext=`echo $ext | sed 's/\s/ /g'`
  echo ${ext[@]}
}

no_ext() {
  if $1; then
    echo false
  else
    echo true
  fi
}

best_sugg() {
  echo `echo $@ | cut -d ' ' -f 1`
}

alt_sugg() {
  echo `echo $@ | cut -d ' ' -f 1 --complement`
}


################################
# main logic 
################################

found='false'

for file in ${files[@]}; do
  ext_is=`get_ext $file`
  ext_should=`guess_ext $file`
  mime_type=`file -b --mime-type $file`
  if [[ "${ext_should[@]}" =~ "$ext_is" ]]; then
    if $verbose; then
      echo -e "${GREEN}[+] $file is fine.${ENDCOLOR}"
    fi
  else
    found='true'
    if [[ $ext_should != "" ]]; then
      echo -e "${RED}[!] $file should be renamed to `best_sugg $ext_should`${ENDCOLOR}"
      if $verbose; then
        echo -e "    based on MIME type: $mime_type"
        echo -e "    less likely: `alt_sugg $ext_should`"
      fi
    else
      echo -e "${MAGENTA}[?] $file: No extension found. Check manually."
      echo -e "    MIME type: $mime_type ${ENDCOLOR}"
    fi
    if $rename; then
      new_ext=`best_sugg $ext_should`
      new_name=`basename $file .$ext_is`".$new_ext"
      if [[ $new_ext != "" ]]; then
        mv $file $new_name
        echo -e "${YELLOW}[-] Renamed $file to $new_name${ENDCOLOR}"
      fi
    fi
  fi
done  


################################
# final information
################################

if [[ -z $rename ]]  && $found; then
  echo -e "${BLUE}[i] rerun this script with the --rename option to rename the files automatically.${ENDCOLOR}"
fi
if $rename && [[ ! $found ]]; then
  echo -e "${GREEN}[i] Everything is fine.${ENDCOLOR}"
fi


################################
# condensed to a oneliner
################################
# for file in *; do exts=`grep "$(file -b --mime-type $file)" /etc/mime.types | sed 's/\s\s*/ /g' | cut -d ' ' -f 1 --complement`; ext=`echo "$file" | cut -d "." -f 2`; if [[ ! "$exts[@]" =~ "$ext" ]]; then echo "$file should be `echo $exts | cut -d ' ' -f 1`";fi;done
