#!/bin/bash

##version 31.08.2014 21.27

##monitoring using proc&bash for linux&zabbix ssh
##stepanovv.ru@yandex.ru

#p- perceintage
#i - int
#d - double
#t - text
##todo
#add fullpath to all awk pgrep ps wc df

#HZ to sec convert
#awk 'NR==1{sec_idle=$2};NR==2{hz_idle=$5; print hz_idle/sec_idle }' /proc/uptime /proc/stat

total_uptime=`awk '{print $1}' /proc/uptime`
idle_uptime=`awk '{print $2}' /proc/uptime`
mailfrom="zabbix@stepanovv.ru"
mailto="bskmail@bk.ru"


case $1 in
	"p_mem_free")
			  awk '/MemTotal/ { mem_all = $2 };
			      /MemFree/ { mem_free = $2 };
			      END { printf "%.0f\n", mem_free / mem_all * 100 }' /proc/meminfo
			  ;;
	"i_zombie_count") ps aux | awk '{print $8}' | grep -cE '^Z$' ;;
	"i_proc_count")   pgrep -f $2 | wc -l ;;
	#
	"p_cpu_free")     ;;
	"p_cpu_iowait")   ;;
	"p_cpu_steal")    awk 'NR==1{total_uptime=$1*100};NR==2{steal_time=$9 ;printf "%.0f\n", steal_time / total_uptime * 100}' /proc/uptime /proc/stat;; #HZ_time convertion!!!
			  ##NR - current number of procesed line. 
	"p_cpu_idle")     vmstat | awk 'NR==3{print $15}';; #awk '{printf "%.0f\n", $2 / $1 * 100}' /proc/uptime 
	#
	"i_io_read_delay") vmstat -d | awk -v disk=$2 '{if ($1==disk) printf "%.0f\n", $5 / $2}' ;;
	"i_io_write_delay") vmstat -d | awk -v disk=$2 '{if ($1==disk) printf "%.0f\n", $9 / $6}' ;;
	"i_io_time") awk -v disk=$2 '{if ($3==disk) printf "%.0f\n", ($1 + $5) / $10 * 10000}' /proc/diskstats ;; 
	#microsecs per IO should be <=100000 (10millisecs)
	"p_swap_free") 	  awk '/SwapTotal/ { mem_all = $2 };
			  /SwapFree/ { mem_free = $2 };
			  END { printf "%.0f\n", (mem_free / mem_all) * 100 }' /proc/meminfo
			  ;;
	"p_/_free") df | awk '{if ($6=="/") printf "%.0f\n", ($4 / $2) * 100}';; #why differ from df %?
	#
	"i_kbits_avg_day") vnstat --oneline | awk -F\; '{print $7}' | awk -F. '{print $1}' ;;
	"i_mbit_out") ;;
	"i_packet_out") ;;
	"i_packet_in") ;;
	"i_proc_forked");;#/proc/stat
	"p_swap_pages");;#/proc/stat
	"test") 
	    bash $0 p_mem_free
	    bash $0 i_zombie_count
	    bash $0 i_proc_count bash
	    bash $0 p_cpu_steal
	    bash $0 p_cpu_idle
	    bash $0 i_io_read_delay vda
	    bash $0 i_io_write_delay vda
	    bash $0 i_io_time vda
	    bash $0 p_swap_free
	    bash $0 p_/_free
	    bash $0 i_kbits_avg_day ;;
	"reboot") echo "server `hostname` reboot" | mail -s zabbix_alert -r $mailfrom $mailto ;;
	*) echo "65534" ;;
esac