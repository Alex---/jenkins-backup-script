#!/bin/sh

readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)


JENKINS_HOME=/var/jenkins_home
DEST_FILE=$CUR_DIR/jenkins-backup-$(date "+%Y.%m.%d-%H.%M.%S").tar.gz

usage() {
  cat <<-END
	usage: $(basename $0) [-j JENKINS_HOME] [-b BACKUP_FILE]

	optional arguments:
	    -h, --help  show this help message and exit
	    -j DIR, --jenkins-home  DIR
	                Jenkins home directory.
	                Default is $JENKINS_HOME
	    -b FILE, --backup-file  FILE
	                output backup archive file.
	                Default is $DEST_FILE


	END

}

GETOPT_OUTPUT=$(getopt -o "hj:b:" --long "help,jenkins-home:,backup-file:" -- "$@")
if [ $? -gt 0 ] ; then
	usage
	exit 1
fi
eval set -- "$GETOPT_OUTPUT"
 
while true ; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -j|--jenkins-home)
      JENKINS_HOME=$2
      shift 2
      ;;
    -b|--backup-file)
      DEST_FILE$2
      shift 2
      ;;
    --) shift ; break ;;
    *)
      echo "Command line parsing internal error!"
      usage
      exit 1
      ;; 
  esac
done

readonly SCRATCH=$(mktemp -t tmp.XXXXXXXXXX)
on_exit() {
  rm -rf "$SCRATCH"
}
trap on_exit INT TERM HUP EXIT

if [ ! -d "$JENKINS_HOME" ]; then
  (>&2 echo "$JENKINS_HOME does not exist!")
  exit 1000
fi

set -e 

find "$JENKINS_HOME" -maxdepth 1 -type f -print >> $SCRATCH
find "$JENKINS_HOME" -name ".ssh" -maxdepth 1 -type d -print >> $SCRATCH
find "$JENKINS_HOME/plugins/" -name "*.[hj]pi" -maxdepth 1 -type f -print >> $SCRATCH
find "$JENKINS_HOME/plugins/" -name "*.[hj]pi.pinned" -maxdepth 1 -type f -print >> $SCRATCH
find "$JENKINS_HOME" -name "users" -maxdepth 1 -type d -print >> $SCRATCH
find "$JENKINS_HOME" -name "secrets" -maxdepth 1 -type d -print >> $SCRATCH
find "$JENKINS_HOME" -name "nodes" -maxdepth 1 -type d -print >> $SCRATCH

if [ "$(ls -A $JENKINS_HOME/jobs/)" ] ; then
  find "$JENKINS_HOME/jobs" -type f -not -path "*/builds/*" -print >> $SCRATCH
fi


tar -czvf $DEST_FILE -T $SCRATCH
