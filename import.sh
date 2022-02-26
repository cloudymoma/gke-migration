path=$(pwd)
for n in $(ls -d */)
do
        _n=${n:0:(${#n}-1)}
        echo _$n
	echo "Creating namespace $_n"
	kubectl create namespace $_n

	for yaml in $(ls $path/$n)
	do
		echo -e "\t Importing $yaml"
		kubectl apply -f $path/$n$yaml -n $_n 
	done

done
