#!/bin/bash

PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

function hoursDiff {
if [ $# -eq 2 ]; then
	echo  $(expr \( $(date --reference="$1" +%s) - $(date --reference="$2" +%s) \) / 3600 )
elif [ $# -eq 1 ]; then
	echo $(expr \( $(date +%s) - $(date --reference="$1" +%s) \) / 3600 )
else
	echo "wrong number of arguments to hoursDiff function"
fi
}


if [ $# -eq 2 ]; then
	options=$1;
	conf_file=$2;
elif [ $# -eq 1 ]; then
	conf_file=$1;
else 
        echo "Wrong number of arguments"
        echo "Usage: [options] config-file min-seconds  interval"
fi

root_dir=$(awk '/^snapshot_root\t(.*)$/ {print $2}' $conf_file)
#echo "root_dir: $root_dir"

minHours=$(awk '/^#<scheduling>/ {print  $2}' $conf_file)
intervals=($(awk '/^retain/ {printf "%s ", $2}' $conf_file))
numRetain=($(awk '/^retain/ {printf "%s ", $3}' $conf_file))


#build minimum hours difference for interval array
minHoursInterval=($minHours)
i=1
while [ $i -le $(expr ${#numRetain} + 1) ]; do
	minHoursInterval[$i]=$(expr ${minHoursInterval[$(expr $i - 1)]} \* ${numRetain[$(expr $i - 1)]} )
	i=$(expr $i + 1)
done
echo "intervals: ${intervals[*]}"
echo "retain: ${numRetain[*]}"
#echo "check dir $root_dir.sync"
echo "retain hours: ${minHoursInterval[*]}"


#rotate higher intervals
i=$(expr ${#intervals[*]} - 1)
while [ $i -gt 0 ] ; do
	curr_interval=${intervals[$i]}
	prev_interval=${intervals[$(expr $i - 1)]}
	curr_minHours=${minHoursInterval[$i]}

	prev_maxDir="$root_dir$prev_interval.$(expr ${numRetain[$(expr $i - 1)]} - 1)"		
	curr_minDir="$root_dir$curr_interval.0"
	echo "check if max dir exists: $prev_maxDir"
	if [ -d $prev_maxDir ] ; then
		echo "check if min dir exists: $curr_minDir"
		if [  -d $curr_minDir ]; then
			#rotate only if old enough
			age=$(hoursDiff $prev_maxDir $curr_minDir)
			echo "age diff: $age"
			if [ $age -ge $curr_minHours ]; then
				#rotate
				echo "rotate ${intervals[$i]}"
				rsnapshot $options -c $conf_file ${intervals[$i]}
			fi
		else
			#rotate
			echo "rotate ${intervals[$i]}"
			rsnapshot $options -c $conf_file ${intervals[$i]}
		fi
	fi
	
	i=$(expr $i - 1)
done

#Hours since last backup
lastBkpAge=$minHours
if [ -d $root_dir${intervals[0]}.0 ]; then
	lastBkpAge=$(hoursDiff $root_dir${intervals[0]}.0)
fi
echo "last backup age: $lastBkpAge"
echo "min hours: $minHours"

if [ $lastBkpAge -ge $minHours ]; then
	#rotate smallest interval
	echo "Last backup is old: updating (and rotating ${intervals[0]})..."
	
	#ugly trick to mix conditional execution of the rotation and the reporting script	
	error=$(  { rsnapshot $options -c $conf_file sync > tmp_out; } 2>&1 )
	echo $error >> tmp_out
	#cat  tmp_out
	cat  tmp_out | rsnapreport.pl > $root_dir"RsnapReport.txt" ;
	rm tmp_out
	
	if [ ! "$error" ]; then
		rsnapshot $options -c $conf_file ${intervals[0]}
	else
		echo "rsnapshot exited whit errors: $errors"
	fi
fi

