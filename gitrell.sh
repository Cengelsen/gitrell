#!/bin/sh
: <<'END'

USER BEWARE!

This script does not currently account for the following scenarios:

1. You have a local branch, that you've made yourself, without setting upstream branch
2. Somebody else has deleted the remote branch, without your knowledge. 

This script is intended mainly for the scenario where you have finished and merged a branch
on a different machine. This script should not be within the repo folder, but rather in
the root folder of all your repo-folders. However, you can comment out line 19, 21 an 65 if
you want to use it in a single repo folder. 
END

for folder in $PWD/*/; 
do
       repo=${folder%*/};
       cd $repo/;
       folderName=$(basename $PWD)
       echo -e "-------\nNow working in $folderName. \n-------"
       
       # finds the URL of the repo
       repoURL=$(git remote get-url origin);
       echo $repoURL

       # finds the main branch of the repo
       mainBranch=$(git remote show $repoURL | grep 'HEAD branch' | cut -d' ' -f5);

       # list of local branches
       branches=$(git for-each-ref --format='%(refname:short)' refs/heads)

       # cycles through all local branches
       for branch in $branches;
       do
              # checks if current branch has remote, returns 0 if not 
              branchHasRemote=$(git ls-remote --heads $repoURL $branch | wc -l);
              
              # case when a remote cannot be found
              if [ "$branchHasRemote" -eq "0" ]; then
                     echo "$branch has no remote. Deleting..."
                     git checkout $mainBranch;
                     git branch -D $branch;
                     git fetch; git pull;
                     continue
       
              # case when a remote can be found
              else
                     # Skips the main branch, leaving it for last
                     if [ "$branch" == "$mainBranch" ]; then
                            echo "Skipping main branch; $mainBranch" 
                            continue 
                     fi

                     echo "$branch has remote. Fetching & pulling..."
                     git checkout $branch;
                     git fetch; git pull;
                     continue
              fi
       done

       git checkout $mainBranch;
       git fetch; git pull; 
       cd ..;
       echo -e "-------\nStopped working in $folderName. \n-------"
done