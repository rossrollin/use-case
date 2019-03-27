#!/bin/bash
####### Usage check 
[[ $# -ne 5 ]] && echo -e "Please provide the SQL scripts directory, username, hostname, database and password \nUSAGE: ./ecs_test_final.sh /directory username hostname dbname password" && exit

####### access / store db information
cd $1
user=$2
host=$3
database=$4
pass=$5

######## DB Version store
mysql -u $user -h $host -p$pass -D $database -e "SELECT version FROM versionTable" > dbvers.out
CURRENT_DB_VERSION=$(cat dbvers.out | grep -o '[0-9]\+')
highest_upgrade_version=$(ls $(pwd) | grep -Eo '[0-9]+' | sort -rn | head -n 1 | awk 'NR' |  sed 's/^0*//')

####### order scripts and prepare for exectuion
for sql_script in $(ls -1 | grep .sql | sort -n)
do
	next_script_to_execute=$(echo $sql_script | sed -e 's:^0*::' | sed -e 's/[^0-9]*//g')
	if [[ $next_script_to_execute -gt $CURRENT_DB_VERSION ]];
	then
		echo "Script $next_script_to_execute is newer than $CURRENT_DB_VERSION, executing $sql_script"
		 mysql -u $user -h $host -p$pass -D $database < $sql_script
		 CURRENT_DB_VERSION=$next_script_to_execute
	else
		echo "Version $next_script_to_execute is older or equal to the current version of the database $CURRENT_DB_VERSION - Nothing is being executed"
	fi
done

echo "Current version of the Database is: "$highest_upgrade_version
mysql -u $user -h $host -p$pass -D $database -e "UPDATE versionTable SET version = $highest_upgrade_version"

rm -rf dbvers.out
