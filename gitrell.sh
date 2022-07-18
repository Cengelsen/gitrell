#!/bin/sh
: <<'END'

USER BEWARE!

This script does not currently account for the following scenarios:

1. You have a local branch, that you've made yourself, without setting upstream branch
2. Somebody else has deleted the remote branch, without your knowledge. 
3. Merge conflicts between remote commits and local commits

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

                     read  -n 1 -p "$branch has no remote. Delete local branch? [y/n]:" "deleteLocal"

                     if [ $deleteLocal = "y" ]; then
                            echo -e "\nDeleting $branch..."
                            git checkout $mainBranch;
                            git branch -D $branch;
                            git fetch; git pull;
                            continue

                     elif [ $deleteLocal = "n" ]; then
                            echo -e "\nSkipping $branch. It was not deleted." 
                            continue
                     fi

              # case when a remote can be found
              else
                     # Skips the main branch, leaving it for last
                     if [ "$branch" == "$mainBranch" ]; then
                            echo "Skipping main branch; $mainBranch" 
                            continue 
                     fi

                     echo "$branch has remote. Fetching & pulling..."!
                     git checkout $branch;
                     git fetch; git pull;
                     
                     localDiff=$(git diff -S "<<<<<<< HEAD" -S "=======" -S ">>>>>>> $(git name-rev --name-only MERGE_HEAD)" HEAD)

                     if [ "$localDiff" == "" ]; then
                            echo "There are no merge-conflicts on $branch."
                            continue
                     
                     # scenarioer:
                     # 1. Det er lokale filer/endringer som ikke er staged, som ligger utenfor en git add
                            # - git diff gir tilbakemelding

                     # 2. Det er lokale filer/endringer som er staged, men som ligger utenfor en git commit
                            # - git diff gir IKKE tilbakemelding
                     
                     # 3. Det er lokale commits som har forandringer.
                            # - git diff gir IKKE tilbakemelding

                     
                     # 1. sjekk om det er lokale forandringer
                            # - om det er unstaged files - spør brukeren: git stash eller git clean -f -d
                            # - om det er staged files - spør brukeren: git stash eller 
                            # - om det er commits - sjekk om det er merge-conflicts og si ifra.

                     # tracked = at filen er lagt til i indeksen til git. Da ligger den i en liste over filer som git følger med på.
                     # staged = at forandringen er lagt til i en commit.
                     
                     # staged tracked file = en fil som følges med på, hvor forandringene er lagt til i hva som skal commites
                     # unstaged tracked file = en fil som følges med på, hvor forandringene IKKE er lagt til i hva som skal commites.
                     # unstaged untracked file = en fil som ikke følges med på, hvor forandringene IKKE er lagt til i hva som skal commites.

                     # git checkout . = fjerner bare forandringer som ikke er staged
                     # git clean -f -d = fjerner bare filer og mapper som både ikke er staged og ikke er tracked.
                     # git reset --hard =  fjerner bare staged filer og unstaged filer som er tracked

                     # burde også si ifra om du har lokale commits, og hvor mange. 
                     # burde også gi brukeren valget å se diff på grenen

                     elif [ "$localDiff" != "" ]; then

                            echo $localDiff

                            echo "There are merge-conflicts on $branch."
                            echo "\n1) Apply remote version and delete local changes?" 
                            read -n 1 -p "\n2) Keep and apply all local changes? [1/2]:" "mergeChanges"

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

                            elif [ "$mergeChanges" = "2" ]; then

                                   # pulls and rebases the branch, and specifies the strategy of keeping local changes
                                   git pull --rebase -X theirs;

                                   continue
                            fi
                     fi
              fi
       done

       git checkout $mainBranch;
       git fetch; git pull; 
       cd ..;
       echo -e "-------\nStopped working in $folderName. \n-------"
done

echo "All your repos are now synchronized!"