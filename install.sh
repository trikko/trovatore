echo ""

case "$OSTYPE" in
   linux*) PACKAGE="linux/trovatore";;
   darwin*)
      if [[ $(uname -m) == "arm64" ]]; then
         PACKAGE="macos-14/trovatore"
      else
         PACKAGE="macos-13/trovatore"
      fi
      ;;

   *)
      echo "$OSTYPE auto-install not supported."
      return 1
      ;;
esac

bin_candidate=( "$HOME/.local/bin" "$HOME/.bin" "$HOME/bin" "/usr/local/bin" )
user_bin_dirs=( )
sudo_bin_dirs=( )

# Which dir is writable?
for p in ${bin_candidate[@]}; do

   if [[ ":$PATH:" == *":$p:"* ]]
   then
      if [[ -w $p ]]
      then
         user_bin_dir+=($p)
      else
         sudo_bin_dir+=($p)
      fi;
   fi;

done;

# Trying user dir
if [[ ${#user_bin_dir[@]} -gt 0 ]]
then
   curl -sLo ${user_bin_dir[0]}/trovatore "https://trikko.github.io/trovatore/$PACKAGE"

   if [[ $? -eq 0 ]]
   then
      chmod +x ${user_bin_dir[0]}/trovatore
      echo "Installed: '${user_bin_dir[0]}/trovatore'"
      exit 0
   else
      echo "Installation fail"
      exit 1
   fi;
fi;

# System dir
if [[ ${#sudo_bin_dir[@]} -gt 0 ]]
then
   echo "trovatore will be installated in '${sudo_bin_dir[0]}'"
   curl -sLo ${sudo_bin_dir[0]}/trovatore "https://trikko.github.io/trovatore/$PACKAGE"

   if [[ $? -eq 0 ]]
   then
      chmod +x ${sudo_bin_dir[0]}/trovatore
      echo "Installed: '${sudo_bin_dir[0]}/trovatore'"
      exit 0
   else
      echo "Installation fail"
      exit 1
   fi;
fi;

echo "Can't find a directory to install trovatore. Please report this issue."
echo "You can download the binary package here: https://trikko.github.io/trovatore/$PACKAGE"

