function gerrit()
{
    git remote rm gerrit 2> /dev/null
    if [ ! -d .git ]
    then
        echo .git directory not found. Please run this from the root directory of the Android repository you wish to set up.
    fi
    GERRIT_REMOTE=$(cat .git/config | grep git://github.com/omniarmv6 | awk '{ print $NF }' | sed s#git://github.com/##g)
    if [ -z "$GERRIT_REMOTE" ]
    then
        GERRIT_REMOTE=$(cat .git/config | grep http://github.com/omniarmv6 | awk '{ print $NF }' | sed s#http://github.com/##g)
        if [ -z "$GERRIT_REMOTE" ]
        then
          echo Unable to set up the git remote, are you in the root of the repo?
          return 0
        fi
    fi
    CMUSER=`git config --get review.review.androidarmv6.org.username`
    if [ -z "$CMUSER" ]
    then
        git remote add gerrit ssh://review.androidarmv6.org:29418/$GERRIT_REMOTE
    else
        git remote add gerrit ssh://$CMUSER@review.androidarmv6.org:29418/$GERRIT_REMOTE
    fi
    echo You can now push to "gerrit".
}
export -f gerrit
