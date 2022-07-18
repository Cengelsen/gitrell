#!/bin/sh
: <<'END'

USER BEWARE!

This script does not currently account for the following scenarios:

1. You have a local branch, that you've made yourself, without setting upstream branch
2. Somebody else has deleted the remote branch, without your knowledge. 
3. whether or not the repo has a submodule included

This script is intended mainly for the scenario where you have finished and merged a branch
on a different machine. This script should optimally not be within the repo folder, but rather in
the root folder of all your repo-folders. However, you can of course comment out the necessary 
lines if you want to use it in a single repo folder. 
END

for folder in $PWD/*/; 
do
       # establishes folder and moves into it
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
              
              # case for when a remote cannot be found
              if [ "$branchHasRemote" -eq "0" ]; then

                     read  -n 1 -p "$branch has no remote. Delete local branch? [y/n]:" "deleteLocal"

                     # case for when the user wants to delete local branch
                     if [ $deleteLocal = "y" ]; then
                            echo -e "\nDeleting $branch..."
                            git checkout $mainBranch;
                            git branch -D $branch;
                            git fetch; git pull;
                            continue

                     # case for when the user wants to keep local branch
                     elif [ $deleteLocal = "n" ]; then
                            echo -e "\nSkipping $branch. It was not deleted." 
                            continue
                     fi

              # case for when a remote can be found
              else
                     # Skips the main branch, leaving it for last
                     if [ "$branch" == "$mainBranch" ]; then
                            echo "Skipping main branch; $mainBranch" 
                            continue 
                     fi

                     # pulls changes from remote
                     echo "$branch has remote. Fetching & pulling..."!
                     git checkout $branch;
                     git fetch; git pull;
                     
                     # checks the differences between remote and local
                     localDiff=$(git diff -S "<<<<<<< HEAD" -S "=======" -S ">>>>>>> $(git name-rev --name-only MERGE_HEAD)" HEAD)

                     # case when there is no conflict
                     if [ "$localDiff" == "" ]; then
                            echo "There are no merge-conflicts on $branch."
                            continue

                     # case when there is a conflict
                     elif [ "$localDiff" != "" ]; then

                            # shows conflict
                            echo $localDiff

                            echo "There are merge-conflicts on $branch."
                            echo "\n1) Apply remote version and delete local changes?" 
                            read -n 1 -p "\n2) Keep and apply all local changes? [1/2]:" "mergeChanges"

                            # case for when the user wants to remove local changes
                            if [ "$mergeChanges" = "1" ]; then
                                   read -n 1 -p "\nAre you sure? [y/n]:" "finalDecision"

                                   if [ "$finalDecision" = "y"]; then
                                          
                                          # remove local changes and keep remotes changes
                                          git checkout .;
                                          git clean -f -d;
                                          git reset --hard;
                                          git pull;

                                          continue

                                   elif [ "$finalDecision" = "n"]; then

                                          # pulls and rebases the branch, and specifies the strategy of keeping local changes
                                          git pull --rebase -X theirs;

                                          continue

                            # case for when the user wants to keep all local changes
                            elif [ "$mergeChanges" = "2" ]; then

                                   # pulls and rebases the branch, and specifies the strategy of keeping local changes
                                   git pull --rebase -X theirs;

                                   continue
                            fi
                     fi
              fi
       done

       # finishes by synchronizing the main branch
       git checkout $mainBranch;
       git fetch; git pull; 
       cd ..;
       echo -e "-------\nStopped working in $folderName. \n-------"
done

echo "All your repos are now synchronized!"