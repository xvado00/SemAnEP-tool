#!/bin/bash
#
# Print statistics of various environment programs classes for a given 
# BF programs sample file.
# 
# TODO: Some regexes may overlap ("Action surely does not influence reward" is worked-around),
# to solve this, program samples should be uniqly numbered (cat -n), greped intermediate
# results saved and all of them for a given question should be cat | sort | uniqed
# this will also facilitate extracting the classes from the samples in a single script

# Test for sample file
if [ -f ./"${1}" ]; then
	samples="${1}"
	_samples_name="`echo ${samples} | cut -d "(" -f 2 | cut -d ")" -f 1`,1"
	symbols="`echo ${_samples_name} | cut -d "," -f 1`"
	observations="`echo ${_samples_name} | cut -d "," -f 2`"
	#TODO Take into account regex differences in case of more than 1 observation
	# esp. nr. of writes to cause halting
else
	echo "Specified sample file does not exist."	
fi

# Define functions
# Expects instruction character (else than [])
function count_instruction_only_in_loop()
{
	local _i
	local _result
	_i="\\${1}"
	_result="$(grep -P -e "${_i}" ${samples} | grep -P -e "^[0-9]* [^\[${_i}]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[${_i}]*)+#$" | wc -l)"
	echo ${_result}
}

# Expects instruction character conditioned in loop, other conditioning the loop (else than []) 
# and optionally a parametre "observation"
function count_instruction_only_in_loop_conditioned_by()
{
	local _i
	local _c
	local _ro
	local _result
	_i="\\${1}"
	_c="\\${2}"
	_ro="\\${3}"
	_result="$(expr \
		`grep -P -e "${_i}" ${samples} | grep -P -e "^[0-9]* ([^${_i}\[\]]*${_c}[\+\-]*\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*${_i}[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\])+[^${_i}]*#$" | wc -l` + \
		`grep -P -e "${_i}" ${samples} | grep -P -e "^[0-9]* [\+\-]*\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*${_i}[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\]([^${_i}]*${_c}[\+\-]*\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*${_i}[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\])*[^${_i}]*${_c}[\+\-]*#$" | wc -l`)"
	if [ "$_ro" == "observation" ]; then
		_result="$(expr ${_result} + \
			`grep -P -e "${_i}" ${samples} | grep -P -e "^[0-9]* [^${_i}\[\]]*${_i}([^${_i}\[\]]*${_c}[\+\-]*\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*${_i}[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\])+[^${_i}]*#$" | wc -l`)"
	fi
	echo ${_result}
}

# Expects instruction character (else than [].)
function count_instruction_only_in_not_executed_loop()
{
	local _i
	local _result
	_i="\\${1}"
	_result="$(expr \
		`grep -P -e "^[0-9]* [^${_i}]*\[[^\[\]${_i}]+\]\[[^\[\]]*${_i}[^\[\]]*\][^${_i}]*$" ${samples} | wc -l` + \
		`grep -P -e "^[0-9]* [^${_i}]*\[[^\[\]${_i}]*\[[^\[\]${_i}]+\][^\[\]${_i}]*\]\[[^\[\]]*${_i}[^\[\]]*\][^${_i}]*$" ${samples} | wc -l` + \
		`grep -P -e "^[0-9]* [^${_i}]*\[[^\[\]${_i}]*\[[^\[\]${_i}]*\[[^\[\]${_i}]+\][^\[\]${_i}]*\][^\[\]${_i}]*\]\[[^\[\]]*${_i}[^\[\]]*\][^${_i}]*$" ${samples} | wc -l` + \
		`grep -P -e "^[0-9]* [^${_i}]*\[[^\[\]${_i}]*\[[^\[\]${_i}]*\[[^\[\]${_i}]*\[[^\[\]${_i}]+\][^\[\]${_i}]*\][^\[\]${_i}]*\][^\[\]${_i}]*\]\[[^\[\]]*${_i}[^\[\]]*\][^${_i}]*$" ${samples} | wc -l`)"
	echo ${_result}
}

# Expects instruction character (else than [].) and uses nr. of observations
function count_instruction_only_after_write_limit()
{
	local _i
	local _l
	local _result
	_i="\\${1}"
	_l=`expr ${observations} + 2`
	_result=`grep -P -e "^[0-9]* ([^${_i}\.\[]*\.){${_l}}.*${_i}.*$" ${samples} | wc -l`
	echo ${_result}
}

# Expects nothing and uses nr. of observations
function count_write_limit_surely_exceeded()
{
	local _l
	local _result
	_l=`expr ${observations} + 2`
	_result=`grep -P -e "^[0-9]* ([^\.\[]*(\[[^\[]*(\[[^\[]*(\[[^\[]*\][^\[]*)*\][^\[]*)*\][^\[]*)*\.){${_l}}.*$" ${samples} | wc -l`
	echo ${_result}
}

# Expects nothing and uses nr. of observations
function count_write_limit_possibly_exceeded()
{
	local _l
	local _result
	_l=`expr ${observations} + 2`
	_result=`grep -P -e "^[0-9]* .*\[[^<>]*\.[^<>]*\].*$" ${samples} | \
		grep -P -v -e "^[0-9]* ([^\.\[]*(\[[^\[]*(\[[^\[]*(\[[^\[]*\][^\[]*)*\][^\[]*)*\][^\[]*)*\.){${_l}}.*$" | wc -l`
	echo ${_result}
}

# Expects instruction character conditioning the loop and uses nr. of observations
function count_write_limit_possibly_exceeded_conditioned_by()
{
	_c="\\${1}"
	local _l
	local _result
	_l=`expr ${observations} + 2`
	_result=`grep -P -e "^[0-9]* .*${_c}[\+\-]*\[[^<>]*\.[^<>]*\].*$" ${samples} | \
		grep -P -v -e "^[0-9]* ([^\.\[]*(\[[^\[]*(\[[^\[]*(\[[^\[]*\][^\[]*)*\][^\[]*)*\][^\[]*)*\.){${_l}}.*$" | wc -l`
	echo ${_result}
}

# Expects instruction character (else than [].) and uses nr. of observations
function count_instruction_only_after_write_cycle()
{
	local _i
	local _l
	local _result
	_i="\\${1}"
	_l=`expr ${observations} + 2`
	_result=$(expr \
		`grep -P -e "^[0-9]* ([^${_i}\.\[]*\.){0,${_l}}([^\[\.${_i}]*\[[\[\+\-\.]*\.[\+\-\.\]]*\]\])+.*${_i}.*$" ${samples} | grep -P -v -e "^[0-9]* ([^${_i}\.\[]*\.){0,${_l}}([^\[\.${_i}]*\[[\+\-\.]*(\[[\+\-\.]*\][\+\-\.]*)*\.(\[[\+\-\.]*\][\+\-\.]*)*[\+\-\.]*\])+.*${_i}.*$" | wc -l` + \
		`grep -P -e "^[0-9]* ([^${_i}\.\[]*\.){0,${_l}}([^\[\.${_i}]*\[[\+\-\.]*(\[[\+\-\.]*\][\+\-\.]*)*\.(\[[\+\-\.]*\][\+\-\.]*)*[\+\-\.]*\])+.*${_i}.*$" ${samples} | wc -l`)
	echo ${_result}
}

# Expects instruction character to be overwritten and instruction charter which overwrites (, or %)
function count_instruction_only_overwritten_by()
{
	local _i
	local _o
	local _result
	_i="\\${1}"
	_o="\\${2}"
	_result=$(expr \
		`grep -P -e "^[0-9]* ([^${_i}]*${_i}[\+\-]*${_o})+[^${_i}]*$" ${samples} | wc -l` + \
		`grep -P -e "^[0-9]* [\+\-]*${_o}([^${_i}]*${_i}[\+\-]*${_o})*[^${_i}]*${_i}[\+\-]*#$" ${samples} | wc -l`)
	echo ${_result}
}

# Expects instruction character (,%+-)
function count_instruction_only_as_zeroing()
{
	local _i
	local _result
	_i="\\${1}"
	_result=`grep -P -e "^[0-9]* ([^${_i}]*\[[\+\-,%]*${_i}[\+\-,%]*\])+[^${_i}]*#$" ${samples} | wc -l`
	echo ${_result}
}

# Expects instruction character (,%+-)
function count_instruction_only_zeroed()
{
	local _i
	local _result
	_i="\\${1}"
	_result=$(expr \
		`grep -P -e "^[0-9]* ([^${_i}]*${_i}[\+\-]*\[[\+\-,%]+\])+[^${_i}]*#$" ${samples} | wc -l` + \
		`grep -P -e "^[0-9]* [\+\-]*\[[\+\-,%]+\]([^${_i}]*${_i}[\+\-]*\[[\+\-,%]+\])*[^${_i}]*${_i}[\+\-]*#$" ${samples} | wc -l`)
	echo ${_result}
}

# Print header
echo "Characteristics,BF(${symbols}-${observations})"

# Analyze role of chance
echo "Chance,"
echo "instruction is present:,`grep -P -e "%" ${samples} | wc -l`"
echo "surely influences reward:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*%[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\..*%[\+\-]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^<>\.]*<[\+\-]*\..*%[\+\-]*>[^<>]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^<>\.]*>[\+\-]*\..*%[\+\-]*<[^<>]*#$" ${samples} | wc -l`)"
echo "possibly influences reward:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*%[\+\-]*\[[\+\-\[]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\[[\+\-\[]*\..*%[\+\-]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\[\.]*\[[^\.\]]*%[\+\-]*\..*$" ${samples} | wc -l`)"
echo "possibly doesn't influence reward:,$(count_instruction_only_after_write_cycle '%')"
echo "surely doesn't influence reward:,$(expr \
	`grep -P -v -e "%" ${samples} | wc -l` + \
	`grep -P -e "%" ${samples} | grep -P -e "^[0-9]* [^\[\.]*,[\+\-]*\..*$" | wc -l` + \
	`grep -P -e "%" ${samples} | grep -P -e "^[0-9]* [\+\-]*\..*,[\+\-]*#$" | wc -l` + \
	$(count_instruction_only_zeroed '%') + \
	$(count_instruction_only_as_zeroing '%') + \
	$(count_instruction_only_overwritten_by '%' ',') + \
	$(count_instruction_only_after_write_limit '%') + \
	$(count_instruction_only_in_not_executed_loop '%'))"
echo "surely influences observation:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*\.[^\[\.]*%[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\[\.]*%[\+\-]*\.[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\.[\+\-]*\..*%[\+\-]*#$" ${samples} | wc -l`)"
echo "possibly influences observation:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*\.[^\[\.]*%[\+\-]*\[[\+\-\[]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\[\.]*\.[^\[\.]*\[[^\.\]]*%[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\.]*%[\+\-]*\[[\+\-]*\.[\+\-]*\].*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\[[\+\-\[]*\.[\+\-]*\].*%[\+\-]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\[\.]*\[[^\.\]<>]*%[\+\-]*\.[^\.<>]*\][^\[\]]*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\[[\+\-\[]*\.[\+\-\[]*\..*%[\+\-]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\.]*%[\+\-]*\[[\+\-\[]*\.[\+\-\[]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\.]*\[[^\.\]]*%[\+\-\[]*\.[\+\-\[]\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\.]*\[[^\.\]]*\.[^\.\]]*%[\+\-\[]\..*$" ${samples} | wc -l`)"
echo "possibly doesn't influence observation:,$(count_instruction_only_after_write_cycle '%')"
echo "surely doesn't influence observation:,$(expr \
	`grep -P -v -e "%" ${samples} | wc -l` + \
	`grep -P -e "%" ${samples} | grep -P -e "^[0-9]* [^\[\.]*\.[^\[\.]*,[\+\-]*\..*$" | wc -l` + \
	`grep -P -e "%" ${samples} | grep -P -e "^[0-9]* [^\[\.]*,[\+\-]*\.[\+\-]*\..*$" | wc -l` + \
	`grep -P -e "%" ${samples} | grep -P -e "^[0-9]* [\+\-]*\.[\+\-]*\..*,[\+\-]*#$" | wc -l` + \
	$(count_instruction_only_zeroed '%') + \
	$(count_instruction_only_as_zeroing '%') + \
	$(count_instruction_only_overwritten_by '%' ',') + \
	$(count_instruction_only_after_write_limit '%') + \
	$(count_instruction_only_in_not_executed_loop '%'))"
echo "surely influences computation:,$(grep -P -e "^[0-9]* [^\[]*%.*$" ${samples} \
	| grep -P -v -e "^[0-9]* [^\.%\[]*\.[^\.%\[]*\.[^\.%\[]*\..*$" | wc -l)"
echo "possibly influences computation:,$(count_instruction_only_in_loop '%')"
#echo "possibly influences computation:,$(grep -P -e "^[0-9]* [^%]*\[[^\]%]*%.*\][^%]*$" ${samples} \
#	| grep -P -v -e "^[0-9]* [^\.%\[]*\.[^\.%\[]*\.[^\.%\[]*\..*$" | wc -l)"
echo "of that based on action:,$(grep -P -e "^[0-9]* [^%]*,[\+\-]*\[[^\]%]*%.*\][^%]*$" ${samples} \
	| grep -P -v -e "^[0-9]* [^\.%\[]*\.[^\.%\[]*\.[^\.%\[]*\..*$" | wc -l)"
echo "possibly doesn't influence computation:,$(count_instruction_only_after_write_cycle '%')"
echo "surely doesn't influence computation:,$(expr \
	`grep -P -v -e "%" ${samples} | wc -l` + \
	$(count_instruction_only_zeroed '%') + \
	$(count_instruction_only_as_zeroing '%') + \
	$(count_instruction_only_overwritten_by '%' ',') + \
	$(count_instruction_only_after_write_limit '%') + \
	$(count_instruction_only_in_not_executed_loop '%'))"

# Analyze role of action
echo "Action,"
echo "instruction is present:,`grep -P -e "," ${samples} | wc -l`"
echo "surely influences computation:,$(expr \
	`grep -P -e "^[0-9]* [^\[,]*,.*$" ${samples} | grep -P -v -e "^[0-9]* [^,]*\.[^,]*\.[^,]*\..*$" | wc -l` + \
	`grep -P -e "^[0-9]* [^\[,]*\[[^\[]*\][^\[,]*,.*$" ${samples} | grep -P -v -e "^[0-9]* [^,]*\.[^,]*\.[^,]*\..*$"| grep -P -v -e "^[0-9]* [^,]*\[[^,]*\.[^,]*\].*" | wc -l` + \
	`grep -P -e "^[0-9]* [^\[,]*\[[^\[]*\][^\[,]*\[[^\[]*\][^\[,]*,.*$" ${samples} | grep -P -v -e "^[0-9]* [^,]*\.[^,]*\.[^,]*\..*$"| grep -P -v -e "^[0-9]* [^,]*\[[^,]*\.[^,]*\].*" | wc -l` + \
	`grep -P -e "^[0-9]* [^\[,]*\[[^\[]*\[[^\[]*\][^\[]*\][^\[,]*,.*$" ${samples} | grep -P -v -e "^[0-9]* [^,]*\.[^,]*\.[^,]*\..*$"| grep -P -v -e "^[0-9]* [^,]*\[[^,]*\.[^,]*\].*" | wc -l`)"
echo "possibly influences computation:,$(count_instruction_only_in_loop ',')"
echo "of that based on chance:,$(grep -P -e "^[0-9]* [^,]*%[\+\-]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*,[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^,]*)+[^,]*$" ${samples} | wc -l)"
echo "possibly doesn't influence computation:,$(count_instruction_only_after_write_cycle ',')"
echo "surely doesn't influence computation:,$(expr \
	$(count_instruction_only_zeroed ',') + \
	$(count_instruction_only_as_zeroing ',') + \
	$(count_instruction_only_overwritten_by ',' '%') + \
	$(count_instruction_only_after_write_limit ',') + \
	$(count_instruction_only_in_not_executed_loop ','))"
echo "surely influences reward:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*,[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\..*,[\+\-]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^<>\.]*<[\+\-]*\..*,[\+\-]*>[^<>]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^<>\.]*>[\+\-]*\..*,[\+\-]*<[^<>]*#$" ${samples} | wc -l`)"
echo "possibly influences reward:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*,[\+\-]*\[[\+\-\[]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\[[\+\-\[]*\..*,[\+\-]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\[\.]*\[[^\.\]]*,[\+\-]*\..*$" ${samples} | wc -l`)"
echo "possibly doesn't influence reward:,$(count_instruction_only_after_write_cycle ',')"
echo "surely doesn't influence reward:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*%[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\..*%[\+\-]*#$" ${samples} | wc -l`)"
	#$(count_instruction_only_zeroed ',') + \
	#$(count_instruction_only_as_zeroing ',') + \
	#$(count_instruction_only_overwritten_by ',' '%') + \
	#$(count_instruction_only_after_write_limit ',') + \
	#$(count_instruction_only_in_not_executed_loop ','))"
echo "surely influences observation:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*\.[^\[\.]*,[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\[\.]*,[\+\-]*\.[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\.[\+\-]*\..*,[\+\-]*#$" ${samples} | wc -l`)"
echo "possibly influences observation:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*\.[^\[\.]*,[\+\-]*\[[\+\-\[]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\[\.]*\.[^\[\.]*\[[^\.\]]*,[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\.]*,[\+\-]*\[[\+\-]*\.[\+\-]*\].*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\[[\+\-\[]*\.[\+\-]*\].*,[\+\-]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\[\.]*\[[^\.\[\]<>]*,[\+\-]*\.[^\.\[\]<>]*\].*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\[[\+\-\[]*\.[\+\-\[]*\..*,[\+\-]*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\.]*,[\+\-]*\[[\+\-\[]*\.[\+\-\[]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\.]*\[[^\.\]]*,[\+\-\[]*\.[\+\-\[]\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\.]*\[[^\.\]]*\.[^\.\]]*,[\+\-\[]\..*$" ${samples} | wc -l`)"
echo "possibly doesn't influence observation:,$(count_instruction_only_after_write_cycle ',')"
echo "surely doesn't influence observation:,$(expr \
	`grep -P -e "^[0-9]* [^\[\.]*\.[^\[\.]*%[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [^\[\.]*%[\+\-]*\.[\+\-]*\..*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]*\.[\+\-]*\..*%[\+\-]*#$" ${samples} | wc -l` + \
	$(count_instruction_only_zeroed ',') + \
	$(count_instruction_only_as_zeroing ',') + \
	$(count_instruction_only_overwritten_by ',' '%') + \
	$(count_instruction_only_after_write_limit ',') + \
	$(count_instruction_only_in_not_executed_loop ','))"

# Analyze observations and rewards
echo "Reward/Observations,"
echo "instruction is present:,`grep -P -e "\." ${samples} | wc -l`"
echo "Reward,"
echo "surely is produced in computation:,$(grep -P -e "^[0-9]* [^\[\.]*((\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\.]*)*\.[^\[\.]*){1}.*$" ${samples} | wc -l)"
echo "possibly is produced in computation:,$(count_instruction_only_in_loop '.')"
echo "of that based on action:,$(count_instruction_only_in_loop_conditioned_by '.' ',')"
echo "of that based on chance:,$(count_instruction_only_in_loop_conditioned_by '.' '%')"
echo "surely isn't produced in computation:,$(count_instruction_only_in_not_executed_loop '.')"
echo "Observation,"
echo "surely is produced in computation:,$(grep -P -e "^[0-9]* [^\[\.]*((\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*(\[[^\[\]]*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\]]*)*\][^\[\.]*)*\.[^\[\.]*){2}.*$" ${samples} | wc -l)"
echo "possibly is produced in computation:,$(grep -P -e "^[0-9]* .*\[[^<>]*\.[^<>]*\].*$" ${samples} \
	| grep -P -v -e "^[0-9]* [^\.\[]*(\[[^\[]*\][^\.\[]*)*?\.[^\.\[]*(\[[^\[]*\][^\.\[]*)*?\..*$" | wc -l)"
echo "of that based on action:,$(count_instruction_only_in_loop_conditioned_by '.' ',' 'observation')"
echo "of that based on chance:,$(count_instruction_only_in_loop_conditioned_by '.' '%' 'observation')"
echo "surely isn't produced in computation:,$(expr \
	$(count_instruction_only_in_not_executed_loop '.') + \
	`grep -P -e "^[0-9]* [^\[\.]*\.[^\.]*$" ${samples} | wc -l`)"

# Analyze simple programs
echo "Syntactically degraded environments,"
echo "only read and write instructions:,$(grep -P -e "^[0-9]* [\.,]*#$" ${samples} | wc -l)"
echo "read and write and 1 pair/instruction:,$(expr \
	`grep -P -e "^[0-9]* [\.,\+\-]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,<>]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,%]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,\[\]]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,]*#$" | wc -l`)"
echo "read and write and 2 pairs/instructions:,$(expr \
	`grep -P -e "^[0-9]* [\.,\+\-<>]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,\+\-]*#$"  | grep -P -v -e "^[0-9]* [\.,<>]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,\+\-%]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,\+\-]*#$"  | grep -P -v -e "^[0-9]* [\.,%]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,\+\-\[\]]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,\+\-]*#$"  | grep -P -v -e "^[0-9]* [\.,\[\]]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,<>%]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,%]*#$"  | grep -P -v -e "^[0-9]* [\.,<>]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,\[\]<>]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,\[\]]*#$"  | grep -P -v -e "^[0-9]* [\.,<>]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,\[\]%]*#$" ${samples} | grep -v -P -e "^[0-9]* [\.,\[\]]*#$"  | grep -P -v -e "^[0-9]* [\.,%]*#$" | wc -l`)"
echo "read and write and 3 pairs/instructions:,$(expr \
	`grep -P -e "^[0-9]* [\.,\+\-<>%]*#$" ${samples} | grep -P -v -e "^[0-9]* [\.,\+\-<>]*#$" \
	| grep -P -v -e "^[0-9]* [\.,\+\-%]*#$" | grep -P -v -e "^[0-9]* [\.,<>%]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,\+\-<>\[\]]*#$" ${samples} | grep -P -v -e "^[0-9]* [\.,\+\-<>]*#$" \
	| grep -P -v -e "^[0-9]* [\.,\+\-\[\]]*#$" | grep -P -v -e "^[0-9]* [\.,<>\[\]]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,\[\]<>%]*#$" ${samples} | grep -P -v -e "^[0-9]* [\.,\[\]<>]*#$" \
	| grep -P -v -e "^[0-9]* [\.,\[\]%]*#$" | grep -P -v -e "^[0-9]* [\.,<>%]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [\.,\[\]\+\-%]*#$" ${samples} | grep -P -v -e "^[0-9]* [\.,\[\]\+\-]*#$" \
	| grep -P -v -e "^[0-9]* [\.,\[\]%]*#$" | grep -P -v -e "^[0-9]* [\.,\+\-%]*#$" | wc -l`)"
echo "read and write and 4 pairs/instructions (full BF set):,$(cat ${samples} | grep -P -v -e "^[0-9]* [\.,\+\-<>%]*#$" \
	| grep -P -v -e "^[0-9]* [\.,\+\-<>\[\]]*#$" | grep -P -v -e "^[0-9]* [\.,\[\]<>%]*#$" | grep -P -v -e "^[0-9]* [\.,\[\]\+\-%]*#$" | wc -l)"

# Analyze infinite loops
echo "Infinite loops,"
echo "are present:,$(expr \
	`grep -P -e "^[0-9]* .*\[\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[\[\]\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[\+\-\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[\-\+\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[\<\>\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[\>\<\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[\+\+\+\+\+\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[\-\-\-\-\-\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[<[^\[\]\.<>]+>\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[>[^\[\]\.<>]+<\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[<<[^\[\]\.<>]+>>\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[>>[^\[\]\.<>]+<<\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[<[^\[\]\.<>]*\[[^\[\]\.<>]+\][^\[\]\.<>]*>\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[>[^\[\]\.<>]*\[[^\[\]\.<>]+\][^\[\]\.<>]*<\].*#$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[[^\[\]\.]*\[[\+\-,%<>]+\][\+\-]+\].*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[[^\[\]\.]*\[[^\[\]\.]*\][^\[\]\.]*\[[\+\-,%<>]+\][\+\-]+\].*$" ${samples} | wc -l`)"

# Analyze pointless code
echo "Pointless code,"
echo "never executed loops,$(grep -P -e "^[0-9]* .*\]\[.*$" ${samples} | wc -l)"
echo "incrementation/decrementation of chance,$(expr \
	`grep -P -e "^[0-9]* .*%[\+\-]+.*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [\+\-]+.*%[\+\-]*#$" ${samples} | wc -l`)"
echo "action/chance/incrementation/decrementation overwritten by chance or action,$(expr \
	`grep -P -e "^[0-9]* .*[%\-\+]+[%,].*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* [%\-\+]*[%,].*[%\-\+]+#$" ${samples} | grep -P -v -e "^[0-9]* .*[%\-\+]+[%,].*$" \
	| grep -P -v -e "^[0-9]* .*[%,\-\+]*,[%,\-\+]*%[^,]*$" \
	| grep -P -v -e "^[0-9]* [%,\-\+]*%[^,]*[%,\-\+]*,[%,\-\+]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* .*[%,\-\+]*,[%,\-\+]*%[^,]*$" ${samples} | grep -P -v -e "^[0-9]* .*[%\-\+]+[%,].*$" \
	| grep -P -v -e "^[0-9]* [%\-\+]*[%,].*[%\-\+]+#$" \
	| grep -P -v -e "^[0-9]* [%,\-\+]*%[^,]*[%,\-\+]*,[%,\-\+]*#$" | wc -l` + \
	`grep -P -e "^[0-9]* [%,\-\+]*%[^,]*[%,\-\+]*,[%,\-\+]*#$" ${samples} \
	| grep -P -v -e "^[0-9]* .*[%\-\+]+[%,].*$" | grep -P -v -e "^[0-9]* .*[%,\-\+]*,[%,\-\+]*%[^,]*$" \
	| grep -P -v -e "^[0-9]* [%\-\+]*[%,].*[%\-\+]+#$" | wc -l`)"
echo "zeroing overwritten by chance or action,$(expr \
	`grep -P -e "^[0-9]* .*\[[\+\-%]+\]%.*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*\[[\+\-%]+\],.*$" ${samples} | wc -l`)"
echo "zeroed chance or action,$(expr \
	`grep -P -e "^[0-9]* .*%[\+\-]*\[[\+\-%,]+\].*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*,[\+\-]*\[[\+\-%]+\][^,]*$" ${samples} | wc -l` + \
	`grep -P -e "^[0-9]* .*,[\+\-]*\[[\+\-%,]*,[\+\-%,]*\].*$" ${samples} | wc -l`)"

# Analyze premature termination
echo "Premature termination,"
echo "surely occures,$(count_write_limit_surely_exceeded)"
echo "possibly occures,$(count_write_limit_possibly_exceeded)"
echo "of that based on action:,$(count_write_limit_possibly_exceeded_conditioned_by ',')"
echo "of that based on chance:,$(count_write_limit_possibly_exceeded_conditioned_by '%')"

