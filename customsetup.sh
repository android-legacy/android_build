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

function upstream()
{
    git remote rm upstream 2> /dev/null
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
    GERRIT_REMOTE=$(echo $GERRIT_REMOTE | grep omniarmv6 | awk '{ print $NF }' | sed s#omniarmv6#omnirom#g)
    git remote add upstream git://github.com/$GERRIT_REMOTE.git
    echo You can now fetch from "upstream".
}
export -f upstream

function caf()
{
    git remote rm caf 2> /dev/null
    if [ ! -d .git ]
    then
        echo .git directory not found. Please run this from the root directory of the Android repository you wish to set up.
    fi
    PROJECT=`pwd -P | sed s#$ANDROID_BUILD_TOP/##g`
    if (echo $PROJECT | grep -qv "^device")
    then
        PFX="platform/"
    fi
    git remote add caf git://codeaurora.org/$PFX$PROJECT.git
    echo "Remote 'caf' created"
}
export -f caf

function aosp()
{
    git remote rm aosp 2> /dev/null
    if [ ! -d .git ]
    then
        echo .git directory not found. Please run this from the root directory of the Android repository you wish to set up.
    fi
    PROJECT=`pwd -P | sed s#$ANDROID_BUILD_TOP/##g`
    if (echo $PROJECT | grep -qv "^device")
    then
        PFX="platform/"
    fi
    git remote add aosp https://android.googlesource.com/$PFX$PROJECT
    echo "Remote 'aosp' created"
}
export -f aosp

# Examples:
# mergeupstream
# mergeupstream caf jb_2.5
# mergeupstream aosp android-4.2.2_r1.2
function mergeupstream() {
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
          return 0
        fi
    fi

    UPSTREAM="upstream"
    R_BRANCH="android-4.4"
    if [ ! -z "$1" ]
    then
        UPSTREAM=$1
        $UPSTREAM
    else
        upstream
    fi

    if [ ! -z "$2" ]
    then
        R_BRANCH=$2
    fi

    pwd
    #skip github
    #githubssh
    gerrit
    repo sync . 2> /dev/null
    git reset --hard 2> /dev/null
    git clean -fdx 2> /dev/null
    repo sync . 2> /dev/null
    git remote update 2> /dev/null
    repo sync . 2> /dev/null
    repo abandon android-4.4 . 2> /dev/null
    repo start android-4.4 . 2> /dev/null
    git merge $UPSTREAM/$R_BRANCH
    git push gerrit android-4.4
    # git push gerrit(gerrit) updates github, no need manually update
    # git push githubssh android-4.4
    echo "Upstream ($UPSTREAM/$R_BRANCH) changes have been merged."
}
export -f mergeupstream

function mergeupstreamall() {
  repo forall -c '
  if [ "$REPO_REMOTE" == "github" ]
  then
    mergeupstream
  fi
  '
}
export -f mergeupstreamall





# tag android-4.4-20130501
function tag() {
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
          return 0
        fi
    fi
    if [ -z "$1" ]
    then
      echo Tag must be specified.
      return 0
    fi
    R_TAG=$1
    gerrit
    git tag -d $R_TAG
    git tag -a $R_TAG -m "$R_TAG"
    git push -f gerrit $R_TAG
    echo "Tagged: $R_TAG"
}
export -f tag

# tagall android-4.4-RC2 android-4.4
function tagall() {
    if [ ! -d android ]
    then
      echo android directory not found.
      return 0
    fi
    if [ -z "$1" ]
    then
      echo Tag must be specified...
      return 0
    fi
    if [ -z "$2" ]
    then
      echo Branch must be specified...
      return 0
    fi
    export R_TAG=$1
    R_BRANCH=$2
    # Remove local manifests to build the core manifest
    rm -fr .repo/local_manifests
    repo sync -j4
    cd android
    gerrit
    git remote update
    repo abandon $R_BRANCH .
    repo start $R_BRANCH .
    cd ../
    # Create tags without android folder
    repo forall -c '
    if [[ "$REPO_REMOTE" == "github" && "$REPO_PATH" != "android" ]]
    then
      tag $R_TAG
    fi
    '
    # Create manifest
    mkdir -p android/manifests
    repo manifest -o android/manifests/$R_TAG.xml -r
    cd android
    git add manifests/$R_TAG.xml
    git commit -m "manifests/$R_TAG.xml"
    git push gerrit $R_BRANCH
    sleep 5
    git tag -a $R_TAG -m "$R_TAG"
    git push -f gerrit $R_TAG
    cd ../
    sleep 20
    repo sync -j4
    echo "MANIFEST: android/manifests/$R_TAG.xml"
}
export -f tagall

# Create tracking branches to compare upstream changes
# Examples:
# updateupstream
# updateupstream caf kitkat
# updateupstream aosp kitkat-release
function updateupstream() {
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
          return 0
        fi
    fi

    UPSTREAM="upstream"
    R_BRANCH="android-4.4"
    if [ ! -z "$1" ]
    then
        UPSTREAM=$1
        $UPSTREAM
    else
        upstream
    fi

    if [ ! -z "$2" ]
    then
        R_BRANCH=$2
    fi

    pwd
    gerrit
    repo sync . 2> /dev/null
    git reset --hard 2> /dev/null
    git clean -fdx 2> /dev/null
    repo sync . 2> /dev/null
    git fetch $UPSTREAM refs/heads/$R_BRANCH:refs/heads/$R_BRANCH
    repo abandon $UPSTREAM/$R_BRANCH . 2> /dev/null
    git branch $UPSTREAM/$R_BRANCH refs/heads/$R_BRANCH
    git push gerrit $UPSTREAM/$R_BRANCH:refs/heads/$UPSTREAM/$R_BRANCH
    repo abandon $UPSTREAM/$R_BRANCH . 2> /dev/null
    echo "Upstream ($UPSTREAM/$R_BRANCH) updated."
}
export -f updateupstream


function updateupstreamall() {
    if [ ! -d android ]
    then
      echo android directory not found.
      return 0
    fi
    if [ -z "$1" ]
    then
      echo Remote must be specified...
      return 0
    fi
    if [ -z "$2" ]
    then
      echo Branch must be specified...
      return 0
    fi
    export R_REMOTE=$1
    export R_BRANCH=$2

    repo forall -c '
    if [[ "$REPO_REMOTE" == "github" ]]
    then
      updateupstream $R_REMOTE $R_BRANCH
    fi
    '
}
export -f updateupstreamall


export ANDROID_BUILD_TOP=$(gettop)
