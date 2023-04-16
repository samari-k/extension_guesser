# File Extension Guesser

A bash script to identify files with a tampered extension by making an educated guess based on the MIME type.

## Usage

```bash
./extension_guesser.sh [OPTIONS] FILE [FILE ...]
```

### Options:

* `-r`, `--rename`:  Rename file(s) to the correct extension
* `-v`, `--verbose`: Print more information about each file
* `-h`, `--help`:    Print this help message and exit

### Example:

```bash
./extension_guesser.sh --verbose --rename *.jpg
```

This command will check all files with the .jpg extension in the current directory. For each file that has a suspicious extension, the script will suggest a new extension and rename the file.

![screenshot](/home/safi/Documents/Uni/1733/extensionguesser/eg_screenshot.png)

## Condensed oneliner

Not in need for fancy coloured output and automated renaming? Try this oneliner instead:

`for file in *; do exts=`grep "$(file -b --mime-type $file)\s" /etc/mime.types | sed 's/\s/ /g' | tr -s ' ' | cut -d ' ' -f 1 --complement`; ext=`echo "$file" | cut -d "." -f 2`; if [[ ! "$exts[@]" =~ "$ext" ]]; then echo "$file should be `echo $exts | awk '{printf $1}'`";fi;done`
