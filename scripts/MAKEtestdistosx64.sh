#!/bin/bash
revision=$1
REMOTESVNROOT=$2
OSXHOST=$3
SVNROOT=~/$4
errlog=/tmp/smv_errlog.$$

SCP ()
{
  HOST=$1
  FROMDIR=$2
  FROMFILE=$3
  TODIR=$4
  TOFILE=$5

  scp $HOST\:$FROMDIR/$FROMFILE $TODIR/$TOFILE 2>/dev/null
  if [ -e $TODIR/$TOFILE ]; then
    echo "$TOFILE copied from $HOST"
  else
    echo "***error: the file $TOFILE failed to copy from: ">>$errlog
    echo "$HOST:$FROMDIR/$FROMFILE">>$errlog
    echo "">>$errlog
  fi
}

CP ()
{
  FROMDIR=$1
  FROMFILE=$2
  TODIR=$3
  TOFILE=$4
  if [ ! -e $FROMDIR/$FROMFILE ]; then
    echo "***error: the file $FROMFILE does not exist"
  else
    cp $FROMDIR/$FROMFILE $TODIR/$TOFILE
  fi
  if [ -e $TODIR/$TOFILE ]; then
    echo "$TOFILE copied"
  else
    echo "***error: the file $TOFILE failed to copy from $FROMDIR/$FROMFILE">>$errlog
    echo "">>$errlog
  fi
}

CPDIR ()
{
  FROMDIR=$1
  TODIR=$2
  if [ ! -e $FROMDIR ]; then
    echo "***error: the directory $FROMDIR does not exist"
  else
    cp -r $FROMDIR $TODIR
  fi
  if [ -e $TODIR ]; then
    echo "$TODIR copied"
  else
    echo "***error: the directory $TODIR failed to copy from $FROMDIR">>$errlog
    echo "">$errlog
  fi
}


BACKGROUNDDIR=$REMOTESVNROOT/smv/Build/background/intel_osx_64
SMVDIR=$REMOTESVNROOT/smv/Build/smokeview/intel_osx_64
SMZDIR=$REMOTESVNROOT/smv/Build/smokezip/intel_osx_64
DEM2FDSDIR=$REMOTESVNROOT/smv/Build/dem2fds/intel_osx_64
SMDDIR=$REMOTESVNROOT/smv/Build/smokediff/intel_osx_64
WIND2FDSDIR=$REMOTESVNROOT/smv/Build/wind2fds/intel_osx_64
HASHFILEDIR=$REMOTESVNROOT/smv/Build/hashfile/intel_osx_64
FORBUNDLE=$SVNROOT/smv/for_bundle
OSXDIR=$revision\_osx64
UPDATER=$SVNROOT/fds/Utilities/Scripts/make_updater.sh
uploads=$SVNROOT/smv/uploads
hashfile=$SVNROOT/smv/Build/hashfile/intel_osx_64/hashfile_osx_64

cd $SVNROOT/smv/uploads

rm -rf $OSXDIR
mkdir -p $OSXDIR
mkdir -p $OSXDIR/bin
mkdir -p $OSXDIR/bin/hash
mkdir -p $OSXDIR/Documentation

echo ""
echo "---- copying files ----"
echo ""
CP $FORBUNDLE objects.svo $OSXDIR/bin objects.svo
CP $FORBUNDLE smokeview.ini $OSXDIR/bin smokeview.ini
CPDIR $FORBUNDLE/textures $OSXDIR/bin/textures
cp $FORBUNDLE/*.po $OSXDIR/bin/.
CP $FORBUNDLE volrender.ssf $OSXDIR/bin volrender.ssf
SCP $OSXHOST $BACKGROUNDDIR background $OSXDIR/bin background
SCP $OSXHOST $SMVDIR smokeview_osx_test_64 $OSXDIR/bin smokeview
SCP $OSXHOST $DEM2FDSDIR dem2fds_osx_64 $OSXDIR/bin dem2fds
SCP $OSXHOST $SMDDIR smokediff_osx_64 $OSXDIR/bin smokediff
SCP $OSXHOST $WIND2FDSDIR wind2fds_osx_64 $OSXDIR/bin wind2fds
SCP $OSXHOST $HASHFILEDIR hashfile_osx_64 $OSXDIR/bin hashfile

CURDIR=`pwd`
cd $OSXDIR/bin
$hashfile background > background.sha1
$hashfile smokediff  > smokediff.sha1
$hashfile smokeview  > smokeview.sha1
$hashfile smokezip   > smokezip.sha1
$hashfile dem2fds    > dem2fds.sha1
$hashfile wind2fds   > wind2fds.sha1
$hashfile hashfile   > hashfile.sha1
cat *.sha1 > $uploads/$OSXDIR.sha1
cd $CURDIR

rm -f $OSXDIR.tar $OSXDIR.tar.gz
cd $OSXDIR
echo ""
echo "---- building installer ----"
echo ""
tar cvf ../$OSXDIR.tar .
cd ..
gzip $OSXDIR.tar
$UPDATER OSX $revision $OSXDIR.tar.gz $OSXDIR.sh FDS/FDS6
$hashfile $OSXDIR.sh > $OSXDIR.sh.sha1
cat $OSXDIR.sh.sha1 >> $uploads/$OSXDIR.sha1
rm $OSXDIR.sh.sha1

if [ -e $errlog ]; then
  numerrs=`cat $errlog | wc -l `
  if [ $numerrs -gt 0 ]; then
    echo ""
    echo "----------------------------------------------------------------"
    echo "---------------- bundle generation errors ----------------------"
    cat $errlog
    echo "----------------------------------------------------------------"
    echo "----------------------------------------------------------------"
    echo ""
  fi
  rm $errlog
fi

