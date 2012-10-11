#!/bin/sh

doc_root="/Users/luke/Sites/mcode/mercynet"
settings_file="/Users/luke/Sites/mcode/settings.php"
db_to_import="/Users/luke/Sites/mcode/db.sql"
db_name="mercy_$1"

# TODO:
# read these from teh settings_file instead of re-declairing them
db_username=""
db_password=""
db_host=""

# get us to where we're going
cd $doc_root

# check to see if the local branch already exists, and if it does, stash any changes and check it out
if [ "$(git status | grep 'nothing to commit')" ]
then
  echo "You were working on a clean branch. Well done!"
else
  /bin/echo -n "You have uncommitted changes in your working branch. Would you like to stash those changes? [y/n]: "
  read STASH
  
  case $STASH in
    n)
      echo "Commit or stash your changes then re-run the script."
      exit
      ;;
    y)
      echo "Stashing your changes."
      git stash
      ;;
    esac
fi


# todo:
# handle multiple results from the grep (ie: user entered "solr" and
# matching branches include "solrInstall" and "solrInstallSettings")

# if the branch doesn't exist locally, create it at local/branch-name
branch="local/$1"
if [ "`git branch -l | grep $branch`" ] 
then
  echo "Checking out: $branch"
  git checkout $branch
  
  # todo:
  # maybe offer a fetch/rebase??

else
  
  /bin/echo -n "Is this a:
   1) Branch
   2) Tag: "
  
  read tag_or_branch
  
  case $tag_or_branch in
    1)
      type=branch
      ;;
    2)
      type=tags
      ;;
    esac
  
  git checkout -b $branch $type/$1
  echo "Checkout out the remote $type"
fi



# prompt me if i want a new database or not
/bin/echo -n "Would you to create a new database (named $db_name) for this codebase? [y/n]: "
read new_db

case $new_db in
  y)
   
    # create the database and import the data
    /bin/echo "Importing the database. This may take a few minutes."
    CREATE_DB=$(mysql -u$db_username -p$db_password -h$db_host -e "CREATE DATABASE $db_name")
    IMPORT_DB=$(mysql -u$db_username -p$db_password -h$db_host $db_name < $db_to_import)
  
    # reconfigure the settings.php file
    sed "s/\$databases\['default'\]\['default'\]\['database'\]='.*'/\$databases['default']['default']['database']='$db_name'/g" $settings_file > tmp
    mv tmp $settings_file
  
  ;;
  n)
    #do nothing
    exit
  ;;

esac
