# Bash Cheat Sheet

## Special variables

```bash
$0 # Name of the script
$1 # First argument
$# # Number of arguments
$@ # All arguments
$? # Exit code of last command
$$ # PID of current process
$! # PID of last background command
```

## Variables

```bash
# Error if variable is not set
rm -rf /${dirname:?}

# Set error message when variable is not set
name=${1:?"Error: parameter missing Name"}
age=${2:?"Error: parameter missing Age"}

# Set default value to "Unknown"
name=${name:-Unknown}

# Find length of variable
hello=world
echo "${#hello}"

# Remove pattern from start of variable (shortest match)
hello=/etc/resolv.conf
echo "${hello#/etc/}" # resolv.conf

# Get filename (longest match)
_url="https://dns.measurement-factory.com/tools/dnstop/src/dnstop-20090128.tar.gz"
echo "${_url##*/}" # dnstop-20090128.tar.gz

# Remove pattern from end of variable (shortest match)
hello=world.txt
echo "${hello%.txt}" # world

# Find and replace
${varName/Pattern/Replacement}
${varName/word1/word2}
${os/Unix/Linux}
${os//Unix/Linux} # Replace all matches

# Substring
${parameter:offset}
${parameter:offset:length}
${variable:position}

# Casing
"${name^}" # Capitalize first letter
"${name^^}" # Capitalize all letters
"${name,}" # Lowercase first letter
"${name,,}" # Lowercase all letters
```

## Conditionals

```bash
# Single line conditionals
rsync -azP somefile server1:/tmp
[ ! $? -eq 0 ] && { echo "error with rsync"; exit 1; } 
[[ -z "${v1}" && -z "${v2}" ]] && { echo "need v1 and v2"; exit 1; }
```

## Loops

```bash
# For loop
for i in {1..5}; do echo $i; done

# While loop
while true; do echo "Hello"; sleep 1; done

# Until loop
until false; do echo "Hello"; sleep 1; done
```
