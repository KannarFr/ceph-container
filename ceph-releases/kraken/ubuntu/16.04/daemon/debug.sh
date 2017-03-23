#!/bin/bash
set -e

# Bash substitution to remove everything before '='
# and only keep what is after
function extract_param {
  echo "${1##*=}"
}

for option in $(comma_to_space ${DEBUG}); do
  case $option in
    verbose)
      echo "VERBOSE: activating bash debugging mode."
      set -x
      ;;
    fstree*)
      echo "FSTREE: uncompressing content of $(extract_param $option)"
      # NOTE (leseb): the entrypoint should already be running from /
      # This is just a safeguard
      pushd / > /dev/null
      wget -q $(extract_param $option) -O patch.tar

      # Let's find out if the tarball has the / in a sub-directory
      strip_level=0
      for sub_level in $(seq 0 2); do
        tar -tf patch.tar | cut -d "/" -f $((sub_level+1)) | egrep -sqw "bin|etc|lib|lib64|opt|run|usr|sbin|var"
        if [ $? -eq 0 ]; then
          strip_level=$sub_level
          break
        fi
      done
      echo "The main directory is at level $strip_level"
      echo ""
      echo "SHA1 of the archive is: $(sha1sum patch.tar)"
      echo ""
      echo "Now, we print the SHA1 of each file."
      for f in $(tar xfpv patch.tar --strip=$strip_level); do
        if [[ ! -d $f ]]; then
          sha1sum $f
        fi
      done
      rm -f patch.tar
      popd > /dev/null
      ;;
    stayalive)
      echo "STAYALIVE: container will not die if a command fails."
      source docker_exec.sh
      ;;
    *)
      echo "$option is not a valid debug option."
      echo "Available options are: verbose,fstree and stayalive."
      echo "They can be used altogether like this: '-e DEBUG=verbose,fstree=http://myfstree,stayalive"
      exit 1
      ;;
  esac
done