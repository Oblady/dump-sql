#!/bin/bash
###############################################################################################################
# Script de dump/archivage de l'ensemble des base de donnée d'un serveur
# Copyleft : Sylvain Doison (sylvain@oblady.fr)
# Copyleft : Sébastien Thibault aka Beleneglorion (belen@hinatachii.com)
# Version : 2.0-alpha 
###############################################################################################################

################################################################################################################
# Configuration des variables du scripts
################################################################################################################

# Dossier destiné a recevoir les dump 
# des bases de données (pas de slash de fin).
DUMP_PATH=/tmp/test

#
#Chemin du fichier de conf de mysql de debian
DEBIANCNF=/etc/mysql/debian.cnf

# Informations base de donnée locale
DB_HOST=$(cat ${DEBIANCNF}|grep -m 1 host | cut -d"=" -f2|sed -e 's/^ *//g' -e 's/ *$//g');
DB_USER=$(cat ${DEBIANCNF}|grep -m 1 user | cut -d"=" -f2|sed -e 's/^ *//g' -e 's/ *$//g');
DB_PWD=$(cat ${DEBIANCNF}|grep -m 1 password | cut -d"=" -f2|sed -e 's/^ *//g' -e 's/ *$//g');

# Liste des bases de données à exclure du dump
# Ajouter autant de ligne que nécessaire.
excludeDBs[0]='test'
excludeDBs[0]='mysql'

# Liste des tables a exclure du dump.
# Ajouter autant de ligne que nécessaire.
#excludeTables[0]='temp_table'
excludeTables[0]='general_log'
excludeTables[1]='slow_log'

# Liste des tables sans donnée du dump.
# Ajouter autant de ligne que nécessaire.

#default typo3 tables to ignore
nodataTables[0]='cache_hash'
nodataTables[1]='cache_imagesizes'
nodataTables[2]='cache_md5params'
nodataTables[3]='cache_pages'
nodataTables[4]='cache_pagesection'
nodataTables[5]='cache_sys_dmail_stat'
nodataTables[6]='cache_typo3temp_log'
nodataTables[7]='cache_treelist'
nodataTables[8]='cachingframework_cache_hash'
nodataTables[9]='cachingframework_cache_hash_tags'
nodataTables[10]='cachingframework_cache_pages'
nodataTables[11]='cachingframework_cache_pages_tags'
nodataTables[12]='cachingframework_cache_pagesection'
nodataTables[13]='cachingframework_cache_pagesection_tags'
nodataTables[14]='index_config'
nodataTables[15]='index_debug'
nodataTables[16]='index_fulltext'
nodataTables[17]='index_grlist'
nodataTables[18]='index_phash'
nodataTables[19]='index_rel'
nodataTables[20]='index_section'
nodataTables[21]='index_stat_search'
nodataTables[22]='index_stat_word'
nodataTables[23]='index_words'
nodataTables[24]='tx_realurl_chastcache'
nodataTables[25]='tx_realurl_errorlog'
nodataTables[26]='tx_realurl_pathcache'
nodataTables[27]='tx_realurl_uniqalias'
nodataTables[28]='tx_realurl_urldecodecache'
nodataTables[29]='tx_realurl_urlencodecache'
nodataTables[30]='sys_log'
nodataTables[31]='sys_history'

#fonction utilitaire pour verifier si un élément existe dans un tableau
notContainsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 1; done
  return 0
}

#On définit un nom temporaire utilisé par le script (ici la date jusqu'à la minute)
dirname="dump_`date +%d`.`date +%m`.`date +%y`@`date +%H`h`date +%M`"

#On crée sur le disque un répertoire temporaire (changer le chemin précédant /$dirname)
mkdir "$DUMP_PATH/$dirname"

#On place dans un tableau le nom de toutes les bases de données du serveur
#On peut choisir ici d'exclure certaines bases de données de la sauvegarde grâce à la clause LIKE
#Ex : -e "show databases LIKE 'blog_%'"
databases=( $(mysql -h "$DB_HOST" -u "$DB_USER" --password="$DB_PWD" -e "show databases" | grep -v Database) )


#Pour chacune des bases de données trouvées ...
for database in ${databases[@]}
        do

	if notContainsElement "$database"  "${excludeDBs[@]}"
        then
        #... on crée dans le dossier temporaire un dossier portant le nom de la base
                mkdir "${DUMP_PATH}/${dirname}/${database}"
        #... on récupère chacune des tables de cette base de données dans un tableau ...
                tables=( $(mysql $database -h $DB_HOST -u $DB_USER --password=$DB_PWD -e 'show tables' | grep -v Tables_in) )
                #... et on parcourt chacune de ces tables ...
                for table in ${tables[@]}
                do
				

					if notContainsElement "$table"  "${excludeTables[@]}"
					then
                        if notContainsElement "$table"  "${nodataTables[@]}"
                        then
                          	#... que l'on dump avec mysqldump dans un fichier portant le nom de la table dans le dossier de la bdd parcourue
						    $(mysqldump -h $DB_HOST -u $DB_USER --password=$DB_PWD --quick --add-locks --lock-tables --extended-insert $database $table > ${DUMP_PATH}/${dirname}/${database}/${table}.sql)
				
                        else
                        	#... que l'on dump avec mysqldump dans un fichier portant le nom de la table dans le dossier de la bdd parcourue mais sans les données
						    $(mysqldump -h $DB_HOST -u $DB_USER --password=$DB_PWD --quick --add-locks --lock-tables --no-data $database $table > ${DUMP_PATH}/${dirname}/${database}/${table}.sql)
				
                        fi
                        
                     fi
				
                done

                #On gzip la base
                tar -czf ${DUMP_PATH}/${database}.tar.gz -C ${DUMP_PATH}/${dirname} ${DUMP_PATH}/${dirname}/${database}
		rm -rf "${DUMP_PATH}/${dirname}/${database}"
	fi

done


#On supprime le répertoire temporaire
rm -rf ${DUMP_PATH}/${dirname}/

