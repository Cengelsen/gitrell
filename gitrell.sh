for repo in $PWD/*/; do
       repo=${repo%*/};	
       cd $repo/; git pull; cd ..;
done;
