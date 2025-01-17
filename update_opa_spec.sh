#!/bin/bash
# BEGIN_ICS_COPYRIGHT8 ****************************************
# 
# Copyright (c) 2015-2017, Intel Corporation
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Intel Corporation nor the names of its contributors
#       may be used to endorse or promote products derived from this software
#       without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# END_ICS_COPYRIGHT8   ****************************************

#[ICS VERSION STRING: unknown]

id=$(./get_id_and_versionid.sh | cut -f1 -d' ')
versionid=$(./get_id_and_versionid.sh | cut -f2 -d' ')

from=$1
to=$2

if [ "$from" = "" -o "$to" = "" ]
then
	echo "Usage: update_opa-ff_spec.sh spec-in-file spec-file"
	exit 1
fi

if [ "$from" != "$to" ]
then
	cp $from $to
fi


source ./OpenIb_Host/ff_filegroups.sh

if [ "$id" = "rhel"  -o "$id" = "centos" ]
then
	GE_7_4=$(echo "$versionid >= 7.4" | bc)
	if [ $GE_7_4 = 1 ]
	then
		sed -i "s/__RPM_BLDREQ/expat-devel, gcc-c++, openssl-devel, ncurses-devel, tcl-devel, rdma-core-devel, ibacm-devel/g" $to
		sed -i "s/__RPM_RQ3/rdma-core-devel, openssl-devel, opa-libopamgt/g" $to
	else
		sed -i "s/__RPM_BLDREQ/expat-devel, gcc-c++, openssl-devel, ncurses-devel, tcl-devel, libibumad-devel, libibverbs-devel, ibacm-devel/g" $to
		sed -i "s/__RPM_RQ3/libibumad-devel, libibverbs-devel, openssl-devel, opa-libopamgt/g" $to
	fi
	sed -i "s/__RPM_REQ/expect%{?_isa}, tcl%{?_isa}, openssl%{?_isa}, expat%{?_isa}, libibumad%{?_isa}, libibverbs%{?_isa}, libibmad%{?_isa}/g" $to
	sed -i "s/__RPM_RQ2/libibumad%{?_isa}, libibverbs%{?_isa}, openssl%{?_isa}/g" $to
	sed -i "/__RPM_DEBUG/,+1d" $to
elif [ "$id" = "sles" ]
then
	GE_11_1=$(echo "$versionid >= 11.1" | bc)
	GE_12_2=$(echo "$versionid >= 12.2" | bc)
	GE_12_3=$(echo "$versionid >= 12.3" | bc)
	if [ $GE_11_1 = 1 ]
	then
		sed -i "s/__RPM_DEBUG/%debug_package/g" $to
	else
		sed -i "/__RPM_DEBUG/,+1d" $to
	fi
	if [ $GE_12_3 = 1 ]
	then
		sed -i "s/__RPM_REQ/libexpat1, libibmad5, libibumad3, libibverbs1, openssl, expect, tcl/g" $to
		sed -i "s/__RPM_BLDREQ/libexpat-devel, gcc-c++, libopenssl-devel, ncurses-devel, tcl-devel, rdma-core-devel, ibacm-devel/g" $to
		sed -i "s/__RPM_RQ3/rdma-core-devel, libopenssl-devel, opa-libopamgt/g" $to
	else
		sed -i "s/__RPM_REQ/libexpat1, libibmad5, libibumad3, libibverbs1, openssl, expect, tcl/g" $to
		sed -i "s/__RPM_BLDREQ/libexpat-devel, gcc-c++, libopenssl-devel, ncurses-devel, tcl-devel, libibumad-devel, libibverbs-devel, ibacm-devel/g" $to
		sed -i "s/__RPM_RQ3/libibumad-devel, libibverbs-devel, libopenssl-devel, opa-libopamgt/g" $to
	fi
	sed -i "s/__RPM_RQ2/libibumad3, libibverbs1, openssl/g" $to
else
	echo ERROR: Unsupported distribution: $id $versionid
	exit 1
fi

> .tmpspec
while read line
do
	if [ "$line" = "__RPM_BASIC_FILES" ]
	then
		for i in $basic_tools_sbin $basic_tools_sbin_sym
		do
			echo "%{_sbindir}/$i" >> .tmpspec
		done
		for i in $basic_tools_opt
		do
			echo "/usr/lib/opa/tools/$i" >> .tmpspec
		done
		for i in $basic_lib_opa_opt
		do
			echo "/usr/lib/opa/$i" >> .tmpspec
		done
		for i in $basic_mans
		do
			echo "%{_mandir}/man1/${i}.gz" >> .tmpspec
		done
		for i in $basic_samples
		do
			echo "/usr/share/opa/samples/$i" >> .tmpspec
		done
	else
		echo "$line" >> .tmpspec
	fi
done < $to
mv .tmpspec $to

> .tmpspec
while read line
do
	if [ "$line" = "__RPM_FF_FILES" ]
	then
		for i in $ff_tools_sbin opafmconfigcheck opafmconfigdiff
		do
			echo "%{_sbindir}/$i" >> .tmpspec
		done
		for i in $ff_tools_opt $ff_tools_misc $ff_tools_exp $ff_libs_misc
		do
			echo "/usr/lib/opa/tools/$i" >> .tmpspec
		done
		for i in $help_doc
		do
			echo "/usr/share/opa/help/$i" >> .tmpspec
		done
		for i in $ff_tools_fm
		do
			echo "/usr/lib/opa/fm_tools/$i" >> .tmpspec
		done
		for i in $ff_iba_samples
		do
			echo "/usr/share/opa/samples/$i" >> .tmpspec
		done
		for i in $ff_mans
		do
			echo "%{_mandir}/man8/${i}.gz" >> .tmpspec
		done
		for i in $mpi_apps_files
		do
			echo "/usr/src/opa/mpi_apps/$i" >> .tmpspec
		done
		for i in $shmem_apps_files
		do
			echo "/usr/src/opa/shmem_apps/$i" >> .tmpspec
		done
	else
		echo "$line" >> .tmpspec
	fi
done < $to
mv .tmpspec $to

exit 0
