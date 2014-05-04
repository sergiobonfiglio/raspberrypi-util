OIFS=$IFS #save original
IFS=','

dropboxCmd="/usr/local/bin/dropbox_uploader.sh"
rootDir="Sergio-Share"
importedDir="downloaded"
transmissionDir="/mnt/hd1/share/torrents/"

list=$($dropboxCmd list $rootDir | \
	awk -v importedDir=$importedDir -v N=3 'NR>1{
			sep=" "; name="";
			if($1 == "[D]" && $3 != importedDir){ 
				for (i=N; i<=NF; i++) {
					name=name""$i""sep;
				};  
				#trim spaces
				gsub(/^[ \t]+/, "", name); gsub(/[ \t]+$/, "", name);
				printf("%s%s",name, ",");
			}
			}')

list=$list$IFS"."
#echo $list

for dir in $list; do

	#list torrents
	echo "scannig directory $dir..."
	torrents=$($dropboxCmd list $rootDir/$dir | \
		awk -v N=3 'NR>1{
			sep=""; 
			name="";
			for (i=N; i<=NF; i++)
				if ( match($i,/.*\.torrent/)){
					#trim spaces 
					gsub(/^[ \t]+/, "", name); gsub(/[ \t]+$/, "", name);
					name=name""$i",";
				}
			print name;
			}');
	#echo "torrent: $torrents";

	#create dir if doesn't exists
	$($dropboxCmd mkdir $rootDir/$dir/$importedDir)

	for torrent in $torrents; do
		torrent=$(echo $torrent | awk  '{gsub(/^[ \t]+/, "", $0); gsub(/[ \t]+$/, "", $0); printf("%s", $0);}')

		echo "Importing $torrent..."
		
		#download torrent in Transmission watch directory
		$($dropboxCmd download  $rootDir/$dir/$torrent $transmissionDir/$torrent) 	

		#move torrents
		$($dropboxCmd move $rootDir/$dir/$torrent $rootDir/$dir/$importedDir)
	done
done




IFS=$OIFS #restore original 
