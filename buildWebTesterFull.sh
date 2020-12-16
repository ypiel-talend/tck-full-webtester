#!/bin/bash

function usage(){
	echo "Build full TCK Web tester"
	echo "Usage : $0 <tck_version> <connectors_version> <install_dir> <connectors_list_file> <port>"
	echo
	echo "Parameter '$1' is needed."
	echo
	exit 1
}

[ -z ${1+x} ] && usage "tck_version"
[ -z ${2+x} ] && usage "connectors_version"
[ -z ${3+x} ] && usage "install_dir"
[ -z ${4+x} ] && usage "connectors_list_file"
[ -z ${5+x} ] && usage "port"

export VERS="$1"
export CONN_VERS="$2"
export INSTALL_DIR="$3"
export SETENV=${INSTALL_DIR}/component-server-distribution/bin/setenv.sh
export REGISTY=${INSTALL_DIR}/component-server-distribution/conf/components-registry.properties
export CONNECTORS_LIST="$4"
export PORT="$5"

echo "Build web tester multi connector."
echo "Install dir	: ${INSTALL_DIR}"
echo "Connectors list	: ${CONNECTORS_LIST}"
echo "Server version	: ${VERS}"
echo "Connector version	: ${CONN_VERS}"
echo "(to deactivate download set a value in NO_DWNLD)"

[ -n "${NO_DWNLD}" ] && echo "No download..."

function download_lib {
	wget -O ${INSTALL_DIR}/component-server-distribution/lib/${1}-${VERS}.jar https://repo.maven.apache.org/maven2/org/talend/sdk/component/${1}/${VERS}/${1}-${VERS}.jar
}


function download_all {
	wget https://repo.maven.apache.org/maven2/org/talend/sdk/component/component-server/${VERS}/component-server-${VERS}.zip
	unzip -d ${INSTALL_DIR} component-server-${VERS}.zip 

	download_lib "component-tools"
	download_lib "component-tools-webapp"
	download_lib "component-form-core"
	download_lib "component-form-model"
	download_lib "component-runtime-beam"

	wget -O  ${INSTALL_DIR}/component-server-distribution/lib/avro-1.10.0.jar  https://apache.mediamirrors.org/avro/avro-1.10.0/java/avro-1.10.0.jar
	wget -O ${INSTALL_DIR}/component-server-distribution/lib/beam-sdks-java-core-2.25.0.jar https://repo1.maven.org/maven2/org/apache/beam/beam-sdks-java-core/2.25.0/beam-sdks-java-core-2.25.0.jar
}

function build_setenv {
	echo "" > ${SETENV}
	chmod +x ${SETENV}
	echo "export JAVA_HOME=\"${JAVA_HOME}\"" > ${SETENV}
	echo "export ENDORSED_PROP=\"ignored.endorsed.dir\"" >> ${SETENV}
	echo "export MEECROWAVE_OPTS=\"-Dhttp=${PORT}\"" >> ${SETENV}
	echo "export MEECROWAVE_OPTS=\"-Dtalend.component.server.component.registry=conf/components-registry.properties \${MEECROWAVE_OPTS}\"" >> ${SETENV}
}

function generate_registry {
	echo "" > ${REGISTY}
	n=0
	while read -r conn;
	do
                [[ "${conn}" =~ "#" ]] && echo "Skip ${conn}..." && continue

		n=$((n+1))
		echo "${n} : add ${conn}..."
		echo "conn_${n}=org.talend.components\\:${conn}\\:${CONN_VERS}" >> ${REGISTY}
	done < ${CONNECTORS_LIST}
}

[ -z "${NO_DWNLD}" ] && download_all
echo "Generate setenv.sh" && build_setenv
echo "Add connectors..." && generate_registry

