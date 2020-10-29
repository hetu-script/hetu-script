git checkout nightly
git add -A
git commit -m %*
git push origin nightly
git checkout master
git merge nightly
git push origin master
git checkout nightly