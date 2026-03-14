#!/bin/bash

###
# script to visually simulate cluster data distribution and recovery from lost nodes including the triplicate replication
# mostly for fun, but also useful for illustration purposes
###

export crunching_base=/tmp/$(basename $0)_$$

showhelp() {
  echo supported parameters:
  echo --start-nodes=INT
  echo -e "\tnumber of nodes before any node losses"
  echo -e "\tvalid range: 1-30 nodes"
  echo --source=FILE
  echo -e "\tthe source text file."
  echo -e "\tthis should contain the test you want to use for the illustration"
  echo --surviving-nodes=INT
  echo -e "\tnumber of surviving nodes"
  echo -e "\tvalid range: 1-30 nodes, must be <= stating-nodes"
  echo -e "\twith triplicate replication, no losses are expected if only 1 or 2 nodes are lost"
  echo "--help|-h"
  echo -e "\tshow this help message"
  }

cleanup(){
  rm -rf ${crunching_base}
  }

for param in "$@"
  do
    case ${param} in
      --start-nodes=*)
        export start_nodes=${param#*=}
        if [ 0 -lt "${start_nodes}" -a "${start_nodes}" -le 30 ] 2>/dev/null
          then
            echo good >/dev/null
          else
            echo Starting Nodes must be an integer in range 1-30 >&2
            exit 22
          fi
        ;;
      --source=*)
        export source_file=${param#*=}
        ;;
      --surviving-nodes=*)
        export surviving_nodes=${param#*=}
        if [ 0 -lt "${surviving_nodes}" -a "${surviving_nodes}" -le 30 ] 2>/dev/null
          then
            echo good >/dev/null
          else
            echo Surviving Nodes must be an integer in range 1-30 and less than or equal to Starting Nodes >&2
            exit 22
          fi
        ;;
      --help|-h)
        showhelp
        exit 0
        ;;
      *)
        echo unknown parameter on command line >&2
        showhelp >&2
        exit 22
        ;;
    esac
  done

if [ "${surviving_nodes}" -gt "${start_nodes}" ]
  then
    echo Surviving Nodes must be an integer in range 1-30 and less than or equal to Starting Nodes >&2
    exit 22
  fi

mkdir -p ${crunching_base}/indexed_words ${crunching_base}/reconstructed

export ncount=0
while true
  do
    export ncount=$((ncount+1))
    mkdir ${crunching_base}/node${ncount}
    if [ ${ncount} -eq ${start_nodes} ]
      then
        break
      fi
  done


export c=0

for word in $(cat ${source_file} | sed s'/ /\n/g')
  do
    export c=$((c+1))
    echo "${word}" >${crunching_base}/indexed_words/${c}
  done

for iw in ${crunching_base}/indexed_words/*
  do
    for n in $(shuf -i 1-${start_nodes} -n 3)
      do
        cp -p ${iw} ${crunching_base}/node${n}/
      done
  done

###
# time to randomly select the survivor nodes
###
for sn in $(shuf -i 1-${start_nodes} -n ${surviving_nodes})
  do
    cp -pf ${crunching_base}/node${sn}/* ${crunching_base}/reconstructed/
  done

###
# show the comparative results
###

echo -e "\n\n\tThis is the original data, as formated by the node distribution, for comparison\n"

for file in $(ls ${crunching_base}/indexed_words/ | sort -h)
  do
    echo -e "$(cat ${crunching_base}/indexed_words/${file}) \c" | tee -a ${crunching_base}/rebuild_all.txt
  done

echo -e "\n\n\tThis is the reconstructed data with the loss of $((start_nodes - surviving_nodes)) nodes\n"
for file in $(ls ${crunching_base}/reconstructed/ | sort -h)
  do
    echo -e "$(cat ${crunching_base}/reconstructed/${file}) \c" | tee -a ${crunching_base}/rebuild_surviving.txt
  done
echo
echo
(
  cd ${crunching_base}/
  md5sum rebuild_*.txt
)
echo -e "\n\n"
###
# clean up
###
cleanup




