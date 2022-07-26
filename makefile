
export FGLLDPATH=../bin_common
export FGLAPPSERVER=9090

all: bin_common/logging.42m bin_cli/main.42m bin_srv/main.42m

cli/ex1.json:
	wget -O tmp.json http://localhost:9090/ex1?openapi.json
	jq . tmp.json > $@
	rm tmp.json

cli/ws_ex1.4gl: cli/ex1.json
	cd cli && fglrestful ex1.json

bin_common/logging.42m: common/logging.4gl
	cd common && fglcomp logging.4gl && mv logging.42m ../bin_common

bin_cli/main.42m: cli/ws_ex1.4gl cli/main.4gl
	cd bin_cli && fglcomp ../cli/main.4gl

bin_srv/main.42m: srv/ws_rest_ex.4gl srv/ws_lib.4gl srv/main.4gl
	cd bin_srv && fglcomp ../srv/main.4gl

runcli: bin_common/logging.42m bin_cli/main.42m
	cd bin_cli && fglrun main.42m

runsrv: bin_common/logging.42m bin_srv/main.42m
	cd bin_srv && fglrun main.42m

clean:
	find . -name \*.42? -delete
